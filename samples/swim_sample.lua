-- validate: skip -- SWIM binds UDP and wants peers; type-checked only.
--
-- Theme: the `swim` module (membership protocol). Member objects expose their
-- attributes as method-fields (status()/uri()/incarnation()/...), so every
-- accessor is captured at its concrete type and used; the member-event trigger
-- and the pairs() iterator are exercised too.

local swim = require('swim')

-- new() with composite config -> a swim.object.
local s = swim.new({
    uri = 3333,
    uuid = '00000000-0000-1000-8000-000000000001',
    heartbeat_rate = 0.1,
})

-- Reconfigure: cfg() returns (true | nil, error_message).
local ok, cfg_err = s:cfg({ heartbeat_rate = 0.5, gc_mode = 'on' })
---@type boolean | nil
local cfg_ok = ok
print(cfg_ok, cfg_err)

-- is_configured -> boolean, size -> integer.
---@type boolean
local configured = s:is_configured()
---@type integer
local member_count = s:size()
print(configured, member_count)

--------------------------------------------------------------------------------
-- self() -> a member object whose attributes are method-fields
--------------------------------------------------------------------------------

local me = s:self()
---@type string
local my_status = me:status()
---@type string
local my_uri = me:uri()
---@type boolean
local dropped = me:is_dropped()

-- incarnation() -> a typed record with two integer parts.
local inc = me:incarnation()
---@type integer
local generation = inc.generation
---@type integer
local version = inc.version
print(my_status, my_uri, dropped, generation, version)

--------------------------------------------------------------------------------
-- Encryption, payload, and explicit membership management
--------------------------------------------------------------------------------

s:set_codec({ algo = 'aes128', mode = 'cbc', key = 'secretkey12345678' })
s:set_payload({ role = 'storage', weight = 10 })

s:add_member({ uuid = '00000000-0000-1000-8000-000000000002', uri = 3334 })
s:probe_member(3335)
s:broadcast(3336)

-- member_by_uuid -> swim.member_object | nil; guard, then read its uri.
local other = s:member_by_uuid('00000000-0000-1000-8000-000000000002')
if other ~= nil then
    ---@type string
    local other_uri = other:uri()
    print(other_uri)
end

--------------------------------------------------------------------------------
-- on_member_event trigger: typed member + event arguments
--------------------------------------------------------------------------------

s:on_member_event(function(member, event)
    ---@type boolean
    local is_new = event:is_new()
    ---@type boolean
    local is_drop = event:is_drop()
    if is_new or is_drop then
        ---@type string
        local who = member:uri()
        print('event', who, is_new, is_drop)
    end
end)

--------------------------------------------------------------------------------
-- pairs(): iterate the member table; the iterator yields (uuid, member)
--------------------------------------------------------------------------------

---@type integer
local alive = 0
for _, member in s:pairs() do
    if member:status() == 'alive' then
        alive = alive + 1
    end
end
print('alive members', alive)

s:quit()
