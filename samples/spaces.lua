-- Generics: typed `box.space` usage. Self-contained and runnable under Tarantool.
--
-- A space is parameterized by two type arguments:
--   * T -- the positional tuple layout (an array-like type), and
--   * U -- the record (named-field) view of the same tuple.
-- The documented pattern is to annotate the space variable with
-- `box.space<T, U>` and let the data-manipulation methods propagate the types.

box.cfg({})

box.schema.space.create('bands', {
    if_not_exists = true,
    format = {
        { name = 'id',   type = 'unsigned' },
        { name = 'name', type = 'string' },
        { name = 'year', type = 'unsigned' },
    },
})
box.space.bands:create_index('primary', { parts = { 'id' }, if_not_exists = true })

---Positional tuple layout of the `bands` space.
---@alias band_tuple [integer, string, integer]

---Record (named-field) view of a `bands` tuple.
---@class band: table
---@field id integer
---@field name string
---@field year integer

-- Annotate a space with its tuple and record types (the README pattern).
---@type box.space<band_tuple, band>
local bands = box.space.bands

-- insert / replace accept a tuple and return the stored tuple.
local _inserted = bands:insert({ 1, 'Roxette', 1986 })
local _replaced = bands:replace({ 1, 'Pink Floyd', 1965 })

-- get returns one tuple or nil.
local _one = bands:get({ 1 })

-- select returns a list of tuples.
local rows = bands:select({}, { limit = 10, iterator = 'GE' })

-- Iterate the list; each element is a tuple, indexable positionally.
for _, t in ipairs(rows) do
    local _id = t[1]
    local _name = t[2]
    print(_id, _name)
end

-- Index access: `space.index.<name>` is a typed index over the same types.
local pk = bands.index.primary
local _viaIdx = pk:select({ 1 })
local _minTuple = pk:min()
local _count = pk:count()

-- update / upsert / delete.
bands:update({ 1 }, { { '=', 3, 1987 } })
bands:upsert({ 2, 'Scorpions', 1965 }, { { '=', 3, 1966 } })
local _deleted = bands:delete({ 2 })

-- pairs iteration over the space.
for _, t in bands:pairs() do
    print(t[1])
end

-- Space metadata fields.
---@type integer
local _sid = bands.id
---@type string
local _sname = bands.name
