-- Theme: the `compress` module (Enterprise Edition) -- zlib, zstd, lz4.
-- validate: enterprise -- `compress` is an EE-only module; runs on EE, skipped elsewhere.
-- Standalone-runnable on Tarantool Enterprise (no box.cfg).

local compress = require('compress')

local payload = string.rep('The quick brown fox. ', 32)

--------------------------------------------------------------------------------
-- zlib
--------------------------------------------------------------------------------

-- Default compressor.
local zlib = compress.zlib.new()
---@type string
local z_packed = zlib:compress(payload)
---@type string
local z_unpacked = zlib:decompress(z_packed)
print(#payload, #z_packed, z_unpacked == payload)

-- With explicit options.
local zlib_tuned = compress.zlib.new({
    level = 9,
    mem_level = 8,
    strategy = 'filtered',
})
local z2 = zlib_tuned:compress(payload)
print(#z2, zlib_tuned:decompress(z2) == payload)

-- The submodule can also be required directly.
local zlib_direct = require('compress.zlib').new()
print(zlib_direct:decompress(zlib_direct:compress('direct')) == 'direct')

--------------------------------------------------------------------------------
-- zstd
--------------------------------------------------------------------------------

local zstd = compress.zstd.new({ level = 5 })
---@type string
local zs_packed = zstd:compress(payload)
---@type string
local zs_unpacked = zstd:decompress(zs_packed)
print(#zs_packed, zs_unpacked == payload)

--------------------------------------------------------------------------------
-- lz4
--------------------------------------------------------------------------------

local lz4 = compress.lz4.new({
    acceleration = 4,
    decompress_buffer_size = 2 * 1024 * 1024,
})
---@type string
local l_packed = lz4:compress(payload)
---@type string
local l_unpacked = lz4:decompress(l_packed)
print(#l_packed, l_unpacked == payload)
