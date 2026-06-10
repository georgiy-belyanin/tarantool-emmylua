-- Theme: tuple-key operations (key_def) and merging sorted tuple streams (merger).
-- Standalone-runnable (operates on box.tuple objects; no box.cfg).

local key_def = require('key_def')
local merger = require('merger')

--------------------------------------------------------------------------------
-- key_def: define a (possibly multi-part) key and operate on tuples
--------------------------------------------------------------------------------

-- A two-part key: field 1 (unsigned) then field 3 (string, nullable).
local kd = key_def.new({
    { fieldno = 1, type = 'unsigned' },
    { fieldno = 3, type = 'string', is_nullable = true },
})

local t1 = box.tuple.new({ 1, 'alpha', 'x' })
local t2 = box.tuple.new({ 2, 'beta', 'y' })
local t3 = box.tuple.new({ 1, 'gamma', 'z' })

-- Compare two tuples by the key.
---@type integer
local _cmp12 = kd:compare(t1, t2)
---@type integer
local _cmp13 = kd:compare(t1, t3)

-- Extract just the key fields as a tuple.
local _key = kd:extract_key(t1)

-- Compare a tuple against a bare key.
---@type integer
local _cwk = kd:compare_with_key(t1, { 1, 'x' })

-- Merge two key definitions into a wider one.
local kd_name = key_def.new({ { fieldno = 2, type = 'string' } })
local kd_merged = kd:merge(kd_name)
local _parts = kd_merged:totable()
print(_cmp12, _cmp13, _key, _cwk, _parts)

-- Validation helpers (since 3.1): raise on invalid input, return nothing on success.
kd:validate_tuple(t1)
kd:validate_key({ 1, 'x' })
local _full_ok = pcall(function() kd:validate_full_key({ 1 }) end)
print(_full_ok)

-- A primary-key-style single-part definition used below for merging.
local pk = key_def.new({ { fieldno = 1, type = 'unsigned' } })

--------------------------------------------------------------------------------
-- merger: combine several already-sorted tuple streams into one sorted stream
--------------------------------------------------------------------------------

-- Each source is a sorted run of tuples.
local function sorted_source(values)
    local tuples = {}
    for i, v in ipairs(values) do tuples[i] = box.tuple.new({ v }) end
    return merger.new_source_fromtable(tuples)
end

-- select() drains the sources and returns the merged, sorted result.
local merged = merger.new(pk, {
    sorted_source({ 1, 4, 7 }),
    sorted_source({ 2, 5, 8 }),
    sorted_source({ 3, 6, 9 }),
}):select()
---@type table
local _merged = merged
print(#merged, merged[1][1], merged[#merged][1])

-- pairs() iterates a fresh merger lazily.
local m2 = merger.new(pk, {
    sorted_source({ 10, 30 }),
    sorted_source({ 20, 40 }),
})
local collected = {}
for _, tuple in m2:pairs() do
    table.insert(collected, tuple[1])
end
print(#collected, collected[1], collected[#collected])
