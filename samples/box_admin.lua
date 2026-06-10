-- Theme: box administration & introspection subsystems not covered by the
-- other samples -- slab memory accounting (box.slab), instance lifecycle and
-- recovery (box.ctl), and the binary-protocol surface (box.iproto). Every
-- result is captured at its concrete type and used. Standalone-runnable.

local fiber = require('fiber')

box.cfg({ memtx_memory = 64 * 1024 * 1024 })

--------------------------------------------------------------------------------
-- box.slab: info() returns a typed record -- byte counts are numbers, but the
-- *_ratio fields are percentage STRINGS (e.g. "43.2%")
--------------------------------------------------------------------------------

local slab = box.slab.info()
---@type number
local quota_size = slab.quota_size
---@type number
local quota_used = slab.quota_used
---@type number
local arena_used = slab.arena_used
---@type number
local items_used = slab.items_used
---@type string
local quota_ratio = slab.quota_used_ratio
---@type string
local arena_ratio = slab.arena_used_ratio

-- Use the numbers arithmetically, the ratios as strings.
local free_quota = quota_size - quota_used
print(quota_ratio, arena_ratio, arena_used, items_used, free_quota)

--------------------------------------------------------------------------------
-- box.ctl: instance lifecycle / recovery state
--------------------------------------------------------------------------------

---@type boolean
local recovered = box.ctl.is_recovery_finished()

-- Waiting until the instance is writable yields, so it runs in an async fiber.
---@async
local function ensure_writable()
    box.ctl.wait_rw(0.5)
end
fiber.create(ensure_writable)

-- on_shutdown installs a trigger and returns the (removable) trigger function.
local function on_stop() end
local shutdown_trigger = box.ctl.on_shutdown(on_stop)
---@type fun()?
local removable = shutdown_trigger
-- Remove it again by passing (nil, old_trigger).
box.ctl.on_shutdown(nil, on_stop)
print(recovered, removable ~= nil)

--------------------------------------------------------------------------------
-- box.iproto: binary-protocol constants and request-handler overrides
--------------------------------------------------------------------------------

-- The key/type maps expose numeric protocol constants.
---@type integer
local sync_key = box.iproto.key.SYNC
---@type integer
local space_id_key = box.iproto.key.SPACE_ID
---@type integer
local select_type = box.iproto.type.SELECT
print(sync_key, space_id_key, select_type)

-- override() installs a custom handler; its (sid, header, body) args are typed
-- and it returns a boolean (false -> fall back to the built-in handler).
box.iproto.override(select_type, function(sid, header, body)
    ---@type number
    local session_id = sid
    print('intercepted SELECT on session', session_id, header, body)
    return false
end)
-- Reset the override by passing nil.
box.iproto.override(select_type, nil)
