---@meta

---# Rock `expirationd`
---
---The `expirationd` rock allows you to set up a background task that emulates a TTL (time to live) for
---tuples: it periodically scans a space and removes (or otherwise processes) tuples that satisfy a
---user-defined "expired" predicate.
---
---See the API documentation at <https://tarantool.github.io/expirationd/>.
---
---**Example:**
---
--- ```lua
--- local expirationd = require('expirationd')
--- local function is_expired(args, tuple)
---     return tuple[args.field] < os.time()
--- end
--- local task = expirationd.start('clean_old', box.space.logs.id, is_expired, {
---     args = { field = 2 },
---     tuples_per_iteration = 200,
---     full_scan_time = 3600,
--- })
--- ```
local expirationd = {}

---Statistics of an `expirationd` task.
---
---@class expirationd.stats
---@field checked_count number the number of tuples examined (expired plus skipped).
---@field expired_count number the number of tuples that were expired/processed.
---@field restarts number the number of full-scan cycles (at least 1).
---@field working_time number the cumulative operation duration, in seconds.

---An `expirationd` task object, returned by [`start`](lua://expirationd.start) and [`task`](lua://expirationd.task).
---
---@class expirationd.task
---@field name string the task identifier.
local task = {}

---Resume processing of a stopped task.
function task:start() end

---Pause processing of the task without removing it.
function task:stop() end

---Restart the task.
function task:restart() end

---Stop the task and remove it from the list of registered tasks.
function task:kill() end

---Fetch the task's metrics.
---
---@return expirationd.stats
function task:statistics() end

---Options for [`expirationd.start`](lua://expirationd.start).
---
---@class expirationd.start_options
---@field args? any custom arguments passed to the `is_tuple_expired`, `process_expired_tuple`, and `start_key` callbacks.
---@field atomic_iteration? boolean (Default: false) if `true`, all tuples of one batch are processed in a single transaction.
---@field force? boolean (Default: false) if `true`, the task is launched even on replicas (read-only instances).
---@field force_allow_functional_index? boolean if `true`, allows iterating with a functional index.
---@field full_scan_delay? number (Default: 1) delay between full scans, in seconds.
---@field full_scan_time? number (Default: 3600) the time required for a full scan, in seconds.
---@field index? string | integer the name or id of the index to iterate over.
---@field iterate_with? fun(task: expirationd.task) a custom iterator generator; receives the task.
---@field iteration_delay? number (Default: 1) the maximum delay between iterations, in seconds.
---@field iterator_type? box.iterator (Default: 'ALL') the iterator direction.
---@field on_full_scan_complete? fun() a callback invoked after each full scan (success or error).
---@field on_full_scan_error? fun(task: expirationd.task, err: any) a callback invoked when a full scan fails.
---@field on_full_scan_start? fun(task: expirationd.task) a callback invoked before each full scan.
---@field on_full_scan_success? fun(task: expirationd.task) a callback invoked after a successful full scan.
---@field process_expired_tuple? fun(space: any, args: any, tuple: table) the action applied to an expired tuple (defaults to deleting it).
---@field process_while? fun(task: expirationd.task): boolean a predicate that stops the current iteration when it returns `false`.
---@field start_key? any | fun(): any the key (or a function returning the key) to start iteration from.
---@field tuples_per_iteration? number (Default: 1024) the number of tuples processed in one batch.
---@field vinyl_assumed_space_len? number (Default: 10^7) the assumed number of tuples in a vinyl space.
---@field vinyl_assumed_space_len_factor? number (Default: 2) the factor by which the assumed vinyl space length grows.

---Register and start a new expiration task.
---
---When `is_tuple_expired` is omitted, the default predicate deletes tuples older than
---`options.args.lifetime_in_seconds`, checking the field `options.args.time_create_field`.
---
---@param name string a unique task identifier.
---@param space string | integer the name or id of the space to process.
---@param is_tuple_expired? fun(args: any, tuple: table): boolean a predicate returning `true` for a tuple that should be expired.
---@param options? expirationd.start_options
---@return expirationd.task
function expirationd.start(name, space, is_tuple_expired, options) end

---Stop a task and remove it from the list of registered tasks.
---
---@param name string the task identifier.
function expirationd.kill(name) end

---Get the statistics of a task, or of all tasks if `name` is omitted.
---
---@param name? string the task identifier.
---@return expirationd.stats
function expirationd.stats(name) end

---Get a registered task object by its name.
---
---@param name string the task identifier.
---@return expirationd.task
function expirationd.task(name) end

---Get the list of names of all registered tasks.
---
---@return string[]
function expirationd.tasks() end

---Configure the `expirationd` module.
---
---@param options { metrics?: boolean } if `metrics` is `true` (the default), metrics collection is enabled.
function expirationd.cfg(options) end

---Reload the module, restarting all registered tasks. Used internally on package upgrade.
function expirationd.update() end

return expirationd
