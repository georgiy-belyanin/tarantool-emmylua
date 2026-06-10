---@meta

---# `metrics.plugins.graphite` submodule
local graphite = {}

---@class metrics.plugins.graphite.options
---@field prefix? string metrics prefix (`'tarantool'` by default)
---@field host? string Graphite server host (`'127.0.0.1'` by default)
---@field port? number Graphite server port (`2003` by default)
---@field send_interval? number metrics collection interval in seconds (`2` by default)

---Send all metrics to a remote Graphite server.
---Exported metric names are formatted as follows: `<prefix>.<metric_name>`.
---
---**Example**
---
--- ```lua
--- local graphite_plugin = require('metrics.plugins.graphite')
--- graphite_plugin.init {
---     prefix = 'tarantool',
---     host = '127.0.0.1',
---     port = 2003,
---     send_interval = 1,
--- }
--- ```
---
---@param options metrics.plugins.graphite.options possible options
function graphite.init(options) end

return graphite
