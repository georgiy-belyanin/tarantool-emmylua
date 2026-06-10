-- validate: skip -- the `membership` rock is not installed here; type-checked only.
--
-- Theme: the `membership` rock (SWIM-based gossip mesh). The member data
-- structure is a typed record, so every field is captured at its concrete type
-- (uri:string, status:alias, incarnation/timestamp:number, payload:table) and
-- used; the members() map and the subscribe() condition variable are exercised.

local membership = require('membership')
local options = require('membership.options')
local fiber = require('fiber')

-- init() binds the UDP socket and returns true.
---@type boolean
local started = membership.init('localhost', 33001)
print(started)

--------------------------------------------------------------------------------
-- The member data structure: typed fields
--------------------------------------------------------------------------------

local me = membership.myself()
---@type string
local uri = me.uri
---@type membership.status
local status = me.status
---@type number
local incarnation = me.incarnation
---@type table
local payload = me.payload
---@type number
local timestamp = me.timestamp
local alive = status == 'alive'
print(uri, incarnation, timestamp, payload.uuid, alive)

-- get_member() returns the same record type for an arbitrary URI.
local other = membership.get_member('localhost:33002')
---@type membership.status
local other_status = other.status
print(other_status)

--------------------------------------------------------------------------------
-- The full members table, plus the pairs() iterator
--------------------------------------------------------------------------------

---@type table<string, membership.member>
local all = membership.members()
---@type integer
local alive_count = 0
for member_uri, member in pairs(all) do
    if member.status == 'alive' then
        alive_count = alive_count + 1
    end
    print(member_uri, member.incarnation)
end

for member_uri, member in membership.pairs() do
    print(member_uri, member.status)
end
print('alive', alive_count)

--------------------------------------------------------------------------------
-- Group management, broadcast, payload, encryption
--------------------------------------------------------------------------------

---@type boolean?
local added = membership.add_member('localhost:33003')
---@type boolean
local probed = membership.probe_uri('localhost:33003')
---@type boolean
local broadcasted = membership.broadcast()
---@type boolean
local payload_set = membership.set_payload('role', 'router')
print(added, probed, broadcasted, payload_set)

membership.set_encryption_key('a-shared-secret-key')
---@type boolean
local encrypted = membership.is_encrypted()
---@type string?
local key = membership.get_encryption_key()
print(encrypted, key)

--------------------------------------------------------------------------------
-- Subscription: subscribe() yields a fiber.cond broadcast on membership changes
--------------------------------------------------------------------------------

local cond = membership.subscribe()

---@async
local function watch_changes()
    -- wait() yields, so it runs in an async fiber; it returns whether it was signalled.
    ---@type boolean
    local signalled = cond:wait(1)
    print('membership changed', signalled)
end
fiber.create(watch_changes)

membership.unsubscribe(cond)

--------------------------------------------------------------------------------
-- Tunable protocol options (numbers)
--------------------------------------------------------------------------------

options.PROTOCOL_PERIOD_SECONDS = 0.2
options.SUSPECT_TIMEOUT_SECONDS = 3
---@type number
local ack_timeout = options.ACK_TIMEOUT_SECONDS
print(ack_timeout)

---@type boolean
local left = membership.leave()
print(left)
