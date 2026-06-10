-- Theme: core utility builtins not covered by the other samples -- Unicode
-- (utf8), table helpers (generic deep/shallow copy), low-level byte buffers
-- (buffer/ibuf), and named loggers (log). Every result is captured at its
-- concrete type and used in a type-demanding way. Standalone-runnable.

local utf8 = require('utf8')
local buffer = require('buffer')
local log = require('log')

--------------------------------------------------------------------------------
-- utf8: Unicode-aware string operations with concrete return types
--------------------------------------------------------------------------------

local text = 'Cafe-Метро'

---@type number
local char_count = utf8.len(text)
---@type string
local upper = utf8.upper(text)
---@type string
local lower = utf8.lower(text)
---@type string
local head = utf8.sub(text, 1, 4)

-- next() yields TWO numbers: the next byte position and the code point.
local byte_pos, code_point = utf8.next(text, 1)
---@type number
local _bp = byte_pos
---@type number
local _cp = code_point

-- Classification predicates return booleans; combine several into one.
---@type boolean
local is_alpha = utf8.isalpha('e')
---@type boolean
local is_digit = utf8.isdigit('7')
---@type boolean
local is_upper = utf8.isupper('M')
local classified = is_alpha and is_digit and is_upper

-- Comparisons return -1 / 0 / +1; build a string back from code points.
---@type number
local order = utf8.cmp('a', 'b')
---@type string
local built = utf8.char(72, 105) -- "Hi"

print(char_count, upper, lower, head, _bp, _cp, classified, order, built)

--------------------------------------------------------------------------------
-- table: generic deep/shallow copy -- the element type T flows in and out
--------------------------------------------------------------------------------

---@class config_node
---@field name string
---@field children string[]
---@field weight integer
local node = { name = 'root', children = { 'a', 'b' }, weight = 3 }

-- deepcopy is generic (T -> T), so the clone keeps config_node's typed fields.
local clone = table.deepcopy(node)
---@type string
local clone_name = clone.name
---@type string[]
local clone_children = clone.children
---@type integer
local clone_weight = clone.weight
print(clone_name, #clone_children, clone_weight)

-- A shallow copy of a plain string array -> string[] is preserved.
local shallow = table.copy({ 'x', 'y', 'z' })
---@type string
local first = assert(shallow[1])
print(first, #shallow)

--------------------------------------------------------------------------------
-- buffer: a low-level ibuf with cdata pointers and integer size accounting
--------------------------------------------------------------------------------

local ib = buffer.ibuf(256)

---@type integer
local capacity = ib:capacity()
---@type integer
local used = ib:size()
---@type integer
local unused = ib:unused()
---@type integer
local position = ib:pos()

-- alloc() returns a write-position cdata pointer; the struct exposes pointers too.
---@type ffi.cdata*
local wptr = ib:alloc(16)
---@type ffi.cdata*
local base = ib.buf

print(capacity, used, unused, position, wptr, base)
ib:reset()

--------------------------------------------------------------------------------
-- log: a named logger (log.new -> log) and runtime level control
--------------------------------------------------------------------------------

local applog = log.new('sample.module')
applog.info('named logger ready: counted %d characters', char_count)
log.level(5)
log.info('default logger at info level')
