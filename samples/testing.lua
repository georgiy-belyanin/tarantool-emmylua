-- Theme: argument validation (checks) and the TAP framework (tap).
-- Every checker / assertion result is captured at its concrete type (boolean)
-- and used, so a wrong return annotation produces a diagnostic.
-- Standalone-runnable.

local checks = require('checks')
local tap = require('tap')
local uuid = require('uuid')

--------------------------------------------------------------------------------
-- checks: validate arguments by type qualifier (incl. unions / optional / table)
--------------------------------------------------------------------------------

local function greet(name, times, _opts)
    checks('string', 'number', '?table')
    return ('%s x%d'):format(name, times)
end
-- The result is a string -> exercise it with a string method.
---@type string
local greeting = greet('Roxette', 2)
print(greeting:upper(), greet('Scorpions', 1, { loud = true }))

local function flexible(value, _flag)
    checks('string|number', '?boolean')
    return value
end
print(flexible(42), flexible('x', true))

-- Custom checker on the global `checkers` table, then a table-form checks().
function checkers.positive(value)
    return type(value) == 'number' and value > 0
end
local function need_positive(n) checks('positive') return n end
local function configure(opts) checks({ host = 'string', port = '?number' }) return opts end
print(need_positive(5), configure({ host = 'localhost', port = 3301 }).host)

-- Built-in / custom checkers return booleans -> assert each at type boolean.
---@type boolean
local is_uuid = checkers.uuid(uuid.new())
---@type boolean
local is_int64 = checkers.int64(42)
---@type boolean
local is_decimal = checkers.decimal(require('decimal').new('1.5'))
---@type boolean
local is_positive = checkers.positive(7)
assert(is_uuid and is_int64 and is_decimal and is_positive)

--------------------------------------------------------------------------------
-- tap: each assertion returns a boolean -> capture, combine, and report
--------------------------------------------------------------------------------

local test = tap.test('sample-suite')
test:plan(7)

---@type boolean
local r_ok = test:ok(1 + 1 == 2, 'addition')
---@type boolean
local r_is = test:is(2 * 2, 4, 'multiplication')
---@type boolean
local r_isnt = test:isnt(1, 2, 'inequality')
---@type boolean
local r_deep = test:is_deeply({ 1, 2, { 3 } }, { 1, 2, { 3 } }, 'deep equality')
---@type boolean
local r_like = test:like('hello world', 'wor', 'substring matches')
---@type boolean
local r_unlike = test:unlike('hello world', 'xyz', 'substring absent')
---@type boolean
local r_str = test:isstring('a string', 'is a string')

-- Combine the booleans (each must be boolean for this to type-check cleanly).
local all_passed = r_ok and r_is and r_isnt and r_deep and r_like and r_unlike and r_str
test:diag('all individual assertions passed: ' .. tostring(all_passed))

---@type boolean
local suite_ok = test:check()
print(all_passed, suite_ok)

-- A subtest receives a typed taptest argument; its assertions are booleans too.
test:test('subtest', function(t)
    t:plan(2)
    ---@type boolean
    local s1 = t:ok(true, 'always true')
    ---@type boolean
    local s2 = t:isnumber(42, 'is a number')
    print(s1 and s2)
end)
