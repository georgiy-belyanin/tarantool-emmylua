-- Theme: cooperative concurrency -- fibers, channels, condition variables, clocks.
-- Standalone-runnable (no box.cfg). Kept strictly non-blocking so it terminates.

local fiber = require('fiber')
local clock = require('clock')

--------------------------------------------------------------------------------
-- Fibers: create / new, join, identity, status
--------------------------------------------------------------------------------

-- fiber.create starts the fiber immediately (until its first yield).
local started = false
fiber.create(function(a, b)
    started = (a + b == 3)
end, 1, 2)

-- fiber.new creates a fiber that starts after the creator yields.
local worker = fiber.new(function() return 'done' end)
worker:set_joinable(true)
fiber.yield() -- let the worker run

---@type boolean
local _joinable_ok, _result = worker:join()
print(started, _joinable_ok, _result)

-- The current fiber.
local self = fiber.self()
---@type number
local _self_id = self:id()
---@type string
local _self_name = self:name()
self:set_joinable(false)

-- fiber module-level identity / scheduling helpers.
---@type number
local _id = fiber.id()
---@type number
local _now = fiber.time()
---@type number
local _clock = fiber.clock()
fiber.sleep(0)
fiber.yield()

-- Name a fiber and read it back.
local named = fiber.create(function() fiber.sleep(1000) end)
named:set_joinable(true)
named:name('greeter', { truncate = true })
---@type string
local _named = named:name()
---@type string
local _status = named:status()
named:cancel()

-- Look a fiber up by id and inspect the registry.
local _found = fiber.find(_id)
local _info = fiber.info()
print(_id, _now, _clock, _named, _status, _found, _info)

--------------------------------------------------------------------------------
-- Channels
--------------------------------------------------------------------------------

local ch = fiber.channel(2)

-- Put within capacity (non-blocking), then drain.
ch:put('first')
ch:put('second', 0)

---@type boolean
local _full = ch:is_full()
---@type number
local _count = ch:count()
---@type number
local _size = ch:size()
---@type boolean
local _has_readers = ch:has_readers()
---@type boolean
local _has_writers = ch:has_writers()

local _a = ch:get()
local _b = ch:get(0)
---@type boolean
local _empty = ch:is_empty()

ch:close()
---@type boolean
local _closed = ch:is_closed()
print(_full, _count, _size, _has_readers, _has_writers, _a, _b, _empty, _closed)

--------------------------------------------------------------------------------
-- Condition variables
--------------------------------------------------------------------------------

local cond = fiber.cond()

-- A waiter fiber that wakes on signal.
local woke = false
local waiter = fiber.create(function()
    woke = cond:wait(0.01)
end)

cond:signal()
cond:broadcast()
fiber.sleep(0)
print(woke, waiter)

--------------------------------------------------------------------------------
-- Clocks
--------------------------------------------------------------------------------

---@type number
local _time = clock.time()
---@type number
local _monotonic = clock.monotonic()
---@type number
local _proc = clock.proc()
---@type number
local _realtime = clock.realtime()
---@type number
local _thread = clock.thread()

-- 64-bit variants return cdata (int64).
local _time64 = clock.time64()
local _monotonic64 = clock.monotonic64()

-- Benchmark a function (its return values are documented as variadic generics;
-- a documented generic limitation, so this sample benchmarks a void callback).
local _elapsed = clock.bench(function() end)
print(_time, _monotonic, _proc, _realtime, _thread, _time64, _monotonic64, _elapsed)
