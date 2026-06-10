---@meta

---# `metrics.plugins.prometheus` submodule
local prometheus = {}

---@class metrics.plugins.prometheus.http_response
---@field status integer set to `200`
---@field headers table response headers
---@field body string metrics in the Prometheus format

---Get an HTTP response object containing metrics in the Prometheus format.
---
---**Example**
---
--- ```lua
--- local prometheus_plugin = require('metrics.plugins.prometheus')
--- local prometheus_metrics = prometheus_plugin.collect_http()
--- ```
---
---@return metrics.plugins.prometheus.http_response response a table containing `status`, `headers`, and `body`
function prometheus.collect_http() end

return prometheus
