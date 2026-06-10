-- Generics: luafun iterators are parameterized by their element types.
-- Chaining higher-order operations should preserve/transform those types.

local fun = require('fun')

-- range -> map -> filter -> reduce (all numeric).
local total = fun.range(1, 10)
    :map(function(x) return x * 2 end)
    :filter(function(x) return x % 3 == 0 end)
    :reduce(function(acc, x) return acc + x end, 0)
---@type number
local _total = total

-- iter over an array, transform, materialize.
local doubled = fun.iter({ 1, 2, 3 })
    :map(function(x) return x * 2 end)
    :totable()
---@type table
local _doubled = doubled

-- take / each.
fun.range(100):take(5):each(function(x) print(x) end)

-- enumerate in a generic-for loop.
for i, v in fun.iter({ 'a', 'b', 'c' }):enumerate() do
    print(i, v)
end

-- zip two sequences and materialize.
local zipped = fun.zip({ 1, 2, 3 }, { 'a', 'b', 'c' }):totable()
print(zipped)

-- reductions over a range.
---@type number
local _sum = fun.range(5):sum()
---@type number
local _len = fun.range(5):length()

-- key/value iteration over a map.
fun.iter({ x = 1, y = 2 }):each(function(k, v) print(k, v) end)
