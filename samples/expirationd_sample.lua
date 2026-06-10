-- validate: skip -- the `expirationd` rock is not installed here; type-checked only.
--
-- Theme: the `expirationd` rock (TTL background tasks). start() yields a typed
-- task whose statistics() returns a typed numeric record; callbacks in the
-- options table receive typed arguments. Every result is captured and used.

local expirationd = require('expirationd')

expirationd.cfg({ metrics = true })

-- The expiration predicate receives (args, tuple) and returns a boolean.
---@param args { field: integer, ttl: number }
---@param tuple table
---@return boolean
local function is_expired(args, tuple)
    return tuple[args.field] + args.ttl < os.time()
end

-- start() -> a typed task; the options table exercises several typed callbacks.
---@type expirationd.task
local task = expirationd.start('clean_logs', box.space._space.id, is_expired, {
    args = { field = 2, ttl = 3600 },
    tuples_per_iteration = 200,
    full_scan_time = 1800,
    iterator_type = 'ALL',
    atomic_iteration = true,
    process_while = function(t)
        ---@type string
        local running_name = t.name
        return running_name ~= ''
    end,
    process_expired_tuple = function(space, args, tuple)
        print(space, args, tuple[1])
    end,
    on_full_scan_complete = function() print('scan done') end,
})

---@type string
local task_name = task.name
print(task_name)

--------------------------------------------------------------------------------
-- statistics(): a typed numeric record
--------------------------------------------------------------------------------

local stats = task:statistics()
---@type number
local checked = stats.checked_count
---@type number
local expired = stats.expired_count
---@type number
local restarts = stats.restarts
---@type number
local working_time = stats.working_time
local skipped = checked - expired
print(checked, expired, restarts, working_time, skipped)

--------------------------------------------------------------------------------
-- Lifecycle control
--------------------------------------------------------------------------------

task:stop()
task:start()
task:restart()

-- Module-level registry: tasks() -> string[]; task(name) -> the task; stats().
---@type string[]
local names = expirationd.tasks()
---@type string
local first_name = assert(names[1])

local same_task = expirationd.task(first_name)
---@type number
local same_checked = same_task:statistics().checked_count

local global_stats = expirationd.stats()
print(#names, first_name, same_checked, global_stats.restarts)

task:kill()
expirationd.kill('clean_logs')
