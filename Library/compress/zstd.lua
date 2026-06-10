---@meta

---# Builtin `compress.zstd` submodule
---
---**⚠️ Enterprise Edition only.** This submodule is a part of the [Tarantool Enterprise Edition](https://www.tarantool.io/compare/).
---
---## Overview
---
---The `compress.zstd` submodule provides the ability to compress and decompress data using the [zstd](https://en.wikipedia.org/wiki/Zstd) algorithm.
---You can use the `zstd` compressor as follows:
---
---1.  Create a compressor instance using the [compress.zstd.new()](lua://compress.zstd.new) function:
---
--- ```lua
--- local zstd_compressor = require('compress.zstd').new()
--- -- or --
--- local zstd_compressor = require('compress').zstd.new()
--- ```
---
---    Optionally, you can pass compression options ([zstd_opts](lua://compress.zstd.opts)) specific for `zstd`:
---
--- ```lua
--- local zstd_compressor = require('compress.zstd').new({
---     level = 5
--- })
--- ```
---
---2.  To compress the specified data, use the [compress()](lua://compress.zstd.compressor.compress) method:
---
--- ```lua
--- compressed_data = zstd_compressor:compress('Hello world!')
--- ```
---
---3.  To decompress data, call [decompress()](lua://compress.zstd.compressor.decompress):
---
--- ```lua
--- decompressed_data = zstd_compressor:decompress(compressed_data)
--- ```
---@class compress.zstd
local zstd = {}

---Configuration options of the [zstd_compressor](lua://compress.zstd.compressor).
---These options can be passed to the [compress.zstd.new()](lua://compress.zstd.new) function.
---@class compress.zstd.opts
---@field level? integer Specifies the `zstd` compression level that enables you to adjust the compression ratio and speed. The lower level improves the compression speed at the cost of compression ratio. For example, you can use level 1 if speed is most important and level 22 if size is most important. (Default: 3, Minimum: -131072, Maximum: 22). **Note:** Assigning 0 to `level` resets its value to the default (3).

---A compressor instance that exposes the API for compressing and decompressing data using the `zstd` algorithm.
---To create the `zstd` compressor, call [compress.zstd.new()](lua://compress.zstd.new).
---@class compress.zstd.compressor
local zstd_compressor = {}

---Compress the specified data.
---
---**Example**
---
--- ```lua
--- compressed_data = zstd_compressor:compress('Hello world!')
--- ```
---
---@param data string data to be compressed
---@return string data compressed data
function zstd_compressor:compress(data) end

---Decompress the specified data.
---
---**Example**
---
--- ```lua
--- decompressed_data = zstd_compressor:decompress(compressed_data)
--- ```
---
---@param data string data to be decompressed
---@return string data decompressed data
function zstd_compressor:decompress(data) end

---Create a `zstd` compressor instance.
---
---**Example**
---
--- ```lua
--- local zstd_compressor = require('compress.zstd').new({
---     level = 5
--- })
--- ```
---
---@param options? compress.zstd.opts `zstd` compression options (see [zstd_opts](lua://compress.zstd.opts))
---@return compress.zstd.compressor compressor a new `zstd` compressor instance
function zstd.new(options) end

return zstd
