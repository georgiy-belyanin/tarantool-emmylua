-- Theme: net.box -- remote work over a self-loopback connection.
-- Every result is captured with its concrete expected type AND used in a
-- type-demanding way (method call / iteration / field access), so a wrong
-- return annotation actually produces a diagnostic. net.box yields, so the
-- remote work runs in an `---@async` function inside a fiber; MVCC is enabled
-- so stream transactions survive yields.
--
-- NOTE: raw-table tuple args carry the documented generic warning; ignored.

local net = require('net.box')
local fiber = require('fiber')

box.cfg({ listen = 'unix/:./netbox.sock', memtx_use_mvcc_engine = true })
box.schema.user.grant('guest', 'read,write,execute', 'universe', nil, { if_not_exists = true })

box.schema.space.create('remote_t', {
    if_not_exists = true,
    format = {
        { name = 'id', type = 'unsigned' },
        { name = 'v',  type = 'string' },
    },
})
box.space.remote_t:create_index('pk', { parts = { 'id' }, if_not_exists = true })
box.space.remote_t:truncate()
box.schema.func.create('answer', { body = 'function(a, b) return a + b end', if_not_exists = true })

---@async
local function main()
    -- connect() returns a typed connection; pass a composite options table.
    ---@type net.box.conn
    local conn = net.connect('unix/:./netbox.sock', {
        wait_connected = true,
        reconnect_after = 1,
        fetch_schema = true,
    })

    -- Boolean-returning state methods (each assertion fires if the return type
    -- is not boolean).
    ---@type boolean
    local reached = conn:wait_connected(5)
    ---@type boolean
    local connected = conn:is_connected()
    ---@type boolean
    local active = conn:wait_state('active', 1)
    assert(reached and connected and active)

    -- conn.state is a string union -> exercise it with a string method.
    ---@type string
    local upper_state = conn.state:upper()
    ---@type string
    local host = conn.host
    print(upper_state, host)

    -- ping -> boolean (used in a condition).
    ---@type boolean
    local pinged = conn:ping({ timeout = 1 })
    if pinged then print('pong') end

    -- eval -> table; consume it as a table (iteration + indexing).
    ---@type table
    local evaled = conn:eval('return { sum = 2 + 2, items = { 10, 20 } }')
    local eval_keys = 0
    for _ in pairs(evaled) do eval_keys = eval_keys + 1 end
    print('eval keys', eval_keys)

    -- call -> table; index the result.
    ---@type table
    local called = conn:call('answer', { 40, 2 })
    print('answer', called[1])

    -- Async request: returns a future with its own typed API.
    local future = conn:eval('return 7', {}, { is_async = true }) --[[@as net.box.future]]
    ---@type boolean
    local ready = future:is_ready()
    ---@type table?
    local future_result = future:wait_result(1)
    print(ready, future_result)

    -- watch -> box.watcher, whose only method is unregister().
    local watcher = conn:watch('sample_key', function(key, value) print('watch', key, value) end)
    watcher:unregister()

    -- Remote spaces: box.tuple methods on the returned tuples.
    conn.space.remote_t:insert({ 1, 'hello' })
    conn.space.remote_t:replace({ 1, 'world' })
    local got = conn.space.remote_t:get({ 1 })
    if got ~= nil then
        ---@type number
        local nbytes = got:bsize()
        ---@type table
        local as_table = got:totable()
        print('tuple', nbytes, as_table)
    end
    local rows = conn.space.remote_t:select({}, { limit = 10 })
    for _, tuple in ipairs(rows) do
        print(tuple[1], tuple[2])
    end

    -- Streams: a typed stream gives transactional remote spaces.
    ---@type net.box.stream
    local stream = conn:new_stream()
    stream:begin()
    stream.space.remote_t:insert({ 2, 'in-stream' })
    stream:commit()

    ---@type net.box.stream
    local stream2 = conn:new_stream()
    stream2:begin()
    stream2.space.remote_t:insert({ 3, 'rolled-back' })
    stream2:rollback()

    -- A disconnect trigger that reads the typed connection back.
    conn:on_disconnect(function(c) print('disconnected from', c.state) end)
    conn:close()
end

fiber.create(main)
fiber.sleep(1)

-- The loopback connection to the current instance.
---@type net.box.conn
local self_conn = net.self
print(self_conn.state)
