-- Theme: Tarantool scalar data types and serializers.
--
-- Covers uuid, decimal, datetime (+ interval), varbinary, and the json / msgpack /
-- yaml serializers. Every result is captured at its concrete type and USED in a
-- type-demanding way (chained typed arithmetic, field access on cast results,
-- string methods), so a wrong return annotation produces a diagnostic.
-- Standalone-runnable (no box.cfg needed).

local uuid = require('uuid')
local decimal = require('decimal')
local datetime = require('datetime')
local varbinary = require('varbinary')
local json = require('json')
local msgpack = require('msgpack')
local yaml = require('yaml')

--------------------------------------------------------------------------------
-- uuid: object methods -> strings, predicates -> booleans
--------------------------------------------------------------------------------

local u = uuid.new()
local u_from_str = uuid.fromstr('64d22e4d-ac92-4a23-899a-e59f34af5479')
local u_from_bin = uuid.frombin(u:bin())

---@type string
local u_str = u:str()
---@type string
local u_bin_le = u:bin('l')
-- Use the strings as strings (a string method + length arithmetic).
local id_len = #u_str + #u_bin_le

---@type boolean
local is_uuid = uuid.is_uuid(u)
---@type boolean
local is_nil = u:isnil()
local both_checks = is_uuid and not is_nil
print(u_str:upper(), u_from_str, u_from_bin, id_len, both_checks)

--------------------------------------------------------------------------------
-- decimal: operators and module functions all yield decimals (chainable)
--------------------------------------------------------------------------------

---@type decimal
local d1 = decimal.new('3.14')
---@type decimal
local d2 = decimal.new(2)

-- Arithmetic metamethods preserve the decimal type.
---@type decimal
local d_sum = d1 + d2
---@type decimal
local d_mul = d1 * d2
---@type decimal
local d_div = d1 / d2

-- Module functions return decimals too; chaining them only type-checks if each
-- result is a decimal (the operands of `+` below must all be decimals).
---@type decimal
local d_abs = decimal.abs(decimal.new('-5.5'))
---@type decimal
local d_sqrt = decimal.sqrt(decimal.new('16'))
---@type decimal
local d_log10 = decimal.log10(decimal.new('1000'))
local d_total = d_sum + d_mul + d_div + d_abs + d_sqrt + d_log10

-- precision/scale -> number; is_decimal -> boolean.
---@type number
local precision = decimal.precision(d_total)
---@type number
local scale = decimal.scale(d_total)
---@type boolean
local is_decimal = decimal.is_decimal(d_total)
print(d_total, precision + scale, is_decimal)

--------------------------------------------------------------------------------
-- datetime + interval: field access, formatting, and typed arithmetic
--------------------------------------------------------------------------------

---@type datetime
local dt = datetime.new({ year = 2021, month = 8, day = 20, hour = 18, min = 25, sec = 20, tzoffset = 180 })
---@type datetime
local dt_parsed = datetime.parse('2021-08-20T18:25:20Z')

-- Fields are typed integers/strings directly on the object.
---@type integer
local year = dt.year
---@type integer
local month = dt.month
---@type string
local formatted = dt:format('%Y-%m-%dT%H:%M:%S')

-- Typed arithmetic: datetime +/- interval -> datetime; datetime - datetime -> interval.
---@type datetime.interval
local iv = datetime.interval.new({ month = 1, day = 7 })
---@type datetime
local dt_plus = dt + iv
---@type datetime
local dt_minus = dt - iv
---@type datetime.interval
local span = dt_parsed - dt
print(year, month, formatted, dt_plus:format(), dt_minus:format(), span)

--------------------------------------------------------------------------------
-- varbinary
--------------------------------------------------------------------------------

local vb = varbinary.new('\xDE\xAD\xBE\xEF')
---@type boolean
local is_vb = varbinary.is(vb)
print(vb, is_vb)

--------------------------------------------------------------------------------
-- json / msgpack / yaml: encode -> string; decode -> any (cast, then USE fields)
--------------------------------------------------------------------------------

---@type string
local j = json.encode({ id = 1, tags = { 'a', 'b' }, nested = { x = 1 } })
-- decode returns `any`; cast to a record and use the typed fields.
local decoded = json.decode(j) --[[@as { id: integer, tags: string[] }]]
---@type integer
local decoded_id = decoded.id
---@type string
local first_tag = assert(decoded.tags[1])
-- Per-call options + module config + NULL placeholder.
---@type string
local j_cfg = json.encode({ 1, 2, 3 }, { encode_max_depth = 4 })
json.cfg({ encode_use_tostring = true })
print(j, decoded_id, first_tag, j_cfg, json.NULL)

---@type string
local mp = msgpack.encode({ id = 1, name = 'x' })
local mp_obj = msgpack.object({ 1, 2, 3 })
---@type boolean
local is_obj = msgpack.is_object(mp_obj)
print(#mp, is_obj, msgpack.NULL)

---@type string
local y = yaml.encode({ list = { 1, 2, 3 }, map = { k = 'v' } })
local y_decoded = yaml.decode(y) --[[@as { map: table<string, string> }]]
---@type table<string, string>
local y_map = y_decoded.map
print(#y, y_map['k'], yaml.NULL)
