---@meta

---# Builtin `box.session` submodule
---
---The `box.session` submodule allows querying the session state, writing to a session-specific temporary Lua table, or sending out-of-band messages, or setting up triggers which will fire when a session starts or ends.
---
---A *session* is an object associated with each client connection.
box.session = {}


---Return the unique identifier (ID) for the current session.
---
---The result can be 0 or -1 meaning there is no session.
---
---@return number
function box.session.id() end


---Check if session exists.
---
---@param id number
---@return boolean exists true if the session exists, false if the session does not exist.
function box.session.exists(id) end

---This function works only if there is a peer, that is, if a connection has been made to a separate Tarantool instance.
---
---Possible errors: 'session.peer(): session does not exist'
---
---@param id? number
---@return string | nil peer The host address and port of the session peer, for example “127.0.0.1:55457”.
function box.session.peer(id) end

---The value of the `sync` integer constant used in the [`binary protocol`](https://github.com/tarantool/tarantool/blob/2.1/src/box/iproto_constants.h).
---
---This value becomes invalid when the session is disconnected.
---
---This function is local for the request, i.e. not global for the session. If the connection behind the session is multiplexed, this function can be safely used inside the request processor.
---
---@return number
function box.session.sync() end

---Get the name of the current user.
---
---@return string user the name of current user
function box.session.user() end

---@alias box.session.type
---| "binary"     # if the connection was done via the binary protocol
---| "console"    # if the connection was done via the administrative console
---| "repl"       # if the connection was done directly
---| "applier"    # if the action is due to replication, regardless of how the connection was done
---| "background" # if the action is in a background fiber

---Get the type of connection or cause of action.
---
---@return box.session.type
function box.session.type() end

---Change Tarantool's current user.
---
---This is analogous to the Unix command `su`.
---
---Or, if function-to-execute is specified, change Tarantool's current user temporarily while executing the function -- this is analogous to the Unix command `sudo`.
---
---**Example:**
--- ```tarantoolsession
---
--- tarantool> function f(a) return box.session.user() .. a end
--- ---
--- ...
---
--- tarantool> box.session.su('guest', f, '-xxx')
--- ---
--- - guest-xxx
--- ...
---
--- tarantool> box.session.su('guest',function(...) return ... end,1,2)
--- ---
--- - 1
--- - 2
--- ...
--- ```
---
---@param user string name of a target user
---@param func? string name of a function, or definition of a function
---@return any? ... result of the function
function box.session.su(user, func) end

---Get the user ID of the current user.
---
---@return number uid the user ID of the current user.
function box.session.uid() end

---Get the effective user ID of the current user.
---
---This is the same as [`box.session.uid`](lua://box.session.uid), except in two cases:
---* The first case: if the call to `box.session.euid()` is within a function invoked by [`box.session.su`](lua://box.session.su) -- in that case, `box.session.euid()` returns the ID of the changed user. (the user who is specified by the `user-name` parameter of the `su` function)  but `box.session.uid()` returns the ID of the original user (the user who is calling the `su` function).
---* The second case: if the call to `box.session.euid()` is within a function specified with [`box.schema.func.create`](lua://box.schema.func.create) and the binary protocol is in use -- in that case, `box.session.euid()` returns the ID of the user who created "function-name" but `box.session.uid()` returns the ID of the the user who is calling "function-name".
---
---**Example:**
--- ```tarantoolsession
---
--- tarantool> box.session.su('admin')
--- ---
--- ...
--- tarantool> box.session.uid(), box.session.euid()
--- ---
--- - 1
--- - 1
--- ...
--- tarantool> function f() return {box.session.uid(),box.session.euid()} end
--- ---
--- ...
--- tarantool> box.session.su('guest', f)
--- ---
--- - - 1
--- - 0
--- ...
--- ```
---
---@return number euid the effective user ID of the current user.
function box.session.euid() end

---Session-specific storage.
---
---A Lua table that can hold arbitrary unordered session-specific names and values, which will last until the session ends.
---
---For example, this table could be useful to store current tasks when working with a [Tarantool queue manager](https://github.com/tarantool/queue).
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> box.session.peer(box.session.id())
--- ---
--- - 127.0.0.1:45129
--- ...
--- tarantool> box.session.storage.random_memorandum = "Don't forget the eggs"
--- ---
--- ...
--- tarantool> box.session.storage.radius_of_mars = 3396
--- ---
--- ...
--- tarantool> m = ''
--- ---
--- ...
--- tarantool> for k, v in pairs(box.session.storage) do
--- >   m = m .. k .. '='.. v .. ' '
--- > end
--- ---
--- ...
--- tarantool> m
--- ---
--- - 'radius_of_mars=3396 random_memorandum=Don't forget the eggs. '
--- ...
--- ```
---
---@type table<number|string,any>
box.session.storage = {}

---Define a trigger for execution when a new session is created.
---
---It may be fired due to an event such as [`console.connect`](lua://console.connect>).
---
---The trigger function will be the first thing executed after a new session is created. If the trigger execution fails and raises an error, the error is sent to the client and the connection is closed.
---
---Details about trigger characteristics are in the [`triggers`](<doc://triggers-box_triggers) section.
---
---**Warning:**
---
---If a trigger always results in an error, it may become impossible to connect to a server to reset it.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> function f ()
--- >   x = x + 1
--- > end
--- tarantool> box.session.on_connect(f)
--- ```
---
---@param trigger_func? fun()
---@param old_trigger_func? fun()
---@return fun()? removed_trigger If the parameters are (nil, old-trigger-function), then the old trigger is deleted.
function box.session.on_connect(trigger_func, old_trigger_func) end

---Define a trigger for execution after a client has disconnected.
---
---If the trigger function causes an error, the error is logged but otherwise is ignored. The trigger is invoked while the session associated with the client still exists and can access session properties, such as [`box.session.id`](lua://box.session.id).
---
---*Since 1.10* the trigger function is invoked immediately after the disconnect, even if requests that were made during the session have not finished.
---
---Details about trigger characteristics are in the [`triggers`](<doc://triggers-box_triggers) section.
---
---**Example #1:**
---
--- ```tarantoolsession
--- tarantool> function f ()
--- >   x = x + 1
--- > end
--- tarantool> box.session.on_disconnect(f)
--- ```
---
---**Example #2:**
---
---After the following series of requests, a Tarantool instance will write a message using the [`log`](doc://log) module whenever any user connects or disconnects.
---
--- ```lua
--- function log_connect()
---     local log = require('log')
---     local m = 'Connection. user=' .. box.session.user() .. ' id=' .. box.session.id()
---     log.info(m)
--- end
---
--- function log_disconnect()
---     local log = require('log')
---     local m = 'Disconnection. user=' .. box.session.user() .. ' id=' .. box.session.id()
---     log.info(m)
--- end
---
--- box.session.on_connect(log_connect)
--- box.session.on_disconnect(log_disconnect)
--- ```
---
---Here is what might appear in the log file in a typical installation:
---
--- ```lua
--- 2014-12-15 13:21:34.444 [11360] main/103/iproto I>
--- Connection. user=guest id=3
--- 2014-12-15 13:22:19.289 [11360] main/103/iproto I>
--- Disconnection. user=guest id=3
--- ```
---
---@param trigger_func? fun()
---@param old_trigger_func? fun()
---@return fun()? removed_trigger If the parameters are (nil, old-trigger-function), then the old trigger is deleted.
function box.session.on_disconnect(trigger_func, old_trigger_func) end

---Define a trigger for execution during authentication.
---
---The `on_auth` trigger function is invoked in these circumstances:
---* The :ref:`console.connect <console-connect>` function includes an authentication check for all users except 'guest'. For this case, the `on_auth` trigger function is invoked after the `on_connect` trigger function, if and only if the connection has succeeded so far.
---* The [`binary protocol`](doc://admin-security) has a separate [`authentication packet`](doc://box_protocol-authentication). For this case, connection and authentication are considered to be separate steps.
---
---Unlike other trigger types, `on_auth` trigger functions are invoked **before** the event. Therefore a trigger function like `function auth_function () v = box.session.user(); end` will set `v` to `"guest"`, the user name before the authentication is done. To get the user name **after** the authentication is done, use the special syntax: `function auth_function (user_name) v = user_name; end`
---
---If the trigger fails by raising an error, the error is sent to the client and the connection is closed.
---
---Details about trigger characteristics are in the [`triggers`](<doc://triggers-box_triggers) section.
---
---**Example #1:**
---
--- ```tarantoolsession
--- tarantool> function f ()
--- >   x = x + 1
--- > end
--- tarantool> box.session.on_auth(f)
--- ```
---
---**Example #2:**
---
---This is a more complex example, with two server instances. The first server instance listens on port 3301; its default user name is `'admin'`.
---
---There are three `on_auth` triggers:
---* The first trigger has a function with no arguments, it can only look at `box.session.user()`.
---* The second trigger has a function with a `user_name` argument, it can look at both of: `box.session.user()` and `user_name`.
---* The third trigger has a function with a `user_name` argument and a `status` argument, it can look at all three of: `box.session.user()` and `user_name` and `status`.
---
---The second server instance will connect with [`console.connect`](lua://console.connect), and then will cause a display of the variables that were set by the trigger functions.
---
--- ```lua
--- -- On the first server instance, which listens on port 3301
--- box.cfg{listen=3301}
--- function function1()
---     print('function 1, box.session.user()='..box.session.user())
--- end
--- function function2(user_name)
---     print('function 2, box.session.user()='..box.session.user())
---     print('function 2, user_name='..user_name)
--- end
--- function function3(user_name, status)
---     print('function 3, box.session.user()='..box.session.user())
---     print('function 3, user_name='..user_name)
---     if status == true then
---         print('function 3, status = true, authorization succeeded')
---     end
--- end
--- box.session.on_auth(function1)
--- box.session.on_auth(function2)
--- box.session.on_auth(function3)
--- box.schema.user.passwd('admin')
--- ```
---
--- ```lua
--- -- On the second server instance, that connects to port 3301
--- console = require('console')
--- console.connect('admin:admin@localhost:3301')
--- ```
---
---The result looks like this:
---
--- ```console
--- function 3, box.session.user()=guest
--- function 3, user_name=admin
--- function 3, status = true, authorization succeeded
--- function 2, box.session.user()=guest
--- function 2, user_name=admin
--- function 1, box.session.user()=guest
--- ```
---
---@param trigger_func? fun()
---@param old_trigger_func? fun()
---@return fun()? removed_trigger If the parameters are (nil, old-trigger-function), then the old trigger is deleted.
function box.session.on_auth(trigger_func, old_trigger_func) end

---Define a trigger for reacting to user's attempts to execute actions that are not within the user's privileges.
---
---Details about trigger characteristics are in the [`triggers`](doc://triggers-box_triggers) section.
---
---**Example:**
---
---For example, server administrator can log restricted actions like this:
---
--- ```tarantoolsession
--- tarantool> function on_access_denied(op, type, name)
--- > log.warn('User %s tried to %s %s %s without required privileges', box.session.user(), op, type, name)
--- > end
--- ---
--- ...
--- tarantool> box.session.on_access_denied(on_access_denied)
--- ---
--- - 'function: 0x011b41af38'
--- ...
--- tarantool> function test() print('you shall not pass') end
--- ---
--- ...
--- tarantool> box.schema.func.create('test')
--- ---
--- ...
--- ```
---
---Then, when some user without required privileges tries to call `test()` and gets the error, the server will execute this trigger and write to log **"User *user_name* tried to Execute function test without required privileges"**.
---@param trigger_func? fun()
---@param old_trigger_func? fun()
---@return fun()? removed_trigger If the parameters are (nil, old-trigger-function), then the old trigger is deleted.
function box.session.on_access_denied(trigger_func, old_trigger_func) end

---Generate an out-of-band message.
---
---*Deprecated since 3.0.0*
---
---By "out-of-band" we mean an extra message which supplements what is passed in a network via the usual channels. Although `box.session.push()` can be called at any time, in practice it is used with networks that are set up with [`net.box`](lua://net.box), and it is invoked by the server (on the "remote database system" to use our terminology for net.box), and the client has options for getting such messages.
---
---This function returns an error if the session is disconnected.
---
---If it is omitted, the default is the current `box.session.sync()` value. *Since 2.4.2*, `sync` is *deprecated* and its use will cause a warning. *Since 2.5.1*, its use will cause an error.
---
---* If the result is an error, then the first part of the return is `nil` and the second part is the error object.
---* If the result is not an error, then the return is the boolean value `true`.
---* When the return is `true`, the message has gone to the network buffer as a [`packet`](doc://box_protocol-iproto_protocol) with a different header code so the client can distinguish from an ordinary Okay response.
---
---The server's sole job is to call `box.session.push()`, there is no automatic mechanism for showing that the message was received.
---
---The client's job is to check for such messages after it sends something to the server. The major client methods -- [`conn:call`](lua://net.box.conn.call), [`conn:eval`](lua://net.box.conn.eval), [`conn:select`](lua://net.box.conn.select), [`conn:insert`](lua://net.box.conn.insert), [`conn:replace`](lua://net.box.conn.replace), [`conn:update`](lua://net.box.conn.update), [`conn:upsert`](lua://net.box.conn.upsert), [`conn:delete`](lua://net.box.conn.delete) -- may cause the server to send a message.
---
---Situation 1: when the client calls synchronously with the default `{async=false}` option. There are two optional additional options: `on_push={function-name}`, and :samp:`on_push_ctx={function-argument}`. When the client receives an out-of-band message for the session, it invokes "function-name(function-argument)". For example, with options `{on_push=table.insert, on_push_ctx=messages}`, the client will insert whatever it receives into a table named 'messages'.
---
---Situation 2: when the client calls asynchronously with the non-default `{async=true}` option. Here `on_push` and `on_push_ctx` are not allowed, but the messages can be seen by calling `pairs()` in a loop.
---
---Situation 2 complication: `pairs()` is subject to timeout. So there is an optional argument = timeout per iteration. If timeout occurs before there is a new message or a final response, there is an error return.
---
---To check for an error one can use the first loop parameter (if the loop starts with "for i, message in future:pairs()" then the first loop parameter is i). If it is `box.NULL` then the second parameter (in our example, "message") is the error object.
---
---**Example:**
---
--- ```lua
--- -- Make two shells. On Shell#1 set up a "server", and
--- -- in it have a function that includes box.session.push:
--- box.cfg{listen=3301}
--- box.schema.user.grant('guest','read,write,execute','universe')
--- x = 0
--- fiber = require('fiber')
--- function server_function() x=x+1; fiber.sleep(1); box.session.push(x); end
---
--- -- On Shell#2 connect to this server as a "client" that
--- -- can handle Lua (such as another Tarantool server operating
--- -- as a client), and initialize a table where we'll get messages:
--- net_box = require('net.box')
--- conn = net_box.connect(3301)
--- messages_from_server = {}
---
--- -- On Shell#2 remotely call the server function and receive
--- -- a SYNCHRONOUS out-of-band message:
--- conn:call('server_function', {},
--- {is_async = false,
--- on_push = table.insert,
--- on_push_ctx = messages_from_server})
--- messages_from_server
--- -- After a 1-second pause that is caused by the fiber.sleep()
--- -- request inside server_function, the result in the
--- --  messages_from_server table will be: 1. Like this:
--- -- tarantool> messages_from_server
--- -- ---
--- -- - - 1
--- -- ...
--- -- Good. That shows that box.session.push(x) worked,
--- -- because we know that x was 1.
---
--- -- On Shell#2 remotely call the same server function and
--- -- get an ASYNCHRONOUS out-of-band message. For this we cannot
--- -- use on_push and on_push_ctx options, but we can use pairs():
--- future = conn:call('server_function', {}, {is_async = true})
--- messages = {}
--- keys = {}
--- for i, message in future:pairs() do
---     table.insert(messages, message) table.insert(keys, i) end
--- messages
--- future:wait_result(1000)
--- for i, message in future:pairs() do
--- table.insert(messages, message) table.insert(keys, i) end
--- messages
--- -- There is no pause because conn:call does not wait for
--- -- server_function to finish. The first time that we go through
--- -- the pairs() loop, we see the messages table is empty. Like this:
--- -- tarantool> messages
--- -- ---
--- -- - - 2
--- --   - []
--- -- ...
--- -- That is okay because the server hasn't yet called
--- -- box.session.push(). The second time that we go through
--- -- the pairs() loop, we see the value of x at the time of
--- -- the second call to box.session.push(). Like this:
--- -- tarantool> messages
--- -- ---
--- -- - - 2
--- --   - &0 []
--- --   - 2
--- --   - *0
--- -- ...
--- -- Good. That shows that the message was asynchronous, and
--- -- that box.session.push() did its job.
--- ```
---
---@deprecated
---@param message tuple_type what to send
---@param sync? number deprecated
function box.session.push(message, sync) end

