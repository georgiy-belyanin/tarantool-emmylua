-- Theme: filesystem (fio), OS helpers (os), and string extensions.
-- Standalone-runnable: performs real file I/O inside a fresh temporary directory.

local fio = require('fio')

--------------------------------------------------------------------------------
-- fio: path helpers (pure string operations)
--------------------------------------------------------------------------------

---@type string
local _joined = fio.pathjoin('/tmp', 'sub', 'file.txt')
---@type string
local _base = fio.basename('/tmp/sub/file.txt')
---@type string
local _dir = fio.dirname('/tmp/sub/file.txt')
---@type string
local _base_noext = fio.basename('/tmp/sub/file.txt', '.txt')
---@type string
local _abs = fio.abspath('.')
---@type string
local _cwd = fio.cwd()
print(_joined, _base, _dir, _base_noext, _abs, _cwd)

--------------------------------------------------------------------------------
-- fio: directories and files
--------------------------------------------------------------------------------

local tmp = fio.tempdir()
local dir = fio.pathjoin(tmp, 'data')
fio.mkdir(dir)

local path = fio.pathjoin(dir, 'hello.txt')

-- Open for writing, write, sync, close.
local fh = fio.open(path, { 'O_CREAT', 'O_WRONLY', 'O_TRUNC' }, tonumber('0644', 8))
assert(fh ~= nil)
---@type boolean
local _written = fh:write('hello, ')
fh:write('world')
fh:fsync()
fh:close()

-- Open for reading; read all, and a positional read.
local rh = fio.open(path, { 'O_RDONLY' })
assert(rh ~= nil)
---@type string
local _contents = rh:read()
rh:seek(0)
local _head = rh:pread(5, 0)
rh:close()
print(_written, _contents, _head)

-- Stat a path.
local st = fio.stat(path)
assert(st ~= nil)
---@type number
local _size = st.size
---@type boolean
local _is_reg = st:is_reg()
print(_size, _is_reg)

-- Directory listing and globbing.
local _entries = fio.listdir(dir)
local _matches = fio.glob(fio.pathjoin(dir, '*.txt'))
print(_entries, _matches)

-- Rename, then remove the file and the tree.
local path2 = fio.pathjoin(dir, 'renamed.txt')
fio.rename(path, path2)
fio.unlink(path2)
fio.rmtree(tmp)

--------------------------------------------------------------------------------
-- os: time, dates, environment (incl. Tarantool extensions environ/setenv)
--------------------------------------------------------------------------------

---@type number
local _time = os.time()
---@type string
local _date = os.date('%Y-%m-%d')
---@type number
local _osclock = os.clock()
local _home = os.getenv('HOME')

-- Tarantool extensions.
os.setenv('SAMPLE_VAR', '1')
local _environ = os.environ()
print(_time, _date, _osclock, _home, _environ)

--------------------------------------------------------------------------------
-- string: Tarantool extensions
--------------------------------------------------------------------------------

-- Splitting.
local _parts = ('a:b:c:d'):split(':')
local _limited = ('a:b:c:d'):split(':', 2)

-- Trimming.
---@type string
local _stripped = ('   padded   '):strip()
---@type string
local _lstripped = ('   left'):lstrip()
---@type string
local _rstripped = ('right   '):rstrip()

-- Prefix / suffix tests.
---@type boolean
local _starts = ('filename.lua'):startswith('file')
---@type boolean
local _ends = ('filename.lua'):endswith('.lua')

-- Padding.
---@type string
local _ljust = ('x'):ljust(5)
---@type string
local _rjust = ('x'):rjust(5, '.')

-- Hex round-trip.
---@type string
local _hex = ('AB'):hex()
---@type string
local _unhex = ('4142'):fromhex()
print(_parts, _limited, _stripped, _lstripped, _rstripped, _starts, _ends, _ljust, _rjust, _hex, _unhex)
