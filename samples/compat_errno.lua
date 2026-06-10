-- Theme: runtime configuration and miscellaneous builtins not covered by the
-- other samples -- the `compat` module (forward-compatibility options), `errno`
-- (system error numbers), and the `tarantool` global helpers. Every result is
-- captured at its concrete type and used. Standalone-runnable (no box.cfg).

local errno = require('errno')
local compat = require('compat')

--------------------------------------------------------------------------------
-- compat: each option is a typed record; the module itself is callable
--------------------------------------------------------------------------------

-- A named option resolves to a compat.option record; its current/default
-- states are the 'new' | 'old' | 'default' union, and brief is a string.
local opt = compat.json_escape_forward_slash
---@type 'new' | 'old' | 'default'
local current = opt.current
---@type 'new' | 'old' | 'default'
local default = opt.default
---@type string
local brief = opt.brief
print(current, default, brief)

-- Read another option, then set options via the callable module form.
---@type 'new' | 'old' | 'default'
local channel_mode = compat.fiber_channel_close_mode.current
compat({ json_escape_forward_slash = 'new', sql_seq_scan_default = 'old' })

-- dump(mode?) serialises the configuration into a restoring Lua command string.
---@type string
local dumped = compat.dump('default')
print(channel_mode, #dumped)

--------------------------------------------------------------------------------
-- errno: the callable current-errno, strerror, and named integer constants
--------------------------------------------------------------------------------

-- The module is callable and returns the current errno value as an integer.
---@type integer
local current_errno = errno()

-- Named constants are integers; use them as arguments and arithmetically.
---@type integer
local eagain = errno.EAGAIN
---@type integer
local eacces = errno.EACCES
local distinct = eagain ~= eacces

-- strerror maps a code to its message string.
---@type string
local message = errno.strerror(eagain)
print(current_errno, distinct, message, errno.strerror(eacces))

--------------------------------------------------------------------------------
-- tarantool global helpers: tonumber64, dostring, table.new, package.search
--------------------------------------------------------------------------------

-- 64-bit integer parsing returns a cdata or a number.
local big = tonumber64('9223372036854775807')

-- dostring evaluates a Lua chunk and returns its results (any); cast and use.
local evaluated = dostring('return 40 + 2') --[[@as integer]]
---@type integer
local answer = evaluated * 1

-- table.new preallocates; package.search resolves a module name to a file path.
local preallocated = table.new(16, 0)
---@type string?
local json_path = package.search('strict')
print(big, answer, #preallocated, json_path)
