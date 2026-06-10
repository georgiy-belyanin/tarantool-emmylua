---@meta

---# Rock `crud`
---
---The `crud` rock implements CRUD operations (insert/get/update/delete/replace/upsert, plus select,
---count, min/max, etc.) over a [`vshard`](lua://vshard)-sharded cluster. It hides the sharding details:
---you call `crud.<op>(space_name, ...)` on a router and `crud` routes the request to the right storage
---(or maps over all of them), returning a uniform `{metadata = ..., rows = ...}` result.
---
---**Example:**
---
--- ```lua
--- local crud = require('crud')
--- local result, err = crud.insert('customers', { 1, box.NULL, 'Elizabeth', 23 })
--- local selected = crud.select('customers', {{ '>=', 'age', 18 }}, { first = 10 })
--- ```
local crud = {}

--------------------------------------------------------------------------------
-- Shared types
--------------------------------------------------------------------------------

---A single field descriptor in a result's `metadata`.
---@class crud.metadata
---@field name string the field name.
---@field type string the field type.
---@field is_nullable? boolean whether the field is nullable.

---The uniform result of most `crud` operations.
---@class crud.result
---@field metadata crud.metadata[] the format of the returned rows.
---@field rows any[][] the returned tuples, as arrays of field values.

---An error object returned as the second value of a `crud` operation.
---@class crud.error
---@field err string the error message.
---@field str? string the stringified error.
---@field class_name? string the error class name.
---@field operation_data? any (batch operations) the tuple/object that caused the error.

---A comparison operator used in `select`/`pairs`/`count` conditions.
---@alias crud.operator '=' | '==' | '>' | '>=' | '<' | '<='

---A single condition: `{operator, field_or_index_name, value}`, e.g. `{'>=', 'age', 18}`.
---@alias crud.condition [crud.operator, string, any]

---The read/write preference for a request.
---@alias crud.mode 'read' | 'write'

--------------------------------------------------------------------------------
-- Option types
--------------------------------------------------------------------------------

---@class crud.insert_opts
---@field timeout? number (Default: 2) a vshard timeout, in seconds.
---@field bucket_id? number | ffi.cdata* a bucket id to use instead of the computed one.
---@field fields? string[] a subset of field names to return.
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.
---@field skip_nullability_check_on_flatten? boolean (`*_object` only) skip the nullability check when flattening the object.
---@field noreturn? boolean if `true`, do not return the resulting tuple.
---@field fetch_latest_metadata? boolean if `true`, guarantee the current space format in the metadata.

---@class crud.many_opts
---@field timeout? number (Default: 2) a vshard timeout, in seconds.
---@field fields? string[] a subset of field names to return.
---@field stop_on_error? boolean stop processing on the first error.
---@field rollback_on_error? boolean roll back a storage's batch if any tuple in it fails.
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.
---@field skip_nullability_check_on_flatten? boolean (`*_object_many` only) skip the nullability check when flattening.
---@field noreturn? boolean if `true`, do not return the resulting tuples.
---@field fetch_latest_metadata? boolean if `true`, guarantee the current space format in the metadata.

---@class crud.get_opts
---@field fields? string[] a subset of field names to return.
---@field bucket_id? number | ffi.cdata* a bucket id to use instead of the computed one.
---@field timeout? number (Default: 2) a vshard timeout, in seconds.
---@field request_timeout? number a single-request timeout, in seconds.
---@field mode? crud.mode read from a replica (`'read'`) or the master (`'write'`).
---@field prefer_replica? boolean prefer a replica over the master.
---@field balance? boolean balance reads over the replica set.
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.
---@field fetch_latest_metadata? boolean if `true`, guarantee the current space format in the metadata.

---@class crud.update_opts
---@field timeout? number (Default: 2) a vshard timeout, in seconds.
---@field bucket_id? number | ffi.cdata* a bucket id to use instead of the computed one.
---@field fields? string[] a subset of field names to return.
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.
---@field noreturn? boolean if `true`, do not return the resulting tuple.
---@field fetch_latest_metadata? boolean if `true`, guarantee the current space format in the metadata.

---@class crud.select_opts
---@field first? number the maximum number of rows to return (negative for reverse pagination).
---@field after? table a tuple after which to start (pagination cursor).
---@field batch_size? number the number of tuples to fetch from storages per network request.
---@field bucket_id? number | ffi.cdata* a bucket id to restrict the request to one storage.
---@field force_map_call? boolean force a map-reduce call over all storages.
---@field timeout? number a vshard timeout, in seconds.
---@field request_timeout? number a single-request timeout, in seconds.
---@field fields? string[] a subset of field names to return.
---@field fullscan? boolean acknowledge that the request performs a full scan.
---@field mode? crud.mode read from a replica (`'read'`) or the master (`'write'`).
---@field prefer_replica? boolean prefer a replica over the master.
---@field balance? boolean balance reads over the replica set.
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.
---@field yield_every? number (Default: 1000) the number of processed tuples after which to yield.
---@field fetch_latest_metadata? boolean if `true`, guarantee the current space format in the metadata.

---@class crud.pairs_opts: crud.select_opts
---@field use_tomap? boolean iterate over objects (`{field = value}` tables) instead of tuples.

---@class crud.count_opts
---@field timeout? number (Default: 2) a vshard timeout, in seconds.
---@field request_timeout? number a single-request timeout, in seconds.
---@field yield_every? number (Default: 1000) the number of processed tuples after which to yield.
---@field bucket_id? number | ffi.cdata* a bucket id to restrict the request to one storage.
---@field force_map_call? boolean force a map-reduce call over all storages.
---@field fullscan? boolean acknowledge that the request performs a full scan.
---@field mode? crud.mode read from a replica (`'read'`) or the master (`'write'`).
---@field prefer_replica? boolean prefer a replica over the master.
---@field balance? boolean balance reads over the replica set.
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.

---@class crud.minmax_opts
---@field timeout? number a vshard timeout, in seconds.
---@field request_timeout? number a single-request timeout, in seconds.
---@field fields? string[] a subset of field names to return.
---@field mode? crud.mode read from a replica (`'read'`) or the master (`'write'`).
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.
---@field fetch_latest_metadata? boolean if `true`, guarantee the current space format in the metadata.

---@class crud.simple_opts
---@field timeout? number (Default: 2) a vshard timeout, in seconds.
---@field vshard_router? string | table the name of a vshard router instance, or the router itself.

--------------------------------------------------------------------------------
-- Insert
--------------------------------------------------------------------------------

---Insert a tuple.
---@param space_name string the space name.
---@param tuple table the tuple (an array of field values).
---@param opts? crud.insert_opts
---@return crud.result?
---@return crud.error?
function crud.insert(space_name, tuple, opts) end

---Insert an object (a `{field = value}` table that is flattened to a tuple).
---@param space_name string the space name.
---@param object table the object.
---@param opts? crud.insert_opts
---@return crud.result?
---@return crud.error?
function crud.insert_object(space_name, object, opts) end

---Insert a batch of tuples.
---@param space_name string the space name.
---@param tuples table[] an array of tuples.
---@param opts? crud.many_opts
---@return crud.result?
---@return crud.error[]? # an array of errors, each with an `operation_data` field
function crud.insert_many(space_name, tuples, opts) end

---Insert a batch of objects.
---@param space_name string the space name.
---@param objects table[] an array of objects.
---@param opts? crud.many_opts
---@return crud.result?
---@return crud.error[]?
function crud.insert_object_many(space_name, objects, opts) end

--------------------------------------------------------------------------------
-- Get / update / delete
--------------------------------------------------------------------------------

---Get a tuple by its primary key.
---@param space_name string the space name.
---@param key any the primary key.
---@param opts? crud.get_opts
---@return crud.result?
---@return crud.error?
function crud.get(space_name, key, opts) end

---Update a tuple by its primary key.
---@param space_name string the space name.
---@param key any the primary key.
---@param operations table the update operations (as in `box.space:update`).
---@param opts? crud.update_opts
---@return crud.result?
---@return crud.error?
function crud.update(space_name, key, operations, opts) end

---Delete a tuple by its primary key.
---@param space_name string the space name.
---@param key any the primary key.
---@param opts? crud.update_opts
---@return crud.result?
---@return crud.error?
function crud.delete(space_name, key, opts) end

--------------------------------------------------------------------------------
-- Replace
--------------------------------------------------------------------------------

---Insert or replace a tuple.
---@param space_name string the space name.
---@param tuple table the tuple.
---@param opts? crud.insert_opts
---@return crud.result?
---@return crud.error?
function crud.replace(space_name, tuple, opts) end

---Insert or replace an object.
---@param space_name string the space name.
---@param object table the object.
---@param opts? crud.insert_opts
---@return crud.result?
---@return crud.error?
function crud.replace_object(space_name, object, opts) end

---Insert or replace a batch of tuples.
---@param space_name string the space name.
---@param tuples table[] an array of tuples.
---@param opts? crud.many_opts
---@return crud.result?
---@return crud.error[]?
function crud.replace_many(space_name, tuples, opts) end

---Insert or replace a batch of objects.
---@param space_name string the space name.
---@param objects table[] an array of objects.
---@param opts? crud.many_opts
---@return crud.result?
---@return crud.error[]?
function crud.replace_object_many(space_name, objects, opts) end

--------------------------------------------------------------------------------
-- Upsert
--------------------------------------------------------------------------------

---Insert a tuple, or apply update operations if it already exists.
---@param space_name string the space name.
---@param tuple table the tuple.
---@param operations table the update operations applied on conflict.
---@param opts? crud.update_opts
---@return crud.result? # a result with an empty `rows` array
---@return crud.error?
function crud.upsert(space_name, tuple, operations, opts) end

---Insert an object, or apply update operations if it already exists.
---@param space_name string the space name.
---@param object table the object.
---@param operations table the update operations applied on conflict.
---@param opts? crud.update_opts
---@return crud.result?
---@return crud.error?
function crud.upsert_object(space_name, object, operations, opts) end

---Upsert a batch of tuples.
---@param space_name string the space name.
---@param tuples_operations table[] an array of `{tuple, operations}` pairs.
---@param opts? crud.many_opts
---@return crud.result?
---@return crud.error[]?
function crud.upsert_many(space_name, tuples_operations, opts) end

---Upsert a batch of objects.
---@param space_name string the space name.
---@param objects_operations table[] an array of `{object, operations}` pairs.
---@param opts? crud.many_opts
---@return crud.result?
---@return crud.error[]?
function crud.upsert_object_many(space_name, objects_operations, opts) end

--------------------------------------------------------------------------------
-- Select / pairs / count / min / max
--------------------------------------------------------------------------------

---Select tuples matching the given conditions.
---@param space_name string the space name.
---@param conditions? crud.condition[] an array of conditions, e.g. `{{'>=', 'age', 18}}`.
---@param opts? crud.select_opts
---@return crud.result?
---@return crud.error?
function crud.select(space_name, conditions, opts) end

---Iterate over tuples matching the given conditions.
---@param space_name string the space name.
---@param conditions? crud.condition[] an array of conditions.
---@param opts? crud.pairs_opts
---@return fun(): integer, table # a generic-for iterator yielding the matching tuples (or objects, if `use_tomap`)
function crud.pairs(space_name, conditions, opts) end

---Count tuples matching the given conditions.
---@param space_name string the space name.
---@param conditions? crud.condition[] an array of conditions.
---@param opts? crud.count_opts
---@return number?
---@return crud.error?
function crud.count(space_name, conditions, opts) end

---Get the tuple with the minimum key value in an index.
---@param space_name string the space name.
---@param index_id? string | integer the index name or id (defaults to the primary index).
---@param opts? crud.minmax_opts
---@return crud.result?
---@return crud.error?
function crud.min(space_name, index_id, opts) end

---Get the tuple with the maximum key value in an index.
---@param space_name string the space name.
---@param index_id? string | integer the index name or id (defaults to the primary index).
---@param opts? crud.minmax_opts
---@return crud.result?
---@return crud.error?
function crud.max(space_name, index_id, opts) end

--------------------------------------------------------------------------------
-- Space-wide operations
--------------------------------------------------------------------------------

---Get the total number of tuples in a space across the cluster.
---@param space_name string the space name.
---@param opts? crud.simple_opts
---@return number?
---@return crud.error?
function crud.len(space_name, opts) end

---Remove all tuples from a space across the cluster.
---@param space_name string the space name.
---@param opts? crud.simple_opts
---@return boolean?
---@return crud.error?
function crud.truncate(space_name, opts) end

---Keep only the given fields in each of `rows`, using `metadata` to resolve field positions.
---@param rows table[] an array of tuples.
---@param metadata? crud.metadata[] the format of the rows.
---@param fields string[] the field names to keep.
---@return crud.result?
---@return crud.error?
function crud.cut_rows(rows, metadata, fields) end

---Keep only the given fields in each of `objects`.
---@param objects table[] an array of objects.
---@param fields string[] the field names to keep.
---@return table[] # the filtered objects
function crud.cut_objects(objects, fields) end

--------------------------------------------------------------------------------
-- Introspection: storage_info / schema / stats
--------------------------------------------------------------------------------

---@class crud.storage_info_entry
---@field status 'running' | 'uninitialized' | 'error' the storage status.
---@field is_master boolean whether the instance is the replica set master.
---@field message? string an error message, when `status` is `'error'`.

---Get the `crud` status of every storage in the cluster.
---@param opts? crud.simple_opts
---@return table<string, crud.storage_info_entry>?
---@return crud.error?
function crud.storage_info(opts) end

---@class crud.index_schema
---@field id integer the index id.
---@field name string the index name.
---@field type string the index type, e.g. `'TREE'`.
---@field unique boolean whether the index is unique.
---@field parts table[] the index parts, each `{fieldno = number, type = string, ...}`.

---@class crud.space_schema
---@field format crud.metadata[] the space format.
---@field indexes table<integer, crud.index_schema> the indexes, keyed by id.

---Get the sharded schema of one space, or of all spaces if `space_name` is omitted.
---@param space_name? string the space name.
---@param opts? { timeout?: number, vshard_router?: string | table, cached?: boolean }
---@return crud.space_schema | table<string, crud.space_schema> | nil
---@return crud.error?
function crud.schema(space_name, opts) end

---@class crud.op_stat_detail
---@field count number the number of operations.
---@field latency number the latency, in seconds.
---@field latency_average number the average latency.
---@field latency_quantile_recent number the recent latency quantile (when quantiles are enabled).
---@field time number the cumulative time spent, in seconds.

---@class crud.op_stats
---@field ok crud.op_stat_detail statistics of successful operations.
---@field error crud.op_stat_detail statistics of failed operations.

---@class crud.space_stats
---@field [string] crud.op_stats statistics per operation name (`insert`, `select`, ...).

---@class crud.stats_result
---@field spaces table<string, crud.space_stats> statistics per space.

---Get the collected statistics for one space, or the whole cluster if `space_name` is omitted.
---@param space_name? string the space name.
---@return crud.stats_result | crud.space_stats
function crud.stats(space_name) end

---Destroy and recreate all statistics collectors.
function crud.reset_stats() end

--------------------------------------------------------------------------------
-- Configuration (callable table, like box.cfg)
--------------------------------------------------------------------------------

---The `crud` configuration. Read it as a table (`crud.cfg`) or call it to update options
---(`crud.cfg{ stats = true }`).
---
---@class crud.cfg_table
---@field stats? boolean enable statistics collection.
---@field stats_driver? 'local' | 'metrics' the statistics backend.
---@field stats_quantiles? boolean collect latency quantiles (requires the `metrics` driver).
---@field stats_quantile_tolerated_error? number the tolerated error of quantile approximation.
---@field stats_quantile_age_bucket_count? number the number of quantile age buckets.
---@field stats_quantile_max_age_time? number the max age of a quantile observation, in seconds.
---@overload fun(cfg: crud.cfg_table)
crud.cfg = {}

--------------------------------------------------------------------------------
-- Read views
--------------------------------------------------------------------------------

---A consistent read view over the cluster, created by [`crud.readview`](lua://crud.readview).
---@class crud.readview
local readview = {}

---Select from the read view (no `mode`/`balance`/`prefer_replica`/`request_timeout`).
---@param space_name string the space name.
---@param conditions? crud.condition[] an array of conditions.
---@param opts? crud.select_opts
---@return crud.result?
---@return crud.error?
function readview:select(space_name, conditions, opts) end

---Iterate over the read view.
---@param space_name string the space name.
---@param conditions? crud.condition[] an array of conditions.
---@param opts? crud.pairs_opts
---@return fun(): integer, table
function readview:pairs(space_name, conditions, opts) end

---Close the read view and free its resources.
---@param opts? { timeout?: number }
function readview:close(opts) end

---Open a consistent read view over the cluster.
---@param opts? { name?: string, timeout?: number, vshard_router?: string | table }
---@return crud.readview
function crud.readview(opts) end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

---Initialize `crud` on a storage instance (call after `vshard.storage.cfg`).
---@param opts? { async?: boolean }
function crud.init_storage(opts) end

---Initialize `crud` on a router instance (call after `vshard.router.cfg`).
function crud.init_router() end

---The module version string.
---@type string
crud._VERSION = nil

return crud
