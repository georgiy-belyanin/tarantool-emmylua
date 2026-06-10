-- Theme: the `metrics` rock -- collectors (counter/gauge/histogram/summary),
-- label sets, callbacks, and collection. Every collect() result is asserted as
-- a typed observation array and its fields are used (value in arithmetic, etc.),
-- so a wrong return/field annotation fires.
-- validate: enterprise -- `metrics` is bundled with Tarantool EE; the community
-- build needs it installed as a separate rock, so it is skipped there.

local metrics = require('metrics')

metrics.cfg({ labels = { app = 'sample' } })

--------------------------------------------------------------------------------
-- Counter -> collect() yields typed observations
--------------------------------------------------------------------------------

local requests = metrics.counter('requests_total', 'Total HTTP requests')
requests:inc(1, { method = 'GET', status = '200' })
requests:inc(3, { method = 'POST', status = '500' })
requests:inc(1, { method = 'GET', status = '200' })

---@type metrics.observation[]
local req_obs = requests:collect()
---@type number
local seen = 0
for _, obs in ipairs(req_obs) do
    ---@type string
    local name = obs.metric_name
    ---@type number
    local value = obs.value
    ---@type table
    local labels = obs.label_pairs
    seen = seen + value -- value must be a number for this to type-check
    print(name, value, labels.method)
end
print('counter observations', #req_obs, seen)

--------------------------------------------------------------------------------
-- Gauge
--------------------------------------------------------------------------------

local connections = metrics.gauge('connections_active', 'Active connections')
connections:set(10)
connections:inc(2)
connections:dec(5, { pool = 'primary' })
---@type metrics.observation[]
local conn_obs = connections:collect()
local first_conn = conn_obs[1]
---@type number
local conn_value = (first_conn ~= nil) and first_conn.value or 0
print(#conn_obs, conn_value)

--------------------------------------------------------------------------------
-- Histogram
--------------------------------------------------------------------------------

local latency = metrics.histogram('latency_seconds', 'Latency', { 0.01, 0.05, 0.1, 1.0 })
latency:observe(0.003, { route = '/api/v1' })
latency:observe(0.42, { route = '/api/v2' })
---@type metrics.observation[]
local lat_obs = latency:collect()
-- A histogram emits _bucket/_sum/_count observations; sum their values.
---@type number
local lat_total = 0
for _, obs in ipairs(lat_obs) do lat_total = lat_total + obs.value end
print(#lat_obs, lat_total)

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

local sizes = metrics.summary('response_bytes', 'Response sizes',
    { [0.5] = 0.01, [0.9] = 0.01, [0.99] = 0.001 },
    { max_age_time = 60, age_buckets_count = 5 })
sizes:observe(512)
sizes:observe(2048, { kind = 'json' })
---@type metrics.observation[]
local size_obs = sizes:collect()
print(#size_obs)

--------------------------------------------------------------------------------
-- Callbacks, global labels, default metrics, and a full collect
--------------------------------------------------------------------------------

metrics.register_callback(function() connections:set(7) end)
metrics.set_global_labels({ datacenter = 'eu-west' })
metrics.enable_default_metrics()

---@type metrics.observation[]
local all = metrics.collect()
-- Aggregate every observation's value (each value must be a number).
---@type number
local grand_total = 0
for _, obs in ipairs(all) do
    grand_total = grand_total + obs.value
end
print('total observations', #all, grand_total)

-- The registry of created collectors.
---@type metrics.collector[]
local collectors = metrics.collectors()
print('collectors', #collectors)
