-- Theme: complex COMPOSITE type annotations and GENERICS over tuple data.
-- The value is the static checking of nested/composite types (arrays of
-- records, maps, inline records, unions, optionals) and generic functions whose
-- type parameters flow from arguments to results. Standalone-runnable.

--------------------------------------------------------------------------------
-- Composite types: a nested record array, a string map, and a union field
--------------------------------------------------------------------------------

---A line item -- an inline record type.
---@alias order_item { sku: string, qty: integer, price: number }

---The positional tuple layout: id, customer, items[], labels{}, status-union.
---@alias order_tuple [integer, string, order_item[], table<string, string>, 'new' | 'paid' | 'shipped']

---The named-field (record) view, with composite field types.
---@class order: table
---@field id integer
---@field customer string
---@field items order_item[]
---@field labels table<string, string>
---@field status 'new' | 'paid' | 'shipped'

-- Building a value checks every composite field against its declared type.
---@type order
local o = {
    id = 1,
    customer = 'Acme',
    items = {
        { sku = 'A1', qty = 2, price = 9.99 },
        { sku = 'B2', qty = 1, price = 19.50 },
    },
    labels = { priority = 'high', region = 'eu' },
    status = 'paid',
}

-- Composite field access flows the nested types (assert narrows order_item? -> order_item).
local item1 = assert(o.items[1])
local item2 = assert(o.items[2])
---@type integer
local _qty1 = item1.qty
---@type number
local _price2 = item2.price
---@type string?
local _region = o.labels['region']
---@type 'new' | 'paid' | 'shipped'
local _status = o.status
print(_qty1, _price2, _region, _status)

-- A typed box.tuple holding the same composite layout.
---@type box.tuple<order_tuple, order>
local ot = box.tuple.new({ o.id, o.customer, o.items, o.labels, _status })
print(ot[1], ot[2])

--------------------------------------------------------------------------------
-- Generic functions: type parameters flow from arguments to the result
--------------------------------------------------------------------------------

---@generic T
---@param list T[]
---@param pred fun(item: T): boolean
---@return T[]
local function filter(list, pred)
    local out = {}
    for _, x in ipairs(list) do
        if pred(x) then out[#out + 1] = x end
    end
    return out
end

-- order_item[] in, order_item[] out -- field access on the result is typed.
local expensive = filter(o.items, function(item) return item.price > 10 end)
---@type integer
local _exp_qty = assert(expensive[1]).qty
print(_exp_qty)

---@generic T, R
---@param list T[]
---@param f fun(item: T, index: integer): R
---@return R[]
local function map(list, f)
    local out = {}
    for i, x in ipairs(list) do out[i] = f(x, i) end
    return out
end

-- order_item[] -> string[]
local skus = map(o.items, function(item) return item.sku end)
---@type string
local _sku1 = skus[1]
-- order_item[] -> { label: string, cost: number }[]
local lines = map(o.items, function(item)
    return { label = item.sku, cost = item.qty * item.price }
end)
---@type number
local _cost1 = assert(lines[1]).cost
print(_sku1, _cost1)

---@generic K, V
---@param list V[]
---@param key_of fun(value: V): K
---@return table<K, V[]>
local function group_by(list, key_of)
    ---@type table<K, V[]>
    local groups = {}
    for _, v in ipairs(list) do
        local k = key_of(v)
        groups[k] = groups[k] or {}
        table.insert(groups[k], v)
    end
    return groups
end

-- order_item[] -> table<string, order_item[]>
local by_sku = group_by(o.items, function(item) return item.sku end)
---@type order_item[]?
local _a1_items = by_sku['A1']
print(_a1_items)

---@generic T, A
---@param list T[]
---@param init A
---@param step fun(acc: A, item: T): A
---@return A
local function reduce(list, init, step)
    local acc = init
    for _, x in ipairs(list) do acc = step(acc, x) end
    return acc
end

-- Fold order_item[] into a number total (the accumulator type A flows from init).
---@type number
local zero = 0
local total = reduce(o.items, zero, function(acc, item) return acc + item.price * item.qty end)
print(total)

--------------------------------------------------------------------------------
-- Composite container types and union narrowing
--------------------------------------------------------------------------------

-- A map of records keyed by id, and an index of record-arrays by customer.
---@type table<integer, order>
local orders_by_id = { [o.id] = o }
---@type { [string]: order[] }
local orders_by_customer = { [o.customer] = { o } }
print(orders_by_id[1].customer, #orders_by_customer['Acme'])

-- Narrow the union status field with a guard.
---@param order order
---@return string
local function stage(order)
    local s = order.status
    if s == 'shipped' then
        return 'delivered'
    elseif s == 'paid' then
        return 'in-transit'
    end
    return 'awaiting-payment'
end
print(stage(o))

-- Cast a generic tuple's tomap() result to the concrete record type.
local as_order = ot:tomap({ names_only = false }) --[[@as order]]
---@type table<string, string>
local _cast_labels = as_order.labels
print(_cast_labels)
