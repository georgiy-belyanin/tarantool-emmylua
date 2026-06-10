---@meta

---# Builtin `debug` module extensions
---
---The `debug` module has everything in the standard Lua `debug` library, and some Tarantool extensions.
---
---This file only declares the additional functions that the Tarantool developers have added.

---Return a string with the relative path to the source file directory.
---
---Instead of `debug.sourcedir()` one can say `debug.__dir__` which means the same thing.
---
---Determining the real path to a directory is only possible
---if the function was defined in a Lua file (this restriction
---may not apply for [loadstring()](https://www.lua.org/pil/8.html)
---since Lua will store the entire string in debug info).
---
---If `debug.sourcedir()` is part of a `return` argument,
---then it should be inside parentheses: `return (debug.sourcedir())`.
---
---@param level? number the level of the call stack which should contain the path (default is 2)
---@return string path a string with the relative path to the source file directory
function debug.sourcedir(level) end

---Return a string with the relative path to the source file.
---
---Instead of `debug.sourcefile()` one can say `debug.__file__` which means the same thing.
---
---Determining the real path to a file is only possible
---if the function was defined in a Lua file (this restriction
---may not apply to `loadstring()` since Lua will store the
---entire string in debug info).
---
---If `debug.sourcefile()` is part of a `return` argument,
---then it should be inside parentheses: `return (debug.sourcefile())`.
---
---@param level? number the level of the call stack which should contain the path (default is 2)
---@return string path a string with the relative path to the source file
function debug.sourcefile(level) end

---The relative path to the source file directory. Same as [`debug.sourcedir()`](lua://debug.sourcedir).
---@type string
debug.__dir__ = nil

---The relative path to the source file. Same as [`debug.sourcefile()`](lua://debug.sourcefile).
---@type string
debug.__file__ = nil
