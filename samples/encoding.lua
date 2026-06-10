-- Theme: encoding & parsing utilities -- uri, iconv, pickle, csv.
-- Standalone-runnable (no box.cfg).

local uri = require('uri')
local iconv = require('iconv')
local pickle = require('pickle')
local csv = require('csv')

--------------------------------------------------------------------------------
-- uri: parse / format / escape / unescape
--------------------------------------------------------------------------------

local parsed = uri.parse('http://user:secret@example.com:3301/path?key=value')
assert(parsed ~= nil)
---@type string?
local _scheme = parsed.scheme
---@type string?
local _host = parsed.host
---@type string?
local _login = parsed.login
print(_scheme, _host, _login, parsed.service, parsed.path)

-- Build a URI string back from its parts.
---@type string
local _formatted = uri.format({ host = 'localhost', service = '3301' })
-- Include the password in the output.
---@type string
local _formatted_pw = uri.format({ host = 'h', login = 'u', password = 'p' }, true)
print(_formatted, _formatted_pw)

-- Percent-escaping.
---@type string
local _escaped = uri.escape('a b/c?d')
---@type string
local _unescaped = uri.unescape(_escaped)
print(_escaped, _unescaped)

--------------------------------------------------------------------------------
-- iconv: character-set conversion
--------------------------------------------------------------------------------

-- A converter is a callable cdata object.
local converter = iconv.new('UTF-8', 'UTF-8')
---@type string
local _converted = converter('hello, world')
print(_converted)

--------------------------------------------------------------------------------
-- pickle: pack / unpack of binary protocol primitives
--------------------------------------------------------------------------------

-- Pack two 32-bit integers and a length-prefixed string.
---@type string
local _packed = pickle.pack('ii', 100, 200)
local _a, _b = pickle.unpack('ii', _packed)
print(#_packed, _a, _b)

-- Bytes and big strings.
---@type string
local _bytes = pickle.pack('bbb', 1, 2, 3)
local _x, _y, _z = pickle.unpack('bbb', _bytes)
print(_x, _y, _z)

--------------------------------------------------------------------------------
-- csv: load / dump / iterate
--------------------------------------------------------------------------------

-- Load a CSV string into a table of rows.
local rows = csv.load('id,name\n1,Roxette\n2,Scorpions')
---@type table
local _rows = rows
print(#rows, rows[1][1], rows[2][2])

-- Load with options (custom delimiter).
local semi = csv.load('a;b;c', { delimiter = ';' })
print(#semi, semi[1][2])

-- Dump a table of rows back to a CSV string.
---@type string
local _dumped = csv.dump({ { 'id', 'name' }, { 1, 'Roxette' } })
print(_dumped)

-- Iterate row by row.
for i, row in csv.iterate('x,y\n1,2') do
    print(i, row[1], row[2])
end
