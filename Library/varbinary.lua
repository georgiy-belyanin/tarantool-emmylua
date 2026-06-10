---@meta

---# Builtin `varbinary` module
---
---The `varbinary` module provides functions for operating on variable-length binary objects in Lua.
---It provides utilities for creating `varbinary` objects, checking their type, and defines metamethods
---for equality, length, and string conversion.
---
---`varbinary` objects preserve binary type when encoded via MsgPack and YAML, but are converted to strings in JSON.
local varbinary = {}

---@class varbinary: ffi.cdata*
---@operator len: integer
---@operator eq(varbinary): boolean
local varbinary_obj = {}

---Check that the given object is a `varbinary` object.
---
---Returns `true` if the object is a `varbinary` cdata object, `false` otherwise.
---
---**Example:**
---
--- ```lua
--- local bin = varbinary.new('data')
--- print(varbinary.is(bin))      -- true
--- print(varbinary.is('data'))  -- false
--- ```
---
---@param object any
---@return boolean
function varbinary.is(object) end

---Create a new `varbinary` object from a string.
---
---Takes a Lua string and wraps it into a `varbinary` cdata object.
---
---**Example:**
---
--- ```lua
--- local bin = varbinary.new('data')
--- print(bin) -- "data"
--- ```
---
---@param str string
---@return varbinary
function varbinary.new(str) end


---Create a new `varbinary` object from a cdata pointer and size.
---
---Takes a `cdata` pointer and a size in bytes, and creates a `varbinary` object from that memory region.
---
---**Example:**
---
--- ```lua
--- local ffi = require('ffi')
--- local ptr = ffi.new('char[5]', 'data\0')
--- local bin2 = varbinary.new(ptr, 4)
--- print(bin2) -- "data"
--- ```
---
---@param ptr cdata
---@param size integer
---@return varbinary
function varbinary.new(ptr, size) end

---Equality metamethod for `varbinary` objects.
---
---Compares a `varbinary` object with another `varbinary` or string.
---Returns `true` if the binary contents are identical.
---
---Defined for use with `==` and `~=` operators.
---
---**Example:**
---
--- ```lua
--- local bin = varbinary.new('data')
--- print(bin == varbinary.new('data'))  -- true
--- print(bin == 'data')                 -- true
--- print(bin ~= 'other')               -- true
--- ```
---
---@param other varbinary
---@return boolean
function varbinary_obj:__eq(other) end

---Length metamethod for `varbinary` objects.
---
---Returns the number of bytes in the binary data.
---
---Defined for use with the `#` operator.
---
---**Example:**
---
--- ```lua
--- local bin = varbinary.new('data')
--- print(#bin) -- 4
--- ```
---
---@return integer
function varbinary_obj:__len() end

---String conversion metamethod for `varbinary` objects.
---
---Returns the binary data as a plain Lua string.
---
---Defined for use with `tostring()`.
---
---**Example:**
---
--- ```lua
--- local bin = varbinary.new('data')
--- print(tostring(bin)) -- "data"
--- ```
---
---@return string
function varbinary_obj:__tostring() end

return varbinary
