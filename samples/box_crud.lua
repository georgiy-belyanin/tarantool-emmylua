-- Theme: the core database API -- schema definition, CRUD, indexes, sequences,
-- access control, and transactions. Runnable end-to-end.
--
-- NOTE: passing raw Lua tables to typed `box.space`/`box.index` tuple methods
-- (`insert`/`replace`/`update`/`upsert`) currently trips the analyzer's
-- generic-class check (a documented generic limitation). Those warnings are expected
-- and ignored here; the sample's purpose is to validate the API at runtime.

box.cfg({})

--------------------------------------------------------------------------------
-- Schema: spaces, formats, indexes, sequences
--------------------------------------------------------------------------------

box.schema.sequence.create('author_id', { min = 1, if_not_exists = true })

local authors = box.schema.space.create('authors', {
    if_not_exists = true,
    engine = 'memtx',
    format = {
        { name = 'id',    type = 'unsigned' },
        { name = 'name',  type = 'string' },
        { name = 'books', type = 'unsigned' },
    },
})

authors:create_index('primary', {
    type = 'tree',
    parts = { 'id' },
    sequence = 'author_id',
    if_not_exists = true,
})
authors:create_index('by_name', {
    type = 'tree',
    parts = { { field = 'name', type = 'string' } },
    unique = false,
    if_not_exists = true,
})

-- Reset to a known state so the sample is idempotent across runs.
authors:truncate()

--------------------------------------------------------------------------------
-- CRUD
--------------------------------------------------------------------------------

-- insert / replace return the stored tuple.
local mark = authors:insert({ 1, 'Mark Twain', 12 })
authors:replace({ 1, 'Mark Twain', 30 })

-- get by primary key.
local got = authors:get({ 1 })
print(mark, got)

-- Bulk insert for the queries below.
authors:insert({ 2, 'Jane Austen', 6 })
authors:insert({ 3, 'Leo Tolstoy', 9 })

-- select with options.
local first_two = authors:select({}, { limit = 2, iterator = 'GE' })
---@type number
local _total = authors:count()
---@type number
local _len = authors:len()
---@type number
local _bsize = authors:bsize()
print(first_two, _total, _len, _bsize)

-- update: increment the book count of author 1.
authors:update({ 1 }, { { '+', 3, 1 } })

-- upsert: insert if missing, otherwise apply the operations.
authors:upsert({ 4, 'Franz Kafka', 3 }, { { '=', 3, 4 } })

-- delete by key.
local deleted = authors:delete({ 4 })
print(deleted)

--------------------------------------------------------------------------------
-- Index operations
--------------------------------------------------------------------------------

local pk = authors.index.primary
local by_name = authors.index.by_name

local _min = pk:min()
local _max = pk:max()
local _by_name_count = by_name:count()
local _random = pk:random(42)
local _name_hits = by_name:select({ 'Jane Austen' })
print(_min, _max, _by_name_count, _random, _name_hits)

-- Iterate an index.
for _, tuple in pk:pairs() do
    print(tuple[1], tuple[2])
end

--------------------------------------------------------------------------------
-- Transactions
--------------------------------------------------------------------------------

box.begin()
authors:insert({ 5, 'George Orwell', 7 })
authors:replace({ 5, 'George Orwell', 8 })
box.commit()

-- atomic() wraps a function in an implicit begin/commit (rollback on error).
box.atomic(function()
    authors:update({ 5 }, { { '+', 3, 1 } })
end)

--------------------------------------------------------------------------------
-- Access control: users, roles, functions
--------------------------------------------------------------------------------

box.schema.user.create('librarian', { password = 'shelf', if_not_exists = true })
box.schema.user.grant('librarian', 'read,write', 'space', 'authors', { if_not_exists = true })
---@type boolean
local _user_exists = box.schema.user.exists('librarian')
local _user_info = box.schema.user.info('librarian')

box.schema.role.create('readers', { if_not_exists = true })
box.schema.role.grant('readers', 'read', 'space', 'authors', { if_not_exists = true })
box.schema.user.grant('librarian', 'readers', nil, nil, { if_not_exists = true })

box.schema.func.create('noop', { if_not_exists = true })
---@type boolean
local _func_exists = box.schema.func.exists('noop')
print(_user_exists, _user_info, _func_exists)

-- Cleanup the access-control objects (keep the run repeatable).
box.schema.func.drop('noop', { if_exists = true })
box.schema.user.drop('librarian', { if_exists = true })
box.schema.role.drop('readers', { if_exists = true })
