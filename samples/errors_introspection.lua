-- Theme: error handling and instance introspection.
-- Runnable: needs a configured instance for box.info / box.stat.
--
-- NOTE: this sample uses `pcall`-based error handling rather than the
-- `box.error.*` constructor API, which currently trips the analyzer (see
-- a documented limitation -- `box.error`'s object-class vs module-table dual identity).

box.cfg({})

--------------------------------------------------------------------------------
-- Error handling with pcall / xpcall
--------------------------------------------------------------------------------

-- A plain Lua error (string payload).
local ok1, err1 = pcall(function() error('boom') end)
---@type boolean
local _ok1 = ok1
print(ok1, err1)

-- A Tarantool error raised by a failing database operation (caught as an object).
local ok2, err2 = pcall(function()
    box.schema.space.create('_space') -- already exists -> raises
end)
print(ok2, err2)

-- xpcall with a message handler.
local ok3, handled = xpcall(function()
    error('handled error')
end, function(e) return tostring(e) end)
print(ok3, handled)

-- A pcall that succeeds returns true plus the function's results.
local ok4, value = pcall(function() return 2 + 2 end)
print(_ok1, ok4, value)

--------------------------------------------------------------------------------
-- box.info
--------------------------------------------------------------------------------

local info = box.info

---@type string
local _version = info.version
---@type integer
local _id = info.id
---@type string
local _uuid = info.uuid
---@type integer
local _pid = info.pid
---@type integer
local _uptime = info.uptime
---@type integer
local _lsn = info.lsn
---@type boolean
local _ro = info.ro
local _status = info.status
local _vclock = info.vclock
local _replication = info.replication

-- Leader-election sub-table.
local _election_state = info.election.state

-- Memory and GC are functions returning tables.
local _memory = info.memory()
local _gc = info.gc()
print(_version, _id, _uuid, _pid, _uptime, _lsn, _ro, _status, _vclock, _replication, _election_state, _memory, _gc)

--------------------------------------------------------------------------------
-- box.stat
--------------------------------------------------------------------------------

-- Request statistics, broken down by request type.
local stat = box.stat()
---@type number
local _selects = stat.SELECT.total
---@type number
local _inserts = stat.INSERT.rps

-- Network statistics.
local net = box.stat.net()
---@type number
local _sent = net.SENT.total
---@type number
local _conns = net.CONNECTIONS.current

-- Storage-engine statistics.
local _memtx = box.stat.memtx()
local _memtx_data_total = _memtx.data.total
local _vinyl = box.stat.vinyl()
local _vinyl_commits = _vinyl.tx.commit

-- Reset all of the above.
box.stat.reset()
print(_selects, _inserts, _sent, _conns, _memtx_data_total, _vinyl_commits)

--------------------------------------------------------------------------------
-- box.session
--------------------------------------------------------------------------------

---@type number
local _sid = box.session.id()
---@type string
local _stype = box.session.type()
---@type string
local _suser = box.session.user()
---@type number
local _suid = box.session.uid()
---@type number
local _seuid = box.session.euid()
---@type boolean
local _sexists = box.session.exists(_sid)

-- peer() raises when there is no peer (e.g. the admin console), so guard it.
local _has_peer = pcall(box.session.peer)
print(_sid, _stype, _suser, _suid, _seuid, _sexists, _has_peer)
