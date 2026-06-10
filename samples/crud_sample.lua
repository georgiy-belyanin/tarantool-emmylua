-- validate: skip -- the `crud` rock is not installed here; type-checked only.
--
-- Theme: the `crud` rock (CRUD over a vshard cluster). Every operation returns
-- (result?, error?) where result is {metadata: crud.metadata[], rows: any[][]}.
-- The result is guarded, its typed fields are used, conditions are typed tuples,
-- batch errors are arrays, and crud.cfg is a callable config table.

local crud = require('crud')

--------------------------------------------------------------------------------
-- insert / get: a guarded result with typed metadata and rows
--------------------------------------------------------------------------------

local inserted, insert_err = crud.insert('customers', { 1, box.NULL, 'Elizabeth', 23 }, { timeout = 2 })
if inserted ~= nil then
    ---@type crud.metadata[]
    local metadata = inserted.metadata
    ---@type any[][]
    local rows = inserted.rows
    -- metadata entries are typed field descriptors.
    local first_field = assert(metadata[1])
    ---@type string
    local field_name = first_field.name
    ---@type string
    local field_type = first_field.type
    print(field_name, field_type, #rows)
end
print(insert_err)

-- insert_object flattens a {field = value} table.
local created = crud.insert_object('customers', { id = 2, bucket_id = box.NULL, name = 'Anna', age = 30 })
print(created)

local got, get_err = crud.get('customers', 1, { mode = 'read', prefer_replica = true })
if got ~= nil and got.rows[1] ~= nil then
    print(got.rows[1])
end
print(get_err)

--------------------------------------------------------------------------------
-- update / delete / upsert
--------------------------------------------------------------------------------

crud.update('customers', 1, { { '+', 'age', 1 } }, { noreturn = true })
crud.delete('customers', 2)
crud.upsert('customers', { 3, box.NULL, 'Tom', 50 }, { { '=', 'age', 51 } })

--------------------------------------------------------------------------------
-- select / pairs / count with typed conditions
--------------------------------------------------------------------------------

---@type crud.condition[]
local conditions = { { '>=', 'age', 18 }, { '<', 'age', 65 } }

local selected = crud.select('customers', conditions, { first = 10, fullscan = true })
---@type integer
local seen = 0
if selected ~= nil then
    for _, row in ipairs(selected.rows) do
        seen = seen + 1
        print(row[1])
    end
end

for _, obj in crud.pairs('customers', conditions, { use_tomap = true, first = 5 }) do
    print(obj)
end

local total, count_err = crud.count('customers', conditions, { yield_every = 500 })
---@type number?
local matched = total
print(seen, matched, count_err)

--------------------------------------------------------------------------------
-- min / max / len / truncate
--------------------------------------------------------------------------------

local youngest = crud.min('customers', 'age')
local oldest = crud.max('customers', 'age', { fields = { 'id', 'age' } })
print(youngest, oldest)

local length, len_err = crud.len('customers')
---@type number?
local space_len = length
local truncated = crud.truncate('customers')
---@type boolean?
local was_truncated = truncated
print(space_len, was_truncated, len_err)

--------------------------------------------------------------------------------
-- Batch insert: result + an ARRAY of errors
--------------------------------------------------------------------------------

local batch, batch_errs = crud.insert_many('customers', {
    { 4, box.NULL, 'Ivan', 28 },
    { 5, box.NULL, 'Maria', 35 },
}, { stop_on_error = true, rollback_on_error = true })
if batch_errs ~= nil then
    local first_err = batch_errs[1]
    if first_err ~= nil then
        ---@type string
        local emsg = first_err.err
        print('batch error:', emsg, first_err.operation_data)
    end
end
print(batch)

--------------------------------------------------------------------------------
-- Introspection: storage_info / schema / stats
--------------------------------------------------------------------------------

local storages = crud.storage_info()
if storages ~= nil then
    for uuid, entry in pairs(storages) do
        ---@type 'running' | 'uninitialized' | 'error'
        local status = entry.status
        ---@type boolean
        local is_master = entry.is_master
        print(uuid, status, is_master)
    end
end

local schema = crud.schema('customers')
print(schema)

local stats = crud.stats('customers')
print(stats)

--------------------------------------------------------------------------------
-- Configuration: crud.cfg is callable AND readable (the box.cfg idiom)
--------------------------------------------------------------------------------

crud.cfg({ stats = true, stats_driver = 'metrics', stats_quantiles = true })
---@type boolean?
local stats_enabled = crud.cfg.stats
print(stats_enabled)

--------------------------------------------------------------------------------
-- Read view: a consistent snapshot with its own select/pairs/close
--------------------------------------------------------------------------------

local rv = crud.readview({ name = 'reporting' })
local rv_result = rv:select('customers', conditions, { first = 100 })
if rv_result ~= nil then
    print(#rv_result.rows)
end
rv:close()
