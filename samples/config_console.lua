-- validate: skip -- config needs a declarative-config instance; console needs a peer.
--
-- Theme: the `config` module (cluster-configuration introspection) and the
-- `console` module. config:info('v2') returns a typed record whose nested
-- fields are captured at concrete types and used; the 'v2' overload widens
-- `meta` into last/active snapshots.

local config = require('config')
local console = require('console')

--------------------------------------------------------------------------------
-- config:info('v2') -> config.info.v2 (status alias, alert array, meta.v2)
--------------------------------------------------------------------------------

local info = config:info('v2')
---@type config.info.status
local status = info.status
---@type config.alert[]
local alerts = info.alerts
print(status, #alerts)

for _, alert in ipairs(alerts) do
    ---@type 'warn' | 'error'
    local atype = alert.type
    ---@type string
    local message = alert.message
    print(atype, message)
end

-- The 'v2' overload exposes last/active configuration snapshots in `meta`.
local last_meta = info.meta.last
local active_meta = info.meta.active
-- Each snapshot may carry an etcd revision (a typed nested record).
local last_etcd = last_meta.etcd
---@type integer?
local last_revision = last_etcd ~= nil and last_etcd.revision or nil
print(active_meta, last_revision)

--------------------------------------------------------------------------------
-- config:get -> any (the untyped config tree); config:instance_uri -> uri
--------------------------------------------------------------------------------

local full = config:get()
local listen = config:get('iproto.listen', { instance = 'instance001' })
print(full, listen)

-- instance_uri returns a uri object; read a couple of its optional string parts.
local peer_uri = config:instance_uri('peer', { instance = 'storage-b-003' })
---@type string?
local host = peer_uri.host
---@type string?
local login = peer_uri.login
print(host, login)

config:reload()

--------------------------------------------------------------------------------
-- console: default output format is a typed { fmt: 'yaml' | 'lua' } record
--------------------------------------------------------------------------------

local out = console.get_default_output()
---@type 'yaml' | 'lua'
local fmt = out.fmt
print(fmt)

console.set_default_output({ fmt = 'lua' })
console.eos(';')
console.delimiter('')
console.ac(true)
console.connect('admin:secret@127.0.0.1:3301')
