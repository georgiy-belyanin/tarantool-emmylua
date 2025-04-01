---@meta

---@alias box.index_part_def { is_nullable?: boolean, collation?: string, path?: string, fieldno?: integer, [1]: string | integer, [2]: tuple_type_name | nil } | { is_nullable?: boolean, collation?: string, path?: string, fieldno?: integer, field: integer | string, type?: tuple_type_name }

---@alias box.index_type "TREE" | "HASH" | "BITSET" | "RTREE" | "tree" | "hash" | "bitset" | "rtree"

---@class box.index_options: table
---@field name? string name of the index
---@field type? box.index_type (Default: "TREE") type of index
---@field id? integer (Default: last index’s id + 1) unique identifier
---@field unique? boolean (Default: true) index is unique
---@field if_not_exists? boolean (Default: false) no error if duplicate name
---@field parts? box.index_part_def[] field numbers + types
---@field dimension? integer (Default: 2) affects RTREE only
---@field distance? "euclid" | "manhattan" (Default: euclid) affects RTREE only
---@field bloom_fpr? number (Default: vinyl_bloom_fpr) affects vinyl only
---@field page_size? number (Default: vinyl_page_size) affects vinyl only
---@field range_size? number (Default: vinyl_range_size) affects vinyl only
---@field run_count_per_level? number (Default: vinyl_run_count_per_level) affects vinyl only
---@field run_size_ratio? number (Default: vinyl_run_size_ratio) affects vinyl only
---@field sequence? string|number
---@field func? string functional index
---@field hint? boolean (Default: true) affects TREE only. true makes an index work faster, false – index size is reduced by half

---@class box.index_part
---@field type string type of the field
---@field is_nullable boolean false if field not-nullable, otherwise true
---@field fieldno integer position in tuple of the field

---@class box.index<T, U>: box.index_options
---@field parts box.index_part[] list of index parts
local index_methods = {}

---Search for a tuple via the given index.
---
---**Possible errors:**
---
---* `index_object` does not exist.
---* Wrong type.
---* More than one tuple matches.
---
---**Complexity factors:**
---
---* Index size.
---* Index type.
---
---The `box.space...select` function returns a set of tuples as a Lua table; the `box.space...get` function returns at most a single tuple.
---And it is possible to get the first tuple in a space by appending `[1]`. Therefore `box.space.tester:get{1}` has the same effect as `box.space.tester:select{1}[1]`, if exactly one tuple is found.
---
---**Example:**
---
--- ```
--- ```tarantoolsession
--- tarantool> box.space.tester.index.primary:get(2)
--- ---
--- - [2, 'Music']
--- ...
--- ```
---
---@param key box.tuple<T, U>|tuple_type[]|scalar
---@return box.tuple<T, U>? tuple the tuple whose index key matches key, or nil.
function index_methods:get(key) end

---Search for a tuple or a set of tuples by the current index.
---
---To search by the primary index in the specified space, use the [`box.space.select`](lua://box.space.select) method.
---
---**Note:** this method doesn't yield. For details, [Cooperative multitasking](doc://app-cooperative_multitasking).
---
---**Note:** the `after` and `fetch_pos` options are supported for the `TREE` :ref:`index <index-types>` only.
---
---This function might return one or two values:
---* The tuples whose fields are equal to the fields of the passed key. If the number of passed fields is less than the number of fields in the current key, then only the passed fields are compared, so `select{1,2}` matches a tuple whose primary key is `{1,2,3}`.
---* (Optionally) If `options.fetch_pos` is set to `true`, returns a base64-encoded string representing the position of the last selected tuple as the second value.
---
---If no tuples are fetched, returns `nil`.
---
---**Warning:**
---
---Use the `offset` option carefully when scanning large data sets as it linearly increases the number of scanned tuples and leads to a full space scan. Instead, you can use the `after` and `fetch_pos` options.
---
---**Examples:**
---
--- ```lua
--- box.space.bands:insert { 1, 'Roxette', 1986 }
--- box.space.bands:insert { 2, 'Scorpions', 1965 }
--- box.space.bands:insert { 3, 'Ace of Base', 1987 }
--- box.space.bands:insert { 4, 'The Beatles', 1960 }
--- box.space.bands:insert { 5, 'Pink Floyd', 1965 }
--- box.space.bands:insert { 6, 'The Rolling Stones', 1962 }
--- box.space.bands:insert { 7, 'The Doors', 1965 }
--- box.space.bands:insert { 8, 'Nirvana', 1987 }
--- box.space.bands:insert { 9, 'Led Zeppelin', 1968 }
--- box.space.bands:insert { 10, 'Queen', 1970 }
---
--- -- Select a tuple by the specified primary key value --
--- select_primary = bands.index.primary:select { 1 }
--- --[[
--- ---
--- - - [1, 'Roxette', 1986]
--- ...
--- --]]
---
--- -- Select a tuple by the specified secondary key value --
--- select_secondary = bands.index.band:select { 'The Doors' }
--- --[[
--- ---
--- - - [7, 'The Doors', 1965]
--- ...
--- --]]
---
--- -- Select a tuple by the specified multi-part secondary key value --
--- select_multipart = bands.index.year_band:select { 1960, 'The Beatles' }
--- --[[
--- ---
--- - - [4, 'The Beatles', 1960]
--- ...
--- --]]
---
--- -- Select tuples by the specified partial key value --
--- select_multipart_partial = bands.index.year_band:select { 1965 }
--- --[[
--- ---
--- - - [5, 'Pink Floyd', 1965]
---   - [2, 'Scorpions', 1965]
---   - [7, 'The Doors', 1965]
--- ...
--- --]]
---
--- -- Select maximum 3 tuples by the specified secondary index --
--- select_limit = bands.index.band:select({}, { limit = 3 })
--- --[[
--- ---
--- - - [3, 'Ace of Base', 1987]
---   - [9, 'Led Zeppelin', 1968]
---   - [8, 'Nirvana', 1987]
--- ...
--- --]]
---
--- -- Select maximum 3 tuples with the key value greater than 1965 --
--- select_greater = bands.index.year:select({ 1965 }, { iterator = 'GT', limit = 3 })
--- --[[
--- ---
--- - - [9, 'Led Zeppelin', 1968]
---   - [10, 'Queen', 1970]
---   - [1, 'Roxette', 1986]
--- ...
--- --]]
---
--- -- Select maximum 3 tuples after the specified tuple --
--- select_after_tuple = bands.index.primary:select({}, { after = { 4, 'The Beatles', 1960 }, limit = 3 })
--- --[[
--- ---
--- - - [5, 'Pink Floyd', 1965]
---   - [6, 'The Rolling Stones', 1962]
---   - [7, 'The Doors', 1965]
--- ...
--- --]]
---
--- -- Select first 3 tuples and fetch a last tuple's position --
--- result, position = bands.index.primary:select({}, { limit = 3, fetch_pos = true })
--- -- Then, pass this position as the 'after' parameter --
--- select_after_position = bands.index.primary:select({}, { limit = 3, after = position })
--- --[[
--- ---
--- - - [4, 'The Beatles', 1960]
---   - [5, 'Pink Floyd', 1965]
---   - [6, 'The Rolling Stones', 1962]
--- ...
--- --]]
---```
---
---**Note:**
---
---`box.space.{space-name}.index.{index-name}:select(...)[1]` can be replaced with `box.space.{space-name}.index.{index-name}:get(...)`.
---
---That is, `get` can be used as a convenient shorthand to get the first tuple in the tuple set that would be returned by `select`.
---
---However, if there is more than one tuple in the tuple set, then `get` throws an error.
---
---@param key box.tuple<T, U> | tuple_type[] | scalar
---@param options? box.space.select_options
---@return box.tuple<T, U>[] list the list of tuples
function index_methods:select(key, options) end

---Search for a tuple or a set of tuples via the given index, and allow iterating over one tuple at a time.
---
---To search by the primary index in the specified space, use the [`box.space.pairs`](lua://box.space.pairs) method.
---
---The `{key}` parameter specifies what must match within the index.
---
---**Note:** `{key}` is only used to find the first match. Do not assume all matched tuples will contain the key.
---
---The `{iterator}` parameter specifies the rule for matching and ordering. Different index types support different iterators. For example, a TREE index maintains a strict order of keys and can return all tuples in ascending or descending order, starting from the specified key. Other index types, however, do not support ordering.
---
---To understand consistency of tuples returned by an iterator, it's essential to know the principles of the Tarantool transaction processing subsystem. An iterator in Tarantool does not own a consistent read view.
---
---Instead, each procedure is granted exclusive access to all tuples and spaces until there is a "context switch": which may happen due to [the implicit yield rules](doc://app-implicit-yields), or by an explicit call to [`fiber.yield`](lua://fiber-yield).
---
---When the execution flow returns to the yielded procedure, the data set could have changed significantly. Iteration, resumed after a yield point, does not preserve the read view, but continues with the new content of the database. The tutorial [indexed pattern search](doc://c_lua_tutorial-indexed_pattern_search) shows one way that iterators and yields can be used together.
---
---For information about iterators' internal structures, see the ["Lua Functional library"](https://luafun.github.io/index.html) documentation.
---
---**Examples:**
---
--- ```tarantoolsession
--- -- Insert test data --
--- tarantool> bands:insert{1, 'Roxette', 1986}
--- bands:insert{2, 'Scorpions', 1965}
--- bands:insert{3, 'Ace of Base', 1987}
--- bands:insert{4, 'The Beatles', 1960}
--- bands:insert{5, 'Pink Floyd', 1965}
--- bands:insert{6, 'The Rolling Stones', 1962}
--- bands:insert{7, 'The Doors', 1965}
--- bands:insert{8, 'Nirvana', 1987}
--- bands:insert{9, 'Led Zeppelin', 1968}
--- bands:insert{10, 'Queen', 1970}
--- ---
--- ...
---
--- -- Select all tuples by the primary index --
--- tarantool> for _, tuple in bands.index.primary:pairs() do
--- print(tuple)
--- end
--- [1, 'Roxette', 1986]
--- [2, 'Scorpions', 1965]
--- [3, 'Ace of Base', 1987]
--- [4, 'The Beatles', 1960]
--- [5, 'Pink Floyd', 1965]
--- [6, 'The Rolling Stones', 1962]
--- [7, 'The Doors', 1965]
--- [8, 'Nirvana', 1987]
--- [9, 'Led Zeppelin', 1968]
--- [10, 'Queen', 1970]
--- ---
--- ...
---
--- -- Select all tuples whose secondary key values start with the specified string --
--- tarantool> for _, tuple in bands.index.band:pairs("The", {iterator = "GE"}) do
--- if (string.sub(tuple[2], 1, 3) ~= "The") then break end
--- print(tuple)
--- end
--- [4, 'The Beatles', 1960]
--- [7, 'The Doors', 1965]
--- [6, 'The Rolling Stones', 1962]
--- ---
--- ...
---
--- -- Select all tuples whose secondary key values are between 1965 and 1970 --
--- tarantool> for _, tuple in bands.index.year:pairs(1965, {iterator = "GE"}) do
--- if (tuple[3] > 1970) then break end
--- print(tuple)
--- end
--- [2, 'Scorpions', 1965]
--- [5, 'Pink Floyd', 1965]
--- [7, 'The Doors', 1965]
--- [9, 'Led Zeppelin', 1968]
--- [10, 'Queen', 1970]
--- ---
--- ...
---
--- -- Select all tuples after the specified tuple --
--- tarantool> for _, tuple in bands.index.primary:pairs({}, {after={7, 'The Doors', 1965}}) do
--- print(tuple)
--- end
--- [8, 'Nirvana', 1987]
--- [9, 'Led Zeppelin', 1968]
--- [10, 'Queen', 1970]
--- ---
--- ...
--- ```
---
---@param key box.tuple<T, U> | tuple_type[] | scalar value to be matched against the index key, which may be multi-part
---@param iterator? box.iterator (Default: 'EQ') defines iterator order
---@return box.space.iterator<T, U> iter Luafun iterator
---@return box.space.iterator.param
---@return box.space.iterator.state
function index_methods:pairs(key, iterator) end

---Update a tuple.
---
---The update function supports operations on fields — assignment, arithmetic (if the field is numeric), cutting and pasting fragments of a field, deleting or inserting a field.
---Multiple operations can be combined in a single update request, and in this case they are performed atomically and sequentially.
---Each operation requires specification of a field identifier, which is usually a number.
---When multiple operations are present, the field number for each operation is assumed to be relative to the most recent state of the tuple, that is, as if all previous operations in a multi-operation update have already been applied.
---In other words, it is always safe to merge multiple update invocations into a single invocation, with no change in semantics.
---@param key box.tuple<T,U> | tuple_type[] | scalar
---@param update_operations [box.update_operation, number|string, tuple_type][]
---@return box.tuple<T,U>? tuple the updated tuple if it was found
function index_methods:update(key, update_operations) end

---Find the maximum value in the specified index.
---
---**Possible errors:**
---
---* Index is not of type 'TREE'.
---* `ER_TRANSACTION_CONFLICT` if a transaction conflict is detected in the [`MVCC transaction mode`](doc://txn_mode_transaction-manager).
---
---**Complexity factors:**
---* Index size.
---* Index type.
---
---**Examples:**
---
--- ```lua
--- -- Find the maximum value in the specified index
--- max = box.space.bands.index.year:max()
--- --[[
--- ---
--- - [8, 'Nirvana', 1987]
--- ...
--- --]]
---
--- -- Find the maximum value that matches the partial key value
--- max_partial = box.space.bands.index.year_band:max(1965)
--- --[[
--- ---
--- - [7, 'The Doors', 1965]
--- ...
--- --]]
--- ```
---
---@param key box.tuple<T, U> | tuple_type[] | scalar
---@return box.tuple<T, U>? tuple result
function index_methods:max(key) end

---Find the minimum value in the specified index.
---
---**Possible errors:**
---
---* Index is not of type 'TREE'.
---* `ER_TRANSACTION_CONFLICT` if a transaction conflict is detected in the [`MVCC transaction mode`](doc://txn_mode_transaction-manager).
---
---**Complexity factors:**
---* Index size.
---* Index type.
---
---**Examples:**
---
--- ```lua
--- min = box.space.bands.index.year:min()
--- --[[
--- ---
--- - [4, 'The Beatles', 1960]
--- ...
--- --]]
---
--- -- Find the minimum value that matches the partial key value
--- min_partial = box.space.bands.index.year_band:min(1965)
--- --[[
--- ---
--- - [5, 'Pink Floyd', 1965]
--- ...
--- --]]
--- ```
---
---@param key box.tuple<T, U> | tuple_type[] | scalar
---@return box.tuple<T, U>? tuple result
function index_methods:min(key) end

---Iterate over an index, counting the number of tuples which match the key-value.
---
---Return the number of tuples. If compared with `len()`, this method works slower because `count()` scans the entire space to `count` the tuples.
---
---**Example:**
---
--- ```lua
--- -- Count the number of tuples that match the full key value
--- count = box.space.bands.index.year:count(1965)
--- --[[
--- ---
--- - 3
--- ...
--- --]]
---
--- -- Count the number of tuples that match the partial key value
--- count_partial = box.space.bands.index.year_band:count(1965)
--- --[[
--- ---
--- - 3
--- ...
--- --]]
--- ```
---@param key? box.tuple<T, U> | tuple_type[] | scalar
---@param iterator? box.iterator
---@return integer number_of_tuples
function index_methods:count(key, iterator) end

---Return the total number of bytes taken by the index.
---
---@return integer
function index_methods:bsize() end

---Delete a tuple identified by a key.
---
---Same as [`box.space...delete()`](box.space.delete), but key is searched in this index instead of in the primary-key index.
---
---This index ought to be unique.
---
---**Note regarding storage engine:** vinyl will return `nil`, rather than the deleted tuple.
---
---@param key box.tuple<T, U> | tuple_type[] | scalar
---@return box.tuple<T, U>? tuple the deleted tuple
function index_methods:delete(key) end

---Alter an index.
---
---It is legal in some circumstances to change one or more of the index characteristics, for example its type, its sequence options, its parts, and whether it is unique.
---
---Usually this causes rebuilding of the space, except for the simple case where a part’s is_nullable flag is changed from false to true.
---
---@param opts box.index_options
function index_methods:alter(opts) end

---Return a tuple's position for an index.
---
---This value can be passed to the `after` option of the `select` and `pairs` methods:
---* [`index_object:select`](lua://box.index.select) and [`space_object:select`](lua://box.space.select)
---* [`index_object:pairs`](lua://box.index.pairs) and [`space_object:pairs`](lua://box.space.pairs)
---
---**Note:** `tuple_pos` does not work with [functional](box.space.index.func) and multikey indexes.
---
---**Example:**
---
--- ```tarantoolsession
--- -- Insert test data --
--- tarantool> bands:insert{1, 'Roxette', 1986}
--- bands:insert{2, 'Scorpions', 1965}
--- bands:insert{3, 'Ace of Base', 1987}
--- bands:insert{4, 'The Beatles', 1960}
--- bands:insert{5, 'Pink Floyd', 1965}
--- bands:insert{6, 'The Rolling Stones', 1962}
--- ---
--- ...
---
--- -- Get a tuple's position --
--- tarantool> position = bands.index.primary:tuple_pos({3, 'Ace of Base', 1987})
--- ---
--- ...
--- -- Pass the tuple's position as the 'after' parameter --
--- tarantool> bands:select({}, {limit = 3, after = position})
--- ---
--- - - [4, 'The Beatles', 1960]
--- - [5, 'Pink Floyd', 1965]
--- - [6, 'The Rolling Stones', 1962]
--- ...
--- ```
---
---@param tuple scalar | table
---@return string # base64-encoded string (a tuple’s position in a space)
function index_methods:tuple_pos(tuple) end
