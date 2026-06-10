-- Theme: process (popen) and network (socket) I/O. Both yield, so the work runs
-- in `---@async` functions inside fibers. Every result is captured at its
-- concrete type and used (status fields, byte counts, echoed payloads).
-- Standalone-runnable.

local popen = require('popen')
local socket = require('socket')
local fiber = require('fiber')

--------------------------------------------------------------------------------
-- popen: run a shell command, read its output, inspect status
--------------------------------------------------------------------------------

---@async
local function popen_demo()
    -- popen.shell returns a handle opened for reading.
    local sh = popen.shell('echo hello-from-popen', 'r')

    -- read -> string | nil (the second return is an error string).
    ---@type string?
    local output = sh:read({ timeout = 5 })

    -- info -> a typed handle_info record.
    ---@type popen.handle_info
    local info = sh:info()
    ---@type integer?
    local pid = info.pid
    ---@type string
    local command = info.command

    -- wait -> a typed process_status; use its union field and optional exit code.
    ---@type popen.process_status
    local status = sh:wait()
    ---@type 'alive' | 'exited' | 'signaled'
    local state = status.state
    local exited_ok = state == 'exited' and status.exit_code == 0

    sh:close()
    print(output, pid, command, state, exited_ok)
end

--------------------------------------------------------------------------------
-- socket: a TCP echo server on a loopback port, plus a client
--------------------------------------------------------------------------------

---@async
local function socket_demo()
    -- The connection handler runs in its own fiber, so it is itself async.
    ---@async
    ---@param client socket
    local function echo_handler(client)
        local request = client:read('\n', 3)
        if request ~= nil and request ~= '' then
            client:write('echo:' .. request)
        end
    end

    -- An echo server bound to an ephemeral loopback port.
    local server = socket.tcp_server('127.0.0.1', 0, echo_handler)
    assert(server ~= nil)

    -- name() -> a typed address record; read the chosen port.
    local addr = server:name()
    ---@type number
    local port = addr.port
    ---@type string
    local family = addr.family

    -- Connect a client and exchange a line.
    local conn = socket.tcp_connect('127.0.0.1', port, 3)
    assert(conn ~= nil)
    -- send -> number of bytes written.
    ---@type number
    local sent = conn:send('ping\n')
    -- read -> the echoed line (a string).
    ---@type string
    local reply = conn:read('\n', 3)

    conn:close()
    server:close()
    print(family, port, sent, reply)
end

-- Run both in fibers (the cooperative/async context) and let them finish.
fiber.create(popen_demo)
fiber.create(socket_demo)
fiber.sleep(1.5)
