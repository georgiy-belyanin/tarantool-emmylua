---@meta

---# Builtin `os` module extensions
---
---The `os` module has everything in the standard Lua `os` library, and some Tarantool extensions.
---
---This file only declares the additional functions that the Tarantool developers have added.

---Return a table containing all environment variables.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> os.environ()['TERM']..os.environ()['SHELL']
--- ---
--- - xterm/bin/bash
--- ...
--- ```
---
---@return table<string, string> environ a table containing all environment variables
function os.environ() end

---Set an environment variable.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> os.setenv('VERSION','99')
--- ---
--- -
--- ...
--- ```
---
---@param variable_name string
---@param variable_value string
function os.setenv(variable_name, variable_value) end
