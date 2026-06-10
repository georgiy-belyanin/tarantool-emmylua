---@meta

---# Builtin `popen` module
---
---*Since 2.4.1*
---
---The `popen` module allows Tarantool to execute external programs and interact with their standard input/output streams.
---
---It is conceptually similar to Python’s `subprocess` or Ruby’s `Open3`, but provides only core primitives: process creation, bidirectional communication via pipes, signal control, and resource management.
---
---Child processes are spawned using `vfork()`, which blocks the calling fiber until the child begins execution.
---
---For full usage patterns, refer to the [official documentation](https://www.tarantool.io/en/doc/latest/reference/reference_lua/popen/).
local popen = {}


---Execute a shell command and return a handle to interact with it.
---
---This is a convenience wrapper around `popen.new()` that:
---* runs the command via `sh -c "<command>"`,
---* enables session control (`setsid = true`),
---* enables group signaling (`group_signal = true`),
---* configures stdin/stdout/stderr based on the `mode` string.
---
---**Mode string interpretation**:
---* `'r'` → stdout is piped (enables `:read()`)
---* `'R'` → stderr is piped (enables `:read({stderr = true})`)
---* `'w'` → stdin is piped (enables `:write()`)
---* `'nil'` or empty → inherit all std streams from parent
---
---Multiple modes can be combined (e.g., `'rw'`, `'rRw'`).
---
---**Example**:
--- ```lua
--- local popen = require('popen')
--- local ph = popen.shell('date', 'r')
--- local output = ph:read():rstrip()
--- ph:close()
--- print(output) -- e.g., "Mon Nov 24 10:30:45 MSK 2025"
--- ```
---
---@param command string
---@param mode? 'r' | 'R' | 'w' | 'rw' | 'rR' | 'rRw' | 'wr' | 'wR' | nil
---@return popen.handle
function popen.shell(command, mode) end


---Create a new process with fine-grained control over execution environment.
---
---The `argv` table must contain the executable path as the first element, followed by arguments.
---If `opts.shell = true`, the command is executed as `sh -c "<joined argv>"`.
---
---**Important**: When `opts.shell` is `false` (default), the executable path must be absolute.
---
---**Environment**:
---* If `opts.env` is not set → inherit parent’s environment.
---* If `opts.env = {}` → start with empty environment.
---* If `opts.env = { KEY = "value", ... }` → use this as the full environment.
---
---**Key options**:
---* `stdin`, `stdout`, `stderr` — control file descriptor behavior (`popen.opts.PIPE`, `INHERIT`, etc.)
---* `setsid`, `group_signal` — enable process group management (recommended for subprocess trees)
---* `keep_child` — prevent automatic `SIGKILL` on `:close()`
---
---**Example 1**: Run `/bin/date` and capture output
--- ```lua
--- local ph = popen.new({'/bin/date'}, { stdout = popen.opts.PIPE })
--- print(ph:read():rstrip())
--- ph:close()
--- ```
---
---**Example 2**: Run shell command with custom environment
--- ```lua
--- local env = os.environ()
--- env.FOO = 'bar'
--- local ph = popen.new({'echo $FOO'}, {
---     shell = true,
---     stdout = popen.opts.PIPE,
---     env = env
--- })
--- print(ph:read():rstrip()) -- "bar"
--- ph:close()
--- ```
---
---@param argv string[]
---@param opts? popen.new_opts
---@return popen.handle
function popen.new(argv, opts) end

---@alias popen.fd_action
---| "inherit"   # inherit from parent (default)
---| "devnull"   # redirect to /dev/null
---| "close"     # close the file descriptor
---| "pipe"      # create a pipe for parent-child communication

---@class popen.new_opts
---@field stdin? popen.fd_action
---@field stdout? popen.fd_action
---@field stderr? popen.fd_action
---@field env? table<string, string>
---@field shell? boolean
---@field setsid? boolean
---@field close_fds? boolean
---@field restore_signals? boolean
---@field group_signal? boolean
---@field keep_child? boolean

---Opaque handle representing a child process and its communication channels.
---Obtained from `popen.shell()` or `popen.new()`.
---
---The handle provides methods to read/write data, send signals, inspect status, and release resources.
---@class popen.handle
local popen_handle = {}


---Read data from the child process’s stdout or stderr.
---
---By default, reads from stdout. Set `opts.stderr = true` to read from stderr.
---Cannot read from both streams simultaneously in one call.
---
---Returns an empty string (`""`) on EOF.
---
---**Example**:
--- ```lua
--- local ph = popen.new({'echo hello >&2'}, { stderr = popen.opts.PIPE, shell = true })
--- local err = ph:read({stderr = true}):rstrip()
--- ph:close()
--- print(err) -- "hello"
--- ```
---
---@param opts? { stdout?: boolean, stderr?: boolean, timeout?: number }
---@return string | nil, string
function popen_handle:read(opts) end


---Write a string to the child process’s stdin.
---
---Blocks until all data is written or `timeout` expires.
---
---**Warning**: May hang indefinitely if the child does not consume stdin and the pipe buffer fills.
---Use `:shutdown({stdin = true})` after writing to signal EOF.
---
---**Example**:
--- ```lua
--- local ph = popen.shell('tr a-z A-Z', 'rw')
--- ph:write('hello')
--- ph:shutdown({stdin = true})
--- print(ph:read():rstrip()) -- "HELLO"
--- ph:close()
--- ```
---
---@param str string
---@param opts? { timeout?: number }
---@return boolean | nil, string
function popen_handle:write(str, opts) end


---Close the parent’s end of one or more std streams.
---
---Useful to signal EOF on stdin (`{stdin = true}`) or to free unused output pipes.
---
---Only streams created with `popen.opts.PIPE` can be shut down.
---
---@param opts { stdin?: boolean, stdout?: boolean, stderr?: boolean }
---@return boolean
function popen_handle:shutdown(opts) end


---Send `SIGTERM` to the child process (or its process group if `group_signal` is enabled).
---
---@return boolean | nil, string
function popen_handle:terminate() end


---Send `SIGKILL` to the child process (or its process group).
---
---@return boolean | nil, string
function popen_handle:kill() end


---Send an arbitrary signal to the child process.
---
---Signal numbers can be obtained from `popen.signal` (e.g., `popen.signal.SIGUSR1`).
---
---If `opts.setsid` and `opts.group_signal` were set during creation, the signal is sent to the **process group**.
---
---@param signo integer
---@return boolean | nil, string
function popen_handle:signal(signo) end


---Retrieve detailed runtime information about the handle and child process.
---
---**Returns** a table with fields:
---* `pid` — process ID (or `nil` if exited)
---* `command` — reconstructed command line
---* `opts` — effective options (without `env`)
---* `status` — process status (`state`, `exit_code`, `signo`, etc.)
---* `stdin`/`stdout`/`stderr` — stream state (`'open'` or `'closed'`)
---
---**Example**:
--- ```tarantoolsession
--- tarantool> ph = require('popen').shell('sleep 10', 'r')
--- tarantool> yaml.encode(ph:info())
--- ---
--- - pid: 12345
---   command: sh -c 'sleep 10'
---   status: { state: alive }
---   stdout: open
---   opts: { stdout: pipe, stdin: inherit, ..., shell: true, setsid: true, group_signal: true }
--- ```
---
---@return popen.handle_info
function popen_handle:info() end


---Wait for the child process to exit or be signaled.
---
---Blocks until termination.
---
---Returns the `status` table (same format as in `:info().status`).
---
---@return popen.process_status
function popen_handle:wait() end


---Close the handle and release all associated resources.
---
---If `opts.keep_child` is `false` (default), sends `SIGKILL` to the child (or process group).
---
---Idempotent: safe to call multiple times.
---
---Always frees memory and file descriptors, even if signaling fails.
---
---@return boolean | nil, string
function popen_handle:close() end


---@class popen.process_status
---@field state "alive" | "exited" | "signaled"
---@field exit_code? integer        # present if state == "exited"
---@field signo? integer            # signal number, if state == "signaled"
---@field signame? string           # signal name, e.g., "SIGTERM"


---@class popen.handle_info
---@field pid integer | nil
---@field command string
---@field opts popen.new_opts
---@field status popen.process_status
---@field stdin? "open" | "closed"
---@field stdout? "open" | "closed"
---@field stderr? "open" | "closed"


---File descriptor action constants.
---
---@enum popen.opts
popen.opts = {
    INHERIT = "inherit",
    DEVNULL = "devnull",
    CLOSE = "close",
    PIPE = "pipe",
}


---Stream state constants.
---
---@enum popen.stream
popen.stream = {
    OPEN = "open",
    CLOSED = "closed",
}


---Process state constants.
---
---@enum popen.state
popen.state = {
    ALIVE = "alive",
    EXITED = "exited",
    SIGNALED = "signaled",
}


---Common signal numbers (platform-normalized).
---
---@enum popen.signal
popen.signal = {
    SIGTERM = 15,
    SIGKILL = 9,
    -- Additional signals may be present depending on platform
}

return popen
