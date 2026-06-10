---@meta

---# Builtin `compress.zlib` submodule
---
---**⚠️ Enterprise Edition only.** This submodule is a part of the [Tarantool Enterprise Edition](https://www.tarantool.io/compare/).
---
---## Overview
---
---The `compress.zlib` submodule provides the ability to compress and decompress data using the [zlib](https://en.wikipedia.org/wiki/Zlib) algorithm.
---You can use the `zlib` compressor as follows:
---
---1.  Create a compressor instance using the [compress.zlib.new()](lua://compress.zlib.new) function:
---
--- ```lua
--- local zlib_compressor = require('compress.zlib').new()
--- -- or --
--- local zlib_compressor = require('compress').zlib.new()
--- ```
---
---    Optionally, you can pass compression options ([zlib_opts](lua://compress.zlib.opts)) specific for `zlib`:
---
--- ```lua
--- local zlib_compressor = require('compress.zlib').new({
---     level = 5,
---     mem_level = 5,
---     strategy = 'filtered'
--- })
--- ```
---
---2.  To compress the specified data, use the [compress()](lua://compress.zlib.compressor.compress) method:
---
--- ```lua
--- compressed_data = zlib_compressor:compress('Hello world!')
--- ```
---
---3.  To decompress data, call [decompress()](lua://compress.zlib.compressor.decompress):
---
--- ```lua
--- decompressed_data = zlib_compressor:decompress(compressed_data)
--- ```
---@class compress.zlib
local zlib = {}

---@alias compress.zlib.strategy
---| 'default' # for normal data.
---| 'huffman_only' # forces Huffman encoding only (no string match). The fastest compression algorithm but not very effective in compression for most of the data.
---| 'filtered' # for data produced by a filter or predictor. Filtered data consists mostly of small values with a somewhat random distribution. This compression algorithm is tuned to compress them better.
---| 'rle' # limits match distances to one (run-length encoding). `rle` is designed to be almost as fast as `huffman_only` but gives better compression for PNG image data.
---| 'fixed' # prevents the use of dynamic Huffman codes and provides a simpler decoder for special applications.

---Configuration options of the [zlib_compressor](lua://compress.zlib.compressor).
---These options can be passed to the [compress.zlib.new()](lua://compress.zlib.new) function.
---@class compress.zlib.opts
---@field level? integer Specifies the `zlib` compression level that enables you to adjust the compression ratio and speed. The lower level improves the compression speed at the cost of compression ratio. (Default: 6, Minimum: 0 (no compression), Maximum: 9)
---@field mem_level? integer Specifies how much memory is allocated for the `zlib` compressor. The larger value improves the compression speed and ratio. (Default: 8, Minimum: 1, Maximum: 9)
---@field strategy? compress.zlib.strategy Specifies the compression strategy.

---A compressor instance that exposes the API for compressing and decompressing data using the `zlib` algorithm.
---To create the `zlib` compressor, call [compress.zlib.new()](lua://compress.zlib.new).
---@class compress.zlib.compressor
local zlib_compressor = {}

---Compress the specified data.
---
---**Example**
---
--- ```lua
--- compressed_data = zlib_compressor:compress('Hello world!')
--- ```
---
---@param data string data to be compressed
---@return string data compressed data
function zlib_compressor:compress(data) end

---Decompress the specified data.
---
---**Example**
---
--- ```lua
--- decompressed_data = zlib_compressor:decompress(compressed_data)
--- ```
---
---@param data string data to be decompressed
---@return string data decompressed data
function zlib_compressor:decompress(data) end

---Create a `zlib` compressor instance.
---
---**Example**
---
--- ```lua
--- local zlib_compressor = require('compress.zlib').new({
---     level = 5,
---     mem_level = 5,
---     strategy = 'filtered'
--- })
--- ```
---
---@param options? compress.zlib.opts `zlib` compression options (see [zlib_opts](lua://compress.zlib.opts))
---@return compress.zlib.compressor compressor a new `zlib` compressor instance
function zlib.new(options) end

return zlib
