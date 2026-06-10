---@meta

---# Builtin `merger` module
---
---*Since 2.11.0*
---
---The `merger` module provides utilities to merge multiple sorted streams of tuples into a single sorted stream.
---
---It is typically used in sharded environments where data is partitioned across several Tarantool instances. The `merger` performs a k-way merge (similar to merge sort) over input sources that are already sorted according to a specified key definition.
---
---Supported input sources include:
---* **buffers** (raw MsgPack-encoded tuple streams),
---* **tables** (Lua arrays of tuples),
---* **tuple iterators**, or
---* **custom generators** that yield chunks or individual tuples.
---
---For full usage patterns and real-world examples, refer to the [merger examples repository](https://github.com/Totktonada/tarantool-merger-examples).
local merger = {}

---Opaque type representing a single sorted input stream of tuples.
---Created via `merger.new_*_source()` or convenience helpers.
---@class merger.source
local merger_source = {}


---Represents a merged stream of tuples from one or more sorted sources.
---Provides methods to consume the result.
---@class merger.object
local merger_object = {}

---Create a new merger source that yields individual tuples via a generator function.
---
---The generator function `gen` must return:
---* `<state>, <tuple>` — if more tuples are available,
---* `nil` — when the stream is exhausted.
---
---Both Lua tables (`{...}`) and `box.tuple` objects are accepted as tuples.
---
---This source is useful when you want to lazily generate or fetch tuples one by one (e.g., from a cursor or iterator).
---
---@param gen fun(param: any, state: any): any, any | nil
---@param param any
---@param state any
---@return merger.source
function merger.new_tuple_source(gen, param, state) end


---Create a new merger source that yields chunks of tuples as buffers.
---
---Each buffer must contain a valid MsgPack array of tuples (i.e., `{T, T, ...}` where `T` is a tuple).
---Buffers are typically obtained via `net.box` with `skip_header = true` and `buffer` option.
---
---The generator function `gen` must return:
---* `<state>, <buffer>` — if more chunks are available,
---* `nil` — when the stream ends.
---
---This source is optimal for streaming large result sets from remote instances without loading everything into memory at once.
---
---@param gen fun(param: any, state: any): any, buffer.ibuf | nil
---@param param any
---@param state any
---@return merger.source
function merger.new_buffer_source(gen, param, state) end


---Create a new merger source that yields chunks of tuples as Lua tables.
---
---Each returned table must be an array of tuples (`{{...}, {...}, ...}`).
---
---The generator function `gen` must return:
---* `<state>, <table>` — if more chunks are available,
---* `nil` — when the stream ends.
---
---Useful for processing local data or pre-fetched batches.
---
---@param gen fun(param: any, state: any): any, table | nil
---@param param any
---@param state any
---@return merger.source
function merger.new_table_source(gen, param, state) end


---Create a merger instance that merges multiple sorted sources into one sorted stream.
---
---The merger assumes **all input sources are already sorted** according to the provided `key_def`.
---
---If merging results from a **non-unique secondary index**, you must include the primary index key parts after the secondary parts (e.g., via `key_def:merge()`).
---
---The merge order is ascending by default; use `reverse = true` in `opts` for descending order.
---
---**Important**: Always use `skip_header = true` when capturing buffers from `net.box:select()`.
---
---@param key_def key_def
---@param sources merger.source[]
---@param opts? { reverse?: boolean }
---@return merger.object
function merger.new(key_def, sources, opts) end


---Create a merger source directly from a buffer containing a MsgPack-encoded tuple array.
---
---The buffer must point to data in the format `{T, T, ...}` (i.e., after skipping any IPROTO headers).
---
---This is a convenience wrapper around `new_buffer_source` for static data.
---
---@param buf buffer.ibuf
---@return merger.source
function merger.new_source_frombuffer(buf) end


---Create a merger source directly from a Lua table of tuples.
---
---Each element must be a tuple (Lua table or `box.tuple`).
---
---This is a convenience wrapper around `new_table_source` for static data.
---
---@param tbl table
---@return merger.source
function merger.new_source_fromtable(tbl) end


---Retrieve a batch of merged tuples.
---
---If a `buffer` is provided, the result is written to it in MsgPack format (without IPROTO header).
---If `limit` is specified, at most `limit` tuples are returned.
---
---Without arguments, returns all remaining tuples as a Lua table.
---
---**Example**:
--- ```lua
--- local merged = merger.new(key_def, {src1, src2})
--- local result = merged:select(nil, 10) -- first 10 tuples
--- ```
---
---@param buffer? buffer.ibuf
---@param limit? integer
---@return table
function merger_object:select(buffer, limit) end


---Return an iterator over the merged stream.
---
---The iterator supports functional-style operations via luafun (e.g., `:take()`, `:drop()`, `:filter()`, `:totable()`).
---
---Tuples are yielded in merged order, one at a time.
---
---**Example**:
--- ```lua
--- local merged = merger.new(key_def, {src1, src2})
--- for _, tuple in merged:pairs() do
---     print(yaml.encode(tuple))
--- end
--- ```
---
---@return fun(): any, any
function merger_object:pairs() end

return merger
