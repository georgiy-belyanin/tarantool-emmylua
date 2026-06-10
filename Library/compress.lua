---@meta

---# Builtin `compress` module
---
---**⚠️ Enterprise Edition.** This module is a part of the [Tarantool Enterprise Edition](https://www.tarantool.io/compare/).
---
---*Since 2.11.0*
---
---The `compress` module provides a set of submodules for compressing and decompressing data using different algorithms:
---
---* [compress.zlib](lua://compress.zlib)
---* [compress.zstd](lua://compress.zstd)
---* [compress.lz4](lua://compress.lz4)
---@class compress
---@field zlib compress.zlib Compress and decompress data using the [zlib](https://en.wikipedia.org/wiki/Zlib) algorithm.
---@field zstd compress.zstd Compress and decompress data using the [zstd](https://en.wikipedia.org/wiki/Zstd) algorithm.
---@field lz4 compress.lz4 Compress and decompress data using the [lz4](https://en.wikipedia.org/wiki/LZ4_(compression_algorithm)) algorithm.
local compress = {}

return compress
