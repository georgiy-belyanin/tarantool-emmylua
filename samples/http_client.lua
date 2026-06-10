-- validate: skip -- needs an external HTTP server; type-checked only.
--
-- Theme: the http.client module. Every response field is captured at its
-- concrete type (status:integer, reason:string, headers:table, body:string?)
-- and used, so a wrong response annotation produces a diagnostic. The request
-- methods are `@async` (they yield), so they run inside an `@async` function.

local http = require('http.client')
local fiber = require('fiber')

-- A client with composite options.
local client = http.new({ max_connections = 5, max_total_connections = 10 })

---@async
local function http_demo()
    ----------------------------------------------------------------------------
    -- GET: a typed response with concrete fields
    ----------------------------------------------------------------------------

    local resp = client:get('http://localhost:8080/health', {
        timeout = 1,
        headers = { ['accept'] = 'application/json' },
    })
    ---@type integer
    local status = resp.status
    ---@type string
    local reason = resp.reason
    ---@type table<string, any>
    local headers = resp.headers
    ---@type string?
    local body = resp.body
    print(status, reason, headers['content-type'], body)

    ----------------------------------------------------------------------------
    -- POST / PUT / DELETE / generic request -- all return http.response
    ----------------------------------------------------------------------------

    local created = client:post('http://localhost:8080/items', '{"name":"widget"}', {
        headers = { ['content-type'] = 'application/json' },
    })
    ---@type integer
    local created_status = created.status

    local updated = client:put('http://localhost:8080/items/1', 'payload', {})
    local removed = client:delete('http://localhost:8080/items/1', {})
    local patched = client:request('PATCH', 'http://localhost:8080/items/1', 'delta', { timeout = 2 })
    ---@type integer
    local patched_status = patched.status
    print(created_status, updated.status, removed.status, patched_status)

    ----------------------------------------------------------------------------
    -- Module-level shortcuts (options optional here)
    ----------------------------------------------------------------------------

    local quick = http.get('http://localhost:8080/')
    ---@type integer
    local quick_status = quick.status
    ---@type number
    local quick_proto = quick.proto
    print(quick_status, quick_proto)
end

-- Connection statistics are synchronous; read a couple of typed counters.
local stat = client:stat()
---@type number
local active = stat.active_requests
---@type number
local total = stat.total_requests
print(active, total)

fiber.create(http_demo)
fiber.sleep(0.1)
