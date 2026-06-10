---@meta

---# Submodule `membership.options`
---
---Tunable parameters of the [`membership`](lua://membership) gossip protocol. They can be set as follows:
---
--- ```lua
--- local options = require('membership.options')
--- options.PROTOCOL_PERIOD_SECONDS = 0.2
--- ```
---
---@class membership.options
---@field PROTOCOL_PERIOD_SECONDS number Period of sending direct pings. Denoted as `T'` in the SWIM protocol.
---@field ACK_TIMEOUT_SECONDS number Time to wait for an ACK message after a ping. If a member is late to reply, the indirect ping algorithm is invoked.
---@field ANTI_ENTROPY_PERIOD_SECONDS number Period to perform the anti-entropy synchronization algorithm of the SWIM protocol.
---@field SUSPECT_TIMEOUT_SECONDS number Timeout to mark `suspect` members as `dead`.
---@field NUM_FAILURE_DETECTION_SUBGROUPS number Number of members to try pinging a `suspect` indirectly. Denoted as `k` in the SWIM protocol.
local options = {}

return options
