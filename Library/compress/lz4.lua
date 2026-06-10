---@meta

---# Builtin `compress.lz4` submodule
---
---**⚠️ Enterprise Edition only.** This submodule is a part of the [Tarantool Enterprise Edition](https://www.tarantool.io/compare/).
---
---## Overview
---
---The `compress.lz4` submodule provides the ability to compress and decompress data using the [lz4](https://en.wikipedia.org/wiki/LZ4_(compression_algorithm)) algorithm.
---You can use the `lz4` compressor as follows:
---
---1.  Create a compressor instance using the [compress.lz4.new()](lua://compress.lz4.new) function:
---
--- ```lua
--- local lz4_compressor = require('compress.lz4').new()
--- -- or --
--- local lz4_compressor = require('compress').lz4.new()
--- ```
---
---    Optionally, you can pass compression options ([lz4_opts](lua://compress.lz4.opts)) specific for `lz4`:
---
--- ```lua
--- local lz4_compressor = require('compress.lz4').new({
---     acceleration = 1000,
---     decompress_buffer_size = 2097152
--- })
--- ```
---
---2.  To compress the specified data, use the [compress()](lua://compress.lz4.compressor.compress) method:
---
--- ```lua
--- compressed_data = lz4_compressor:compress('Hello world!')
--- ```
---
---3.  To decompress data, call [decompress()](lua://compress.lz4.compressor.decompress):
---
--- ```lua
--- decompressed_data = lz4_compressor:decompress(compressed_data)
--- ```
---@class compress.lz4
local lz4 = {}

---Configuration options of the [lz4_compressor](lua://compress.lz4.compressor).
---These options can be passed to the [compress.lz4.new()](lua://compress.lz4.new) function.
---@class compress.lz4.opts
---@field acceleration? integer Specifies the acceleration factor that enables you to adjust the compression ratio and speed. The higher acceleration factor increases the compression speed but decreases the compression ratio. (Default: 1, Maximum: 65537, Minimum: 1)
---@field decompress_buffer_size? integer Specifies the decompress buffer size (in bytes). If the size of decompressed data is larger than this value, the compressor returns an error on decompression. (Default: 1048576)

---A compressor instance that exposes the API for compressing and decompressing data using the `lz4` algorithm.
---To create the `lz4` compressor, call [compress.lz4.new()](lua://compress.lz4.new).
---@class compress.lz4.compressor
local lz4_compressor = {}

---Compress the specified data.
---
---**Example**
---
--- ```lua
--- compressed_data = lz4_compressor:compress('Hello world!')
--- ```
---
---@param data string data to be compressed
---@return string data compressed data
function lz4_compressor:compress(data) end

---Decompress the specified data.
---
---**Example**
---
--- ```lua
--- decompressed_data = lz4_compressor:decompress(compressed_data)
--- ```
---
---@param data string data to be decompressed
---@return string data decompressed data
function lz4_compressor:decompress(data) end

---Create a `lz4` compressor instance.
---
---**Example**
---
--- ```lua
--- local lz4_compressor = require('compress.lz4').new({
---     acceleration = 1000,
---     decompress_buffer_size = 2097152
--- })
--- ```
---
---@param options? compress.lz4.opts `lz4` compression options (see [lz4_opts](lua://compress.lz4.opts))
---@return compress.lz4.compressor compressor a new `lz4` compressor instance
function lz4.new(options) end

return lz4
