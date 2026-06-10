-- Theme: complex tuples, multi-part / JSON-path indexes, iterators, and the
-- box.space<T, U> / box.tuple<T, U> / box.index<T, U> generics.
-- Runnable end-to-end.
--
-- NOTE: raw Lua tables passed to the typed tuple methods and the `iterator`
-- select option carry the documented generic / box.iterator warnings
-- (documented generic limitations); ignored here.

box.cfg({})

--------------------------------------------------------------------------------
-- A rich tuple: scalar fields plus an array field and a map field.
--------------------------------------------------------------------------------

---Positional layout: id, name, price, tags[], meta{}.
---@alias product_tuple [integer, string, number, string[], { currency: string, in_stock: boolean }]

---Named-field (record) view of a product tuple.
---@class product: table
---@field id integer
---@field name string
---@field price number
---@field tags string[]
---@field meta { currency: string, in_stock: boolean }

box.schema.space.create('products', {
    if_not_exists = true,
    format = {
        { name = 'id',    type = 'unsigned' },
        { name = 'name',  type = 'string' },
        { name = 'price', type = 'number' },
        { name = 'tags',  type = 'array' },
        { name = 'meta',  type = 'map' },
    },
})

---@type box.space<product_tuple, product>
local products = box.space.products

-- Primary, multi-part secondary, and a JSON-path index into the map field.
products:create_index('primary', { parts = { 'id' }, if_not_exists = true })
products:create_index('by_name_price', {
    parts = {
        { field = 'name',  type = 'string' },
        { field = 'price', type = 'number' },
    },
    unique = false,
    if_not_exists = true,
})
products:create_index('by_currency', {
    parts = { { field = 'meta', type = 'string', path = 'currency' } },
    unique = false,
    if_not_exists = true,
})
products:truncate()

--------------------------------------------------------------------------------
-- Insert complex tuples; access fields positionally and as a record.
--------------------------------------------------------------------------------

local p1 = products:insert({ 1, 'Widget', 9.99, { 'tools', 'new' }, { currency = 'USD', in_stock = true } })
products:insert({ 2, 'Gadget', 19.50, { 'tools' }, { currency = 'EUR', in_stock = false } })
products:insert({ 3, 'Gizmo', 4.25, { 'toys', 'new', 'sale' }, { currency = 'USD', in_stock = true } })

-- Positional field access on a typed tuple.
local _id = p1[1]
local _name = p1[2]
local _tags = p1[4]
print(_id, _name, _tags)

-- Record view via tomap, and a plain array via totable.
local _as_map = p1:tomap({ names_only = false })
local _as_arr = p1:totable()
local _nbytes = p1:bsize()
print(_as_map, _as_arr, _nbytes)

-- find / findall search within a tuple.
local _pos = p1:find('Widget')
local _all = p1:findall('new')
print(_pos, _all)

--------------------------------------------------------------------------------
-- Tuple update (operation lists) and transform.
--------------------------------------------------------------------------------

-- Apply several operations at once: rename, bump price, set a nested map field.
local _updated = p1:update({
    { '=', 2, 'Widget Pro' },
    { '+', 3, 0.01 },
    { '=', 'meta.in_stock', false },
})
print(_updated)

-- transform: replace one field at position 2 with two new fields.
local _transformed = box.tuple.new({ 1, 'x', 3 }):transform(2, 1, 'y', 'z')
print(_transformed)

--------------------------------------------------------------------------------
-- Space-level update / upsert with operation lists.
--------------------------------------------------------------------------------

products:update({ 1 }, { { '+', 3, 1.0 }, { '=', 2, 'Widget Mk II' } })
products:upsert(
    { 4, 'Doohickey', 2.00, { 'misc' }, { currency = 'GBP', in_stock = true } },
    { { '+', 3, 0.5 } }
)

--------------------------------------------------------------------------------
-- Index queries: every iterator direction, composite keys, limit/offset.
--------------------------------------------------------------------------------

local pk = products.index.primary
local by_np = products.index.by_name_price
local by_cur = products.index.by_currency

-- Exact and ranged lookups.
local _exact = pk:get({ 1 })
local _ge = pk:select({ 2 }, { iterator = 'GE', limit = 10 })
local _gt = pk:select({ 1 }, { iterator = 'GT' })
local _le = pk:select({ 3 }, { iterator = 'LE', limit = 2 })
local _lt = pk:select({ 3 }, { iterator = 'LT' })
local _req = pk:select({}, { iterator = 'REQ', limit = 5 })
local _all = pk:select({}, { iterator = 'ALL', offset = 1 })
print(_exact, #_ge, #_gt, #_le, #_lt, #_req, #_all)

-- Composite-key lookup on the multi-part index.
local _composite = by_np:select({ 'Gadget', 19.50 }, { iterator = 'EQ' })
-- Partial-key lookup (just the first part).
local _partial = by_np:select({ 'Gizmo' })
-- JSON-path index lookup.
local _usd = by_cur:select({ 'USD' })
print(#_composite, #_partial, #_usd)

-- Aggregates.
local _min = pk:min()
local _max = pk:max()
local _count_usd = by_cur:count({ 'USD' })
print(_min, _max, _count_usd)

-- Index-level update of one tuple via the primary key.
pk:update({ 2 }, { { '=', 'meta.in_stock', true } })

--------------------------------------------------------------------------------
-- Iterating an index and reading typed tuples.
--------------------------------------------------------------------------------

for _, tuple in pk:pairs() do
    -- tuple is a box.tuple; fields are accessed positionally.
    local id, name, price = tuple[1], tuple[2], tuple[3]
    print(id, name, price)
end
