-- validate: skip -- the `mysql`/`pg` connector rocks are not installed here;
-- type-checked only.
--
-- Theme: the SQL DBMS connector rocks `mysql` and `pg`. connect() yields a typed
-- connection, ping() -> boolean, and execute() -> (rows, count) where rows is an
-- array of {column = value} tables and count is the row count. Every result is
-- captured at its concrete type and used.

local mysql = require('mysql')
local pg = require('pg')

--------------------------------------------------------------------------------
-- mysql: connect with options (incl. `raise`), ping, execute, close
--------------------------------------------------------------------------------

local my_conn = mysql.connect({
    host = '127.0.0.1',
    port = 3306,
    user = 'p',
    password = 'p',
    db = 'test',
    raise = true,
})

---@type boolean
local my_alive = my_conn:ping()

-- execute returns the result set and a row count; `?` placeholders are filled
-- from the extra arguments.
local my_rows, my_count = my_conn:execute('select name, age from users where age > ?', 18)
---@type integer?
local my_n = my_count
---@type integer
local my_seen = 0
for _, row in ipairs(my_rows) do
    -- each row is a {column = value} table.
    my_seen = my_seen + 1
    print(row.name, row.age)
end
print(my_alive, my_n, my_seen)

my_conn:close()

-- A Unix-socket connection: host = 'unix/', port = <socket path>.
local my_sock = mysql.connect({ host = 'unix/', port = '/var/run/mysqld/mysqld.sock' })
print(my_sock:ping())

--------------------------------------------------------------------------------
-- pg: same shape, but `$N` placeholders and a 5432 default port
--------------------------------------------------------------------------------

local pg_conn = pg.connect({
    host = '127.0.0.1',
    port = 5432,
    user = 'p',
    password = 'p',
    db = 'test',
})

---@type boolean
local pg_alive = pg_conn:ping()

local pg_rows = pg.connect({ host = '127.0.0.1' }):execute('select tablename from pg_tables where schemaname = $1', 'public')
---@type integer
local pg_tables = 0
for _, row in ipairs(pg_rows) do
    pg_tables = pg_tables + 1
    print(row.tablename)
end
print(pg_alive, pg_tables)

pg_conn:close()
