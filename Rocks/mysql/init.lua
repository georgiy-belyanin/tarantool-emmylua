---@meta

---# Rock `mysql`
---
---The `mysql` rock is a connector that allows connecting to a MySQL server and executing SQL statements
---the same way that a MySQL client does. The SQL statements are visible as Lua methods, so Tarantool can
---serve as a "MySQL Lua Connector".
---
---The methods for connect/select/insert/etc. are similar to the ones in the [`net.box`](lua://net_box-module) module.
---
---**Example:**
---
--- ```lua
--- local mysql = require('mysql')
--- local conn = mysql.connect({ host = '127.0.0.1', port = 3306, user = 'p', password = 'p', db = 'test' })
--- ```
local mysql = {}

---Connection options for [`mysql.connect`](lua://mysql.connect).
---
---The option names, except for `raise`, are similar to the names that MySQL's `mysql` client uses.
---To connect with a Unix socket rather than with TCP, specify `host = 'unix/'` and `port = <socket-name>`.
---
---@class mysql.connect_options
---@field host? string (Default: 'localhost') a host name or IP address; use `'unix/'` for a Unix socket connection.
---@field port? integer | string (Default: 3306) a port number, or the socket name when `host = 'unix/'`.
---@field user? string (Default: the operating-system user name) a user name.
---@field password? string (Default: blank) a password.
---@field db? string (Default: blank) a database name.
---@field raise? boolean (Default: false) if `true`, errors are raised when encountered.

---@class mysql.connection
local connection = {}

---Connect to a MySQL server.
---
---@param options mysql.connect_options the connection options
---@return mysql.connection
function mysql.connect(options) end

---Ensure that a connection is working.
---
---@return boolean # `true` if the connection is alive
function connection:ping() end

---Execute an SQL statement.
---
---The optional `parameters` are extra values that can be plugged in to replace any question marks (`?`)
---in the SQL statement.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> conn:execute('select table_name from information_schema.tables')
--- ---
--- - - table_name: ALL_PLUGINS
---   - table_name: APPLICABLE_ROLES
---   <...>
--- - 78
--- ...
--- ```
---
---@param sql_statement string an SQL statement
---@param ... any extra values substituted for the `?` placeholders
---@return table[] # the result set: an array of rows, each represented as a `{column = value}` table
---@return integer? # the number of returned (or affected) rows
function connection:execute(sql_statement, ...) end

---End a session that began with [`mysql.connect`](lua://mysql.connect).
function connection:close() end

return mysql
