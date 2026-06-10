---@meta

---# Rock `vshard.storage`
---
---The `vshard.storage` module is the [storage](doc://vshard-architecture-storage) side of the
---sharded cluster. A storage is a node that physically stores a subset of the dataset, split into
---[virtual buckets](doc://vshard-vbuckets). It serves the read/write requests routed to it by a
---[router](lua://vshard.router), participates in rebalancing (sending and receiving buckets), and
---runs the background services (garbage collector, recovery, rebalancer applier).
---
---The module exposes a public API for configuration, introspection, and bucket management, plus an
---internal API used by the rebalancer and recovery subsystems.
---@class vshard.storage
local storage = {}

--------------------------------------------------------------------------------
-- Storage public API
--------------------------------------------------------------------------------

---Configure the database and start sharding for the specified `storage` instance.
---
---@param cfg vshard.cfg a `storage` configuration
---@param instance_uuid vshard.uuid UUID of the instance
function storage.cfg(cfg, instance_uuid) end

---@class vshard.storage.bucket_stat_info
---@field receiving integer the number of buckets that are being received from other replica sets
---@field active integer the number of active buckets that can accept read and write requests
---@field total integer the total number of buckets stored on the instance
---@field garbage integer the number of buckets in the garbage state, awaiting collection
---@field pinned integer the number of pinned buckets that cannot be moved
---@field sending integer the number of buckets that are being sent to other replica sets

---@class vshard.storage.info
---@field replicasets table<vshard.uuid, table> a map of replica set UUIDs to short replica set descriptions
---@field bucket vshard.storage.bucket_stat_info aggregated bucket counts on this instance
---@field status integer the instance status: `0` (healthy) or higher (degraded/dead)
---@field replication { status: string } replication status of the instance, e.g. `{ status = 'master' }`
---@field alerts table[] a list of active alerts

---Return information about the storage instance.
---
---*Since vshard v.0.1.22*, the function also accepts options, which can be used to get additional information.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> vshard.storage.info()
--- ---
--- - replicasets:
---   c862545d-d966-45ff-93ad-763dce4a9723:
---   uuid: c862545d-d966-45ff-93ad-763dce4a9723
---   master:
---   uri: admin@localhost:3302
---   1990be71-f06e-4d9a-bcf9-4514c4e0c889:
---   uuid: 1990be71-f06e-4d9a-bcf9-4514c4e0c889
---   master:
---   uri: admin@localhost:3304
---   bucket:
---   receiving: 0
---   active: 15000
---   total: 15000
---   garbage: 0
---   pinned: 0
---   sending: 0
---   status: 0
---   replication:
---   status: master
---   alerts: []
---   ...
--- ```
---
---@param opts? { with_services: boolean } if `with_services` is `true`, the result also contains information about the background services (garbage collector, rebalancer, recovery, route applier) running on the instance.
---@return vshard.storage.info
function storage.info(opts) end

---Call the specified function on the current `storage` instance.
---
---@param bucket_id integer a bucket identifier
---@param mode vshard.call_mode a type of the function: `'read'` or `'write'`
---@param function_name string function to execute
---@param argument_list? table array of the function's arguments
---@return any # the original return value of the executed function on success, or `nil` otherwise
---@return vshard.error? # error object on failure
function storage.call(bucket_id, mode, function_name, argument_list) end

---Wait until the dataset is synchronized on replicas.
---
---@param timeout? number a timeout, in seconds
---@return boolean? # `true` if the dataset was synchronized successfully
---@return vshard.error? # error explaining why the dataset cannot be synchronized
function storage.sync(timeout) end

---Pin a bucket to a replica set.
---
---A pinned bucket cannot be moved even if it breaks the cluster balance.
---
---@param bucket_id integer a bucket identifier
---@return boolean? # `true` if the bucket is pinned successfully
---@return vshard.error? # error explaining why the bucket cannot be pinned
function storage.bucket_pin(bucket_id) end

---Return a pinned bucket back into the active state.
---
---@param bucket_id integer a bucket identifier
---@return boolean? # `true` if the bucket is unpinned successfully
---@return vshard.error? # error explaining why the bucket cannot be unpinned
function storage.bucket_unpin(bucket_id) end

---Create an RO or RW [ref](doc://vshard-ref).
---
---@param bucket_id integer a bucket identifier
---@param mode vshard.call_mode `'read'` or `'write'`
---@return boolean? # `true` if the bucket ref is created successfully
---@return vshard.error? # error explaining why the ref cannot be created
function storage.bucket_ref(bucket_id, mode) end

---An alias for [`vshard.storage.bucket_ref`](lua://vshard.storage.bucket_ref) in the RO mode.
---
---@param bucket_id integer a bucket identifier
---@return boolean? # `true` if the bucket ref is created successfully
---@return vshard.error? # error explaining why the ref cannot be created
function storage.bucket_refro(bucket_id) end

---An alias for [`vshard.storage.bucket_ref`](lua://vshard.storage.bucket_ref) in the RW mode.
---
---@param bucket_id integer a bucket identifier
---@return boolean? # `true` if the bucket ref is created successfully
---@return vshard.error? # error explaining why the ref cannot be created
function storage.bucket_refrw(bucket_id) end

---Remove a RO/RW [ref](doc://vshard-ref).
---
---@param bucket_id integer a bucket identifier
---@param mode vshard.call_mode `'read'` or `'write'`
---@return boolean? # `true` if the bucket ref is removed successfully
---@return vshard.error? # error explaining why the ref cannot be removed
function storage.bucket_unref(bucket_id, mode) end

---An alias for [`vshard.storage.bucket_unref`](lua://vshard.storage.bucket_unref) in the RO mode.
---
---@param bucket_id integer a bucket identifier
---@return boolean? # `true` if the bucket ref is removed successfully
---@return vshard.error? # error explaining why the ref cannot be removed
function storage.bucket_unrefro(bucket_id) end

---An alias for [`vshard.storage.bucket_unref`](lua://vshard.storage.bucket_unref) in the RW mode.
---
---@param bucket_id integer a bucket identifier
---@return boolean? # `true` if the bucket ref is removed successfully
---@return vshard.error? # error explaining why the ref cannot be removed
function storage.bucket_unrefrw(bucket_id) end

---Find a bucket which has data in a space but is not stored in a `_bucket` space; or is in a GARBAGE state.
---
---@param bucket_index box.index index of a space with the part of a bucket id
---@param control table a garbage collector controller. If there is an increased buckets generation, then the search should be interrupted.
---@return integer? # an identifier of the bucket in the garbage state, if found; otherwise, `nil`
function storage.find_garbage_bucket(bucket_index, control) end

---Disable rebalancing.
---
---A disabled rebalancer sleeps until it is enabled again with [`vshard.storage.rebalancer_enable`](lua://vshard.storage.rebalancer_enable).
function storage.rebalancer_disable() end

---Enable rebalancing.
function storage.rebalancer_enable() end

---Return a flag indicating whether storage is invisible to the rebalancer.
---
---@return boolean
function storage.is_locked() end

---Return a flag indicating whether rebalancing is in progress.
---
---The result is `true` if the node is currently applying routes received from a rebalancer node in the special fiber.
---
---@return boolean
function storage.rebalancing_is_in_progress() end

---@class vshard.storage.bucket_status
---@field id integer a bucket identifier
---@field status string the bucket status, for example `active`, `sent`, `garbage`, `receiving`, or `sending`
---@field ref_rw? integer the number of read-write refs held on the bucket
---@field ref_ro? integer the number of read-only refs held on the bucket
---@field ro_lock? boolean whether the bucket is locked for read-only access
---@field rw_lock? boolean whether the bucket is locked for read-write access

---Return information about each bucket located in storage.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> vshard.storage.buckets_info(1)
--- ---
--- - 1:
---   status: active
---   ref_rw: 1
---   ref_ro: 1
---   ro_lock: true
---   rw_lock: true
---   id: 1
--- ```
---
---@param bucket_id? integer if set, return information about this bucket only; otherwise, about all buckets
---@return table<integer, vshard.storage.bucket_status> # a map of bucket id to its status
function storage.buckets_info(bucket_id) end

---Return the number of buckets located in storage.
---
---@return integer
function storage.buckets_count() end

---Show the spaces that are visible to the rebalancer and garbage collector fibers.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> vshard.storage.sharded_spaces()
--- ---
--- - 513:
---   engine: memtx
---   id: 513
---   name: actors
---   ...
--- ```
---
---@return table<integer, box.space> # a map of space id to the sharded space object
function storage.sharded_spaces() end

---Immediately wake up a recovery fiber, if it exists.
function storage.recovery_wakeup() end

---@alias vshard.storage.bucket_event 'bucket_data_recv_txn' | 'bucket_data_gc_txn'

---*Since vshard v.0.1.22.* Define a trigger for execution when the data from the user spaces is changed
---(deleted or inserted) due to the rebalancing process. The trigger is invoked each time the data batch changes.
---
---The `trigger_function` can have up to three parameters:
---
---* `event_type` (string) -- in order to distinguish event, you can compare this argument with the supported event types, `bucket_data_recv_txn` and `bucket_data_gc_txn`.
---* `bucket_id` (unsigned) -- bucket id.
---* `data` (table) -- additional information about data change transaction. Currently it only includes an array of all spaces (`data.spaces`), affected by a transaction in which trigger-function is executed.
---
---If the parameters are `(nil, old_trigger_function)`, then the old trigger is deleted.
---If both parameters are omitted, then the response is a list of existing trigger functions.
---
---**Note:** as everything executed inside triggers is already in a transaction, you shouldn't use transactions,
---yield-operations ([explicit](doc://app-yields) or not), or changes to different space engines.
---
---**Example:**
---
--- ```lua
--- vshard.storage.on_bucket_event(function(event, bucket_id, data)
---     if event == 'bucket_data_recv_txn' then
---         -- Handle it.
---         for idx, space in ipairs(data.spaces) do
---             ...
---         end
---     elseif event == 'bucket_data_gc_txn' then
---         -- Handle it.
---         ...
---     end
--- end)
--- ```
---
---@param trigger_function? fun(event_type: vshard.storage.bucket_event, bucket_id: integer, data: { spaces: any[] }) function which will become the trigger function
---@param old_trigger_function? function existing trigger function which will be replaced by `trigger_function`
---@return function? # nil or function pointer
function storage.on_bucket_event(trigger_function, old_trigger_function) end

--------------------------------------------------------------------------------
-- Storage internal API
--------------------------------------------------------------------------------

---Return information about the bucket id.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> vshard.storage.bucket_stat(1)
--- ---
--- - 0
--- - status: active
---   id: 1
--- ...
--- ```
---
---@param bucket_id integer a bucket identifier
---@return vshard.storage.bucket_status? # the bucket status, or `nil` on error
---@return vshard.error? # error object on failure
function storage.bucket_stat(bucket_id) end

---Receive a bucket identified by bucket id from a remote replica set.
---
---@param bucket_id integer a bucket identifier
---@param from vshard.uuid UUID of the source replica set
---@param data any data logically stored in the bucket, in the same format as the return value of [`bucket_collect`](lua://vshard.storage.bucket_collect)
---@return boolean? # `true` on success
---@return vshard.error? # error object on failure
function storage.bucket_recv(bucket_id, from, data) end

---Force garbage collection for the bucket identified by bucket id in case the bucket was transferred to a different replica set.
---
---@param bucket_id integer a bucket identifier
function storage.bucket_delete_garbage(bucket_id) end

---Collect all the data that is logically stored in the bucket identified by bucket id.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> vshard.storage.bucket_collect(1)
--- ---
--- - 0
--- - - - 514
---     - - [10, 1, 1, 100, 'Account 10']
---   - - 513
---     - - [1, 1, 'Customer 1']
--- ...
--- ```
---
---@param bucket_id integer a bucket identifier
---@return any # an array of `{space_id, tuples}` pairs collected for the bucket, or `nil` on error
---@return vshard.error? # error object on failure
function storage.bucket_collect(bucket_id) end

---Force creation of the buckets (single or multiple) on the current replica set.
---
---Use only for manual emergency recovery or for initial bootstrap.
---
---@param first_bucket_id integer an identifier of the first bucket in a range
---@param count? integer the number of buckets to insert (default = 1)
---@return boolean? # `true` on success
---@return vshard.error? # error object on failure
function storage.bucket_force_create(first_bucket_id, count) end

---Drop a bucket manually for tests or emergency cases.
---
---@param bucket_id integer a bucket identifier (the first bucket in a range)
---@param count? integer the number of buckets to drop (default = 1)
---@return boolean? # `true` on success
---@return vshard.error? # error object on failure
function storage.bucket_force_drop(bucket_id, count) end

---Send a specified bucket from the current replica set to a remote replica set.
---
---@param bucket_id integer a bucket identifier
---@param to vshard.uuid UUID of a remote replica set
---@return boolean? # `true` on success
---@return vshard.error? # error object on failure
function storage.bucket_send(bucket_id, to) end

---Check all buckets of the host storage that have the SENT or ACTIVE state, return the number of active buckets.
---
---@return integer? # the number of buckets in the active state, if found; otherwise, `nil`
function storage.rebalancer_request_state() end

---Collect an array of active bucket identifiers for discovery.
---
---@return integer[] # an array of active bucket identifiers
function storage.buckets_discovery() end

return storage
