-- Theme: space replace triggers with typed (old, new) tuple callbacks --
-- exercising the generic `box.space.replace_trigger<T, U>` type.
-- Runnable end-to-end.
--
-- NOTE: raw-table tuple arguments carry the documented generic warning
-- (a documented generic limitation); ignored. The point here is the trigger callbacks.

box.cfg({})

---@alias account_tuple [integer, string, number]
---@class account: table
---@field id integer
---@field owner string
---@field balance number

box.schema.space.create('accounts', {
    if_not_exists = true,
    format = {
        { name = 'id',      type = 'unsigned' },
        { name = 'owner',   type = 'string' },
        { name = 'balance', type = 'number' },
    },
})
---@type box.space<account_tuple, account>
local accounts = box.space.accounts
accounts:create_index('primary', { parts = { 'id' }, if_not_exists = true })
accounts:truncate()

--------------------------------------------------------------------------------
-- before_replace: validate / normalize, and optionally rewrite the new tuple.
--------------------------------------------------------------------------------

-- The callback receives the old and new tuples (either may be nil) and may
-- return a (possibly modified) tuple to be written, or nil to skip.
accounts:before_replace(function(old, new)
    if new == nil then
        return old -- a delete: pass through unchanged
    end
    -- `new` is a box.tuple<account_tuple, account>; round its balance field.
    local balance = new[3]
    if type(balance) == 'number' then
        return new:update({ { '=', 3, math.floor(balance * 100) / 100 } })
    end
    return new
end)

--------------------------------------------------------------------------------
-- on_replace: audit every change after it happens.
--------------------------------------------------------------------------------

---@type { op: string, id: integer, balance: number? }[]
local audit = {}

accounts:on_replace(function(old, new, _space_name, request_type)
    -- old / new are box.tuple<account_tuple, account> | nil.
    if new ~= nil then
        ---@type integer
        local id = new[1]
        ---@type number
        local balance = new[3]
        table.insert(audit, { op = request_type or '?', id = id, balance = balance })
    elseif old ~= nil then
        table.insert(audit, { op = request_type or '?', id = old[1] })
    end
    -- on_replace triggers ignore the return value.
end)

--------------------------------------------------------------------------------
-- Drive the triggers with the full set of data-change operations.
--------------------------------------------------------------------------------

accounts:insert({ 1, 'Alice', 100.456 })   -- before_replace rounds to 100.45/100.46
accounts:replace({ 1, 'Alice', 200.999 })
accounts:update({ 1 }, { { '+', 3, 50 } })
accounts:upsert({ 2, 'Bob', 10.0 }, { { '+', 3, 1 } })
accounts:delete({ 2 })

print('audit entries:', #audit)
for _, entry in ipairs(audit) do
    print(entry.op, entry.id, entry.balance)
end

-- Verify the rounding done by before_replace.
local alice = accounts:get({ 1 })
if alice ~= nil then
    print('rounded balance:', alice[3])
end
