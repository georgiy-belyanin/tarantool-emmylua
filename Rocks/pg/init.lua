---@meta

---# Rock `pg`
---
---The `pg` rock is a connector that allows connecting to a PostgreSQL server and executing SQL statements
---the same way that a PostgreSQL client does. The SQL statements are visible as Lua methods, so Tarantool
---can serve as a "PostgreSQL Lua Connector".
---
---The methods for connect/select/insert/etc. are similar to the ones in the [`net.box`](lua://net_box-module) module.
---
---**Example:**
---
--- ```lua
--- local pg = require('pg')
--- local conn = pg.connect({ host = '127.0.0.1', port = 5432, user = 'p', password = 'p', db = 'test' })
--- ```
local pg = {}

---Connection options for [`pg.connect`](lua://pg.connect).
---
---The names are similar to the names that PostgreSQL itself uses.
---
---@class pg.connect_options
---@field host? string (Default: 'localhost') a host name or IP address.
---@field port? integer (Default: 5432) a port number.
---@field user? string (Default: the operating-system user name) a user name.
---@field pass? string (Default: blank) a password (alias for `password`).
---@field password? string (Default: blank) a password.
---@field db? string (Default: blank) a database name.

---@class pg.connection
local connection = {}

---Connect to a PostgreSQL server.
---
---@param options pg.connect_options the connection options
---@return pg.connection
function pg.connect(options) end

---Ensure that a connection is working.
---
---@return boolean # `true` if the connection is alive
function connection:ping() end

---Execute an SQL statement.
---
---The optional `parameters` are extra values that can be plugged in to replace any placeholders
---(`$1`, `$2`, `$3`, etc.) in the SQL statement.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> conn:execute('select tablename from pg_tables')
--- ---
--- - - tablename: pg_statistic
---   - tablename: pg_type
---   <...>
--- ...
--- ```
---
---@param sql_statement string an SQL statement
---@param ... any extra values substituted for the `$1`, `$2`, ... placeholders
---@return table[] # the result set: an array of rows, each represented as a `{column = value}` table
---@return integer? # the number of returned (or affected) rows
function connection:execute(sql_statement, ...) end

---End a session that began with [`pg.connect`](lua://pg.connect).
function connection:close() end

return pg
