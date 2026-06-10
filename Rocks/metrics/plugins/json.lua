---@meta

---# `metrics.plugins.json` submodule
local json = {}

---Export metrics in the JSON format.
---
---**Important:** The values can also be `+-math.huge` and `math.huge * 0`. In such case:
---
---*   `math.huge` is serialized to `"inf"`
---*   `-math.huge` is serialized to `"-inf"`
---*   `math.huge * 0` is serialized to `"nan"`.
---
---**Example**
---
--- ```lua
--- local json_plugin = require('metrics.plugins.json')
--- local json_metrics = json_plugin.export()
--- ```
---
---@return string json a string containing metrics in the JSON format
function json.export() end

return json
