---@meta

---# Builtin `net.box` module.
---
---The `net.box` module contains connectors to remote database systems. One variant is for connecting to MySQL or MariaDB or PostgreSQL (see [SQL DBMS modules](doc://dbms_modules) reference).
---
---The other variant, which is discussed in this section, is for connecting to Tarantool server instances via a network.
local net_box = {}

---@class net.box.conn
---@field public host string
---@field public port string
---@field public state 'active' | 'fetch_schema' | 'error' | 'error_reconnect' | 'closed' | 'initial' | 'graceful_shutdown'
---@field public error string
---@field public peer_uuid? string
---@field public schema_version? integer
---@field public space box.spaces A collection of remote spaces. Each remote space is accessed by name, e.g. `conn.space.<space-name>`, and supports the data-manipulation methods (`select`/`get`/`insert`/`replace`/`update`/`upsert`/`delete`).
---@field public _fiber? Fiber
local conn = {}

---@class net.box.request_options
---@field public is_async? boolean
---@field public timeout? number

---@class net.box.call_options
---@field timeout number? Timeout of Call
---@field is_async boolean? makes request asynchronous
---@field return_raw boolean? returns raw msgpack (since version 2.10.0)
---@field on_push fun(ctx: any?, msg: any)? callback for each inbound message
---@field on_push_ctx any? ctx for on_push callback

---Execute a remote call.
---
---`conn:call('func', {'1', '2', '3'})` is the remote-call equivalent of `func('1', '2', '3')`. That is, `conn:call` is a remote stored-procedure call. The return from `conn:call` is whatever the function returns.
---
---Limitation: the called function cannot return a function, for example if `func2` is defined as `function func2 () return func end` then `conn:call(func2)` will return "error: unsupported Lua type 'function'".
---
---**Examples:**
---
--- ```lua
--- tarantool> -- create 2 functions with conn:eval()
--- tarantool> conn:eval('function f1() return 5+5 end;')
--- tarantool> conn:eval('function f2(x,y) return x,y end;')
--- tarantool> -- call first function with no parameters and no options
--- tarantool> conn:call('f1')
--- ---
--- - 10
--- ...
--- tarantool> -- call second function with two parameters and one option
--- tarantool> conn:call('f2',{1,'B'},{timeout=99})
--- ---
--- - 1
--- - B
--- ...
--- ```
---
---@async
---@param func string
---@param args? any[]
---@param opts? net.box.call_options
---@return table
function conn:call(func, args, opts) end

---Execute Lua code remotely.
---
---`conn:eval({Lua-string})` evaluates and executes the expression in Lua-string, which may be any statement or series of statements.
---An [execute privilege](doc://authentication-owners_privileges) is required; if the user does not have it, an administrator may grant it with `box.schema.user.grant({username}, 'execute', 'universe')`.
---
---To ensure hat the return from `conn:eval` is whatever the Lua expression returns, begin the Lua-string with the word "return".
---
---**Examples:**
---
--- ```lua
--- tarantool> --Lua-string
--- tarantool> conn:eval('function f5() return 5+5 end; return f5();')
--- ---
--- - 10
--- ...
--- tarantool> --Lua-string, {arguments}
--- tarantool> conn:eval('return ...', {1,2,{3,'x'}})
--- ---
--- - 1
--- - 2
--- - [3, 'x']
--- ...
--- tarantool> --Lua-string, {arguments}, {options}
--- tarantool> conn:eval('return {nil,5}', {}, {timeout=0.1})
--- ---
--- - [null, 5]
--- ...
--- ```
---
---@async
---@param expression string
---@param args any[]?
---@param opts net.box.call_options?
---@return table
function conn:eval(expression, args, opts) end

---Execute a PING command.
---
---@async
---@param opts? { timeout: number }
---@return boolean
function conn:ping(opts) end

---Define a trigger for execution when a new connection is established, and authentication and schema fetch are completed due to an event such as `net_box.connect`.
---
---If a trigger function issues `net_box` requests, they must be [asynchronous](net.box.is_async) (`{is_async = true}`). An attempt to wait for request completion with `future:pairs()` or `future:wait_result()` in the trigger function will result in an error.
---
---If the trigger execution fails and an exception happens, the connection's state changes to 'error'. In this case, the connection is terminated, regardless of the `reconnect_after` option's value. Can be called as many times as reconnection happens, if `reconnect_after` is greater than zero.
---
---@param new_callback fun(conn: net.box.conn)
---@param old_callback? fun(conn: net.box.conn)
function conn:on_connect(new_callback, old_callback) end

---Define a trigger for execution after a connection is closed.
---
---If the trigger function causes an error, the error is logged but otherwise is ignored.
---
---Execution stops after a connection is explicitly closed, or once the Lua garbage collector removes it.
---
---@param new_callback fun(conn: net.box.conn)
---@param old_callback? fun(conn: net.box.conn)
function conn:on_disconnect(new_callback, old_callback) end

---Define a trigger for shutdown when a [box.shutdown](doc://system-events_box-shutdown) event is received.
---
---The trigger starts in a new fiber. While the `on_shutdown()` trigger is running, the connection stays active. It means that the trigger callback is allowed to send new requests.
---
---After the trigger return, the `net.box` connection goes to the `graceful_shutdown` state (check [the state diagram](doc://net_box-state_diagram) for details). In this state, no new requests are allowed. The connection waits for all pending requests to be completed.
---
---Once all in-progress requests have been processed, the connection is closed. The state changes to `error` or `error_reconnect` (if the `reconnect_after` option is defined).
---
---Servers that do not support the `box.shutdown` event or [IPROTO_WATCH](doc://box_protocol-watch) just close the connection abruptly. In this case, the `on_shutdown()` trigger is not executed.
---
---@param new_callback? fun(conn: net.box.conn) the trigger function. Takes the `conn` object as the first argument.
---@param old_callback? fun(conn: net.box.conn) an existing trigger function to replace with `trigger-function`
---@return fun(conn: net.box.conn) | nil
function conn:on_shutdown(new_callback, old_callback) end

---Define a trigger executed when some operation has been performed on the remote server after schema has been updated. So, if a server request fails due to a schema version mismatch error, schema reload is triggered.
---
---If a trigger function issues `net_box` requests, they must be [asynchronous](lua://net.box.future) (`{is_async = true}`). An attempt to wait for request completion with `future:pairs()` or `future:wait_result()` in the trigger function will result in an error.
---
---**Note:**
---
---If the parameters are `(nil, old-trigger-function)`, then the old trigger is deleted.
---
---If both parameters are omitted, then the response is a list of existing trigger functions.
---
---Find the detailed information about triggers in the [triggers](doc://triggers-box_triggers) section.
---
---@param new_callback? fun(conn: net.box.conn) the trigger function. Takes the `conn` object as the first argument.
---@param old_callback? fun(conn: net.box.conn) an existing trigger function to replace with `trigger-function`
---@return fun(conn: net.box.conn) | nil
function conn:on_schema_reload(new_callback, old_callback) end

---Wait for connection to be active or closed.
---
---**Example:**
---
--- ```lua
--- net_box.self:wait_connected()
--- ```
---
---@async
---@param wait_timeout number
---@return boolean is_connected true when connected, false on failure.
function conn:wait_connected(wait_timeout) end

---Close a connection.
---
---Connection objects are destroyed by the Lua garbage collector, just like any other objects in Lua, so an explicit destruction is not mandatory. However, since `close()` is a system call, it is good programming practice to close a connection explicitly when it is no longer needed, to avoid lengthy stalls of the garbage collector.
---
---**Example:**
---
--- ```lua
--- conn:close()
--- ```
---
function conn:close() end

---Show whether connection is active or closed.
---
---@return boolean
function conn:is_connected() end

---Wait for a target state.
---
---*Since 1.7.2*
---
---`states` is a target state name or a set of target state names.
---
---**Examples:**
---
--- ```lua
--- -- wait infinitely for 'active' state:
--- conn:wait_state('active')
---
--- -- wait for 1.5 secs at most:
--- conn:wait_state('active', 1.5)
---
--- -- wait infinitely for either `active` or `fetch_schema` state:
--- conn:wait_state({active=true, fetch_schema=true})
--- ```
---
---@async
---@param states string | table<string, boolean> target states
---@param timeout? number in seconds
---@return boolean reached true when a target state is reached, false on timeout or connection closure
function conn:wait_state(states, timeout) end

---Subscribe to events broadcast by a remote host.
---
---To read more about watchers, see the [Functions for watchers](doc://box-watchers) section.
---
---The method has the same syntax as the [box.watch()](lua://box.watch) function, which is used for subscribing to events locally.
---
---Watchers survive reconnection (see the `reconnect_after` connection [option](lua://net.box.connect)). All registered watchers are automatically resubscribed when the connection is reestablished.
---
---If a remote host supports watchers, the `watchers` key will be set in the connection `peer_protocol_features`. For details, check the [net.box features table](lua://net.box.connect).
---
---**Note:**
---
---Keep in mind that garbage collection of a watcher handle doesn't lead to the watcher's destruction. In this case, the watcher remains registered. It is okay to discard the result of `watch` function if the watcher will never be unregistered.
---
---**Example 1:**
---
---Server:
---
--- ```lua
--- -- Broadcast value 42 for the 'foo' key.
--- box.broadcast('foo', 42)
--- ```
---
---Client:
---
--- ```lua
--- conn = net.box.connect(URI)
--- local log = require('log')
--- -- Subscribe to updates of the 'foo' key.
--- w = conn:watch('foo', function(key, value)
---     assert(key == 'foo')
---     log.info("The box.id value is '%d'", value)
--- end)
--- ```
---
---If you don't need the watcher anymore, you can unregister it using the command below:
---
--- ```lua
--- w:unregister()
--- ```
---
---@param key string a key name of an event to subscribe to
---@param func fun(key: string, value: any) a callback to invoke when the key value is updated
---@return box.watcher watcher a watcher handle. The handle consists of one method -- `unregister()`, which unregisters the watcher.
function conn:watch(key, func) end

---Create a stream.
---
---**Example:**
---
--- ```lua
--- -- Start a server to create a new stream
--- local conn = net_box.connect('localhost:3301')
--- local conn_space = conn.space.test
--- local stream = conn:new_stream()
--- local stream_space = stream.space.test
--- ```
---
---@return net.box.stream
function conn:new_stream() end

---A stream object provides transactional access to a remote Tarantool instance over a `net.box` connection. Like a connection, it exposes a `space` collection (`stream.space.<space-name>`) and the data-manipulation methods, but all requests sent over a single stream are processed sequentially and can be wrapped into an interactive transaction with [`begin()`](lua://net.box.stream.begin)/[`commit()`](lua://net.box.stream.commit)/[`rollback()`](lua://net.box.stream.rollback).
---
---@class net.box.stream
---@field public space box.spaces A collection of remote spaces accessible over the stream. Each remote space is accessed by name, e.g. `stream.space.<space-name>`.
local stream = {}

---Begin a stream transaction. Instead of the direct method, you can also use the `call`, `eval` or execute methods with SQL transaction.
---
---@async
---@param txn_isolation? box.txn_isolation [transaction isolation level](doc://txn_mode_mvcc-options)
function stream:begin(txn_isolation) end

---Commit a stream transaction. Instead of the direct method, you can also use the `call`, `eval` or execute methods with SQL transaction.
---
---**Examples:**
---
--- ```lua
--- -- Begin stream transaction
--- stream:begin()
--- -- In the previously created ``accounts`` space with the primary key ``test``, modify the fields 2 and 3
--- stream.space.accounts:update(test_1, {{'-', 2, 370}, {'+', 3, 100}})
--- -- Commit stream transaction
--- stream:commit()
--- ```
---
---@async
function stream:commit() end

---Rollback a stream transaction. Instead of the direct method, you can also use the `call`, `eval` or execute methods with SQL transaction.
---
---**Example:**
---
--- ```lua
--- -- Test rollback for memtx space
--- space:replace({1})
--- -- Select return tuple that was previously inserted, because this select belongs to stream transaction
--- space:select({})
--- stream:rollback()
--- -- Select is empty, stream transaction rollback
--- space:select({})
--- ```
---
---@async
function stream:rollback() end

---An object returned by a `net.box` request made with the `{is_async = true}` option (applicable to all `net_box` requests including `conn:call`, `conn:eval`, and the `conn.space.space-name` requests).
---
---The default is `is_async=false`, meaning requests are synchronous for the fiber. The fiber is blocked, waiting until there is a reply to the request or until timeout expires. Before Tarantool version 1.10, the only way to make asynchronous requests was to put them in separate fibers.
---
---The non-default is `is_async=true`, meaning requests are asynchronous for the fiber. The request causes a yield but there is no waiting. The immediate return is not the result of the request, instead it is an object that the calling program can use later to get the result of the request.
---
---Typically a user would say `future=request-name(...{is_async=true})`, then either loop checking `future:is_ready()` until it is true and then say `request_result=future:result()`, or say `request_result=future:wait_result(...)`. Alternatively the client could check for "out-of-band" messages from the server by calling `pairs()` in a loop -- see [box.session.push](doc://box_session_push).
---
---A user would say `future:discard()` to make a connection forget about the response -- if a response for a discarded object is received then it will be ignored, so that the size of the requests table will be reduced and other requests will be faster.
---
---**Note:**
---
---Although the final result of an async request is the same as the result of a sync request, it is structured differently: as a table, instead of as the unpacked values.
---
---**Examples:**
---
--- ```tarantoolsession
--- -- Insert a tuple asynchronously --
--- tarantool> future = conn.space.bands:insert({10, 'Queen', 1970}, {is_async=true})
--- ---
--- ...
--- tarantool> future:is_ready()
--- ---
--- - true
--- ...
--- tarantool> future:result()
--- ---
--- - [10, 'Queen', 1970]
--- ...
---
--- -- Iterate through a space with 10 records to get data in chunks of 3 records --
--- tarantool> while true do
---                future = conn.space.bands:select({}, {limit=3, after=position, fetch_pos=true, is_async=true})
---                result = future:wait_result()
---                tuples = result[1]
---                position = result[2]
---                if position == nil then
---                    break
---                end
---                print('Chunk size: '..#tuples)
---            end
--- Chunk size: 3
--- Chunk size: 3
--- Chunk size: 3
--- Chunk size: 1
--- ---
--- ...
--- ```
---
---@class net.box.future
local future = {}

---Return `true` when the result of the request is available.
---
---@return boolean
function future:is_ready() end

---Get the result of the request (returns the response or `nil` in case it's not ready yet or there has been an error).
---
---@return table? result
---@return any? error
function future:result() end

---Wait until the result of the request is available and then get it, or throw an error if there is no result after the timeout exceeded.
---
---@async
---@param timeout? number
---@return table? result
---@return any? error
function future:wait_result(timeout) end

---Abandon the object.
---
---A user would say `future:discard()` to make a connection forget about the response -- if a response for a discarded object is received then it will be ignored, so that the size of the requests table will be reduced and other requests will be faster.
function future:discard() end

---Check for "out-of-band" messages from the server by calling `pairs()` in a loop.
---
---`pairs()` is subject to timeout. So there is an optional argument = timeout per iteration. If timeout occurs before there is a new message or a final response, there is an error return.
---
---To check for an error one can use the first loop parameter (if the loop starts with `for i, message in future:pairs()` then the first loop parameter is `i`). If it is `box.NULL` then the second parameter (in our example, `message`) is the error object.
---
---See [box.session.push](doc://box_session_push).
---
---@async
---@param timeout? number timeout per iteration
---@return fun(): integer, any iterator
function future:pairs(timeout) end

---@class net.box.connect_options
---@field public wait_connected? boolean|number
---@field public reconnect_after? number
---@field public user? string
---@field public password? string
---@field public connect_timeout? number

---Creates a new connection to Tarantool.
---
---The connection is established on demand, at the time of the first request.
---
---It can be re-established automatically after a disconnect (see `reconnect_after` option below).
---
---The returned `conn` object supports methods for making remote requests, such as `select`, `update` or `delete`.
---
---If `reconnect_after` is greater than zero, then `wait_connected` ignores transient failures.
---The wait completes once the connection is established or is closed explicitly.
---
---* `reconnect_after`: a number of seconds to wait before reconnecting.
---
---The default value, as with the other `connect` options, is `nil`. If `reconnect_after` is greater than zero, then a `net.box` instance will attempt to reconnect if a connection is lost or a connection attempt fails. This makes transient network failures transparent to the application.
---
---Reconnection happens automatically in the background, so requests that initially fail due to connection drops fail, are transparently retried. The number of retries is unlimited, connection retries are made after any specified interval (for example, `reconnect_after=5` means that reconnect attempts are made every 5 seconds).
---When a connection is explicitly closed or when the Lua garbage collector removes it, then reconnect attempts stop.
---
---* `connect_timeout`: a number of seconds to wait before returning "error: Connection timed out".
---* `fetch_schema`: a boolean option that controls fetching schema changes from the server. Default: `true`.
---If you don't operate with remote spaces, for example, run only `call` or `eval`, set `fetch_schema` to false` to avoid fetching schema changes which is not needed in this case.
---
---**Important:** In connections with `fetch_schema == false`, remote spaces are unavailable and the [`on_schema_reload`](lua://<net.box.on_schema_reload) triggers don't work.
---
---* `required_protocol_version`: a minimum version of the [IPROTO protocol](doc://box_protocol-id) supported by the server. If the version of the [IPROTO protocol](doc://box_protocol-id) supported by the server is lower than specified, the connection will fail with an error message.
---
---With `required_protocol_version = 1`, all connections fail where the [IPROTO protocol](doc://box_protocol-id) version is lower than `1`.
---
---* `required_protocol_features`: specified [IPROTO protocol features](doc://box_protocol-id) supported by the server.
---You can specify one or more `net.box` features from the table below. If the server does not support the specified features, the connection will fail with an error message.
---
---With `required_protocol_features = {'transactions'}`, all connections fail where the server has `transactions: false`.
---
---*  net.box feature
---   Use
---   IPROTO feature ID
---   IPROTO versions supporting the feature
---* `streams`
---   Requires streams support on the server
---   IPROTO_FEATURE_STREAMS
---   1 and newer
---* `transactions`
---   Requires transactions support on the server
---   IPROTO_FEATURE_TRANSACTIONS
---   1 and newer
---* `error_extension`
---   Requires support for [`MP_ERROR`](lua://msgpack.ext.error) MsgPack extension on the server
---   IPROTO_FEATURE_ERROR_EXTENSION
---   2 and newer
---* `watchers`
---   Requires remote [`watchers`](lua://net.boxwatch) support on the server
---   IPROTO_FEATURE_WATCHERS
---   3 and newer
---
---To learn more about IPROTO features, see [`IPROTO_ID`](box.protocol.id) and the [`IPROTO_FEATURES]`(doc://internals-iproto-keys-features) key.
---
---**Examples:**
---
--- ```lua
--- net_box = require('net.box')
--- 
--- conn = net_box.connect('localhost:3301')
--- conn = net_box.connect('127.0.0.1:3302', {wait_connected = false})
--- conn = net_box.connect('127.0.0.1:3304', {required_protocol_version = 4, required_protocol_features = {'transactions', 'streams'}, })
--- ```
---
---@async
---@param endpoint uri_like
---@param options? net.box.connect_options
---@return net.box.conn
function net_box.connect(endpoint, options) end

---Creates connection to Tarantool.
---
---`new()` is a synonym for `connect()`. It is retained for backward compatibility.
---
---For more information, see the description of [`net_box.connect()`](net.box.connect).
---
---@see net.box.connect
---
---@async
---@param endpoint string
---@param options? net.box.connect_options
---@return net.box.conn
function net_box.new(endpoint, options) end

---For a local Tarantool server, there is a pre-created always-established connection object named `net_box.self`. Its purpose is to make polymorphic use of the `net_box` API easier. Therefore `conn = net_box.connect('localhost:3301')` can be replaced by `conn = net_box.self`.
---
---However, there is an important difference between the embedded connection and a remote one:
---
---* With the embedded connection, requests which do not modify data do not yield. When using a remote connection, due to [the implicit rules](doc://app-implicit-yields) any request can yield, and the database state may have changed by the time it regains control.
---
---* All the options passed to a request (as `is_async`, `on_push`, `timeout`) will be ignored.
---
---@type net.box.conn
net_box.self = conn

return net_box
