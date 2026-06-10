-- validate: skip -- vshard is not installed in this environment and needs a
-- sharded cluster; type-checked only (resolved via Rocks/).
--
-- Theme: the `vshard` rock -- router bucket math, sharded calls, route objects,
-- and cluster introspection, plus the storage-side API. Bucket ids and counts
-- are integers, route() yields a typed replicaset whose master/replicas are
-- typed replica records, and info()/buckets_info()/bucket_stat() return
-- composite records -- all captured and used.

local vshard = require('vshard')
local router = vshard.router
local storage = vshard.storage

--------------------------------------------------------------------------------
-- Configure the router (sharding + bucket_count are the required cfg fields)
--------------------------------------------------------------------------------

---@type vshard.cfg
local cfg = {
    bucket_count = 3000,
    sharding = {},
    discovery_mode = 'on',
}
router.cfg(cfg)
router.bootstrap({ if_not_bootstrapped = true })

--------------------------------------------------------------------------------
-- Bucket math: every bucket id / count is an integer
--------------------------------------------------------------------------------

---@type integer
local total_buckets = router.bucket_count()
---@type integer
local bucket_id = router.bucket_id_mpcrc32('user:42')
---@type integer
local bucket_id2 = router.bucket_id_strcrc32('user:42')
print(total_buckets, bucket_id, bucket_id2)

--------------------------------------------------------------------------------
-- Sharded calls: the first return is the function result, the second an error
--------------------------------------------------------------------------------

local rw_result, rw_err = router.callrw(bucket_id, 'box.space.users:insert', { { 42, 'Ann' } }, { timeout = 1 })
-- The result is opaque (any); treat it as a tuple array via a cast and use it.
local rw_tuple = rw_result --[[@as table]]
print(rw_tuple[1], rw_err)

local ro_result = router.callro(bucket_id, 'box.space.users:get', { 42 }, { timeout = 1 })
print(ro_result)

-- Consistent map-reduce across masters -> a uuid-keyed map (or nil) + error.
local map_result, map_err = router.map_callrw('box.space.users:count', {}, { timeout = 5 })
if map_result ~= nil then
    ---@type integer
    local replicaset_responses = 0
    for _ in pairs(map_result) do replicaset_responses = replicaset_responses + 1 end
    print('responded', replicaset_responses)
end
print(map_err)

--------------------------------------------------------------------------------
-- route() -> a typed replicaset; its master/replicas are typed replica records
--------------------------------------------------------------------------------

local rs = router.route(bucket_id)
---@type vshard.uuid
local rs_uuid = rs.uuid
---@type integer
local rs_weight = rs.weight
---@type vshard.replica
local master = rs.master
---@type string
local master_uri = master.uri
---@type integer
local master_zone = master.zone
-- The replica carries a live net.box connection.
---@type net.box.conn
local master_conn = master.conn
print(rs_uuid, rs_weight, master_uri, master_zone, master_conn)

-- A replicaset can run a function on its own master directly.
local direct = rs:callrw('box.info', {}, { timeout = 1 })
print(direct)

-- routeall() -> a uuid-keyed map of replicasets; count the configured replicas.
local all = router.routeall()
---@type integer
local replica_total = 0
for _, replicaset in pairs(all) do
    ---@type vshard.replica[]
    local replicas = replicaset.replicas
    replica_total = replica_total + #replicas
end
print('configured replicas', replica_total)

--------------------------------------------------------------------------------
-- Cluster introspection: info() and buckets_info() return composite records
--------------------------------------------------------------------------------

local info = router.info()
---@type vshard.router.bucket_info
local bucket_info = info.bucket
---@type integer
local available_rw = bucket_info.available_rw
---@type integer
local available_ro = bucket_info.available_ro
---@type string[]
local alerts = info.alerts
print(available_rw, available_ro, #alerts)

local page = router.buckets_info(0, 10)
for _, b in ipairs(page) do
    ---@type 'available_ro' | 'available_rw' | 'unavailable' | 'unreachable'
    local bucket_status = b.status
    print(b.uuid, bucket_status)
end

-- sync() reports success as an optional boolean.
---@type boolean?
local synced = router.sync(1)
router.discovery_set('once')
print(synced)

--------------------------------------------------------------------------------
-- Storage side: bucket accounting, introspection, and management
--------------------------------------------------------------------------------

storage.cfg(cfg, '00000000-0000-0000-0000-000000000001')

-- Counts and flags are integers / booleans.
---@type integer
local stored_buckets = storage.buckets_count()
---@type boolean
local locked = storage.is_locked()
---@type boolean
local rebalancing = storage.rebalancing_is_in_progress()
print(stored_buckets, locked, rebalancing)

-- info() -> a typed record; the bucket sub-record holds integer counts.
local sinfo = storage.info()
---@type vshard.storage.bucket_stat_info
local bucket_counts = sinfo.bucket
---@type integer
local active_buckets = bucket_counts.active
---@type integer
local sending_buckets = bucket_counts.sending
---@type integer
local sstatus = sinfo.status
---@type string
local repl_status = sinfo.replication.status
print(active_buckets, sending_buckets, sstatus, repl_status)

-- bucket_stat() -> a typed status record (or nil + error); guard, then read it.
local bstat, bstat_err = storage.bucket_stat(bucket_id)
if bstat ~= nil then
    ---@type integer
    local bid = bstat.id
    ---@type string
    local bstatus = bstat.status
    print(bid, bstatus)
end
print(bstat_err)

-- buckets_info() -> a bucket-id-keyed map of status records.
local all_buckets = storage.buckets_info()
---@type integer
local described = 0
---@type integer
local total_rw_refs = 0
for _, b_info in pairs(all_buckets) do
    described = described + 1
    -- ref_rw is an optional integer on each entry.
    total_rw_refs = total_rw_refs + (b_info.ref_rw or 0)
end
print('described buckets', described, total_rw_refs)

-- Pin / ref / management calls return (true | nil, error).
local pinned, pin_err = storage.bucket_pin(bucket_id)
---@type boolean?
local pin_ok = pinned
storage.bucket_unpin(bucket_id)
storage.bucket_refro(bucket_id)
storage.bucket_unrefro(bucket_id)
print(pin_ok, pin_err)

-- A storage-local call mirrors the router call signature.
local call_result, call_err = storage.call(bucket_id, 'write', 'box.space.users:insert', { { 1, 'Ann' } })
print(call_result, call_err)

-- Sharded spaces visible to the rebalancer, keyed by space id.
local spaces = storage.sharded_spaces()
---@type integer
local space_count = 0
for _ in pairs(spaces) do space_count = space_count + 1 end
print('sharded spaces', space_count)

-- A rebalancing trigger; on_bucket_event returns the (removable) trigger.
local bucket_trigger = storage.on_bucket_event(function(event_type, evt_bucket_id, data)
    ---@type vshard.storage.bucket_event
    local et = event_type
    if et == 'bucket_data_recv_txn' then
        for _, space in ipairs(data.spaces) do print(evt_bucket_id, space) end
    end
end)
---@type function?
local removable_trigger = bucket_trigger

storage.rebalancer_disable()
storage.rebalancer_enable()
storage.recovery_wakeup()
print(removable_trigger ~= nil)
