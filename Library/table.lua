---@meta

---# Builtin `table` module extensions
---
---The `table` module has everything in the
---[standard Lua table library](https://www.lua.org/manual/5.1/manual.html#5.5),
---and some Tarantool extensions.
---
---This file only declares the additional functions that the Tarantool developers have added.

---Return a "deep" copy of the table -- a copy which follows
---nested structures to any depth and does not depend on pointers,
---it copies the contents.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> input_table = {1,{'a','b'}}
--- ---
--- ...
---
--- tarantool> output_table = table.deepcopy(input_table)
--- ---
--- ...
---
--- tarantool> output_table
--- ---
--- - - 1
---   - - a
---     - b
--- ...
--- ```
---
---@generic T
---@param input_table T the table to copy
---@return T copy the copy of the table
function table.deepcopy(input_table) end

---Make a copy of an array.
---
---@generic T
---@param input_table T the table to copy
---@return T copy a copy of the table
function table.copy(input_table) end
