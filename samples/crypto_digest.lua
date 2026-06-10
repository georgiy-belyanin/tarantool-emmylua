-- Theme: hashing and cryptography -- the `digest` and `crypto` modules.
-- Standalone-runnable (no box.cfg).

local digest = require('digest')
local crypto = require('crypto')

--------------------------------------------------------------------------------
-- digest: one-shot hashes
--------------------------------------------------------------------------------

local data = 'The Beatles'

---@type string
local _md4 = digest.md4_hex(data)
---@type string
local _md5 = digest.md5_hex(data)
---@type string
local _sha1 = digest.sha1_hex(data)
---@type string
local _sha256 = digest.sha256_hex(data)
---@type string
local _sha512 = digest.sha512_hex(data)

-- Raw (binary) digests.
local _md5_raw = digest.md5(data)
local _sha256_raw = digest.sha256(data)
print(_md4, _md5, _sha1, _sha256, _sha512, _md5_raw, _sha256_raw)

--------------------------------------------------------------------------------
-- digest: base64, urandom
--------------------------------------------------------------------------------

---@type string
local _b64 = digest.base64_encode('binary data')
---@type string
local _b64_opts = digest.base64_encode('binary data', { nopad = true, nowrap = true })
---@type string
local _unb64 = digest.base64_decode(_b64)
---@type string
local _rand = digest.urandom(16)
print(_b64, _b64_opts, _unb64, #_rand)

--------------------------------------------------------------------------------
-- digest: crc32 / murmur (callable + incremental object)
--------------------------------------------------------------------------------

-- One-shot call form.
---@type number
local _crc = digest.crc32('AB')
---@type string
local _mur = digest.murmur('AB')

-- Incremental form.
local crc = digest.crc32.new()
crc:update('A')
crc:update('B')
---@type number
local _crc_inc = crc:result()

local mur = digest.murmur.new({ seed = 13 })
mur:update('AB')
local _mur_inc = mur:result()

-- guava consistent hashing.
---@type integer
local _bucket = digest.guava(10863919174838991, 11)
print(_crc, _mur, _crc_inc, _mur_inc, _bucket)

--------------------------------------------------------------------------------
-- digest.aes256cbc symmetric cipher
--------------------------------------------------------------------------------

local key32 = string.rep('k', 32)
local iv16 = string.rep('v', 16)

---@type string
local _enc = digest.aes256cbc.encrypt('secret message', key32, iv16)
---@type string
local _dec = digest.aes256cbc.decrypt(_enc, key32, iv16)
print(_dec == 'secret message')

--------------------------------------------------------------------------------
-- crypto.cipher: AES with cipher modes (callable codecs + incremental streams)
--------------------------------------------------------------------------------

-- One-shot encrypt/decrypt via the callable codec.
---@type string
local _c_enc = crypto.cipher.aes256.cbc.encrypt('hello world', key32, iv16)
---@type string
local _c_dec = crypto.cipher.aes256.cbc.decrypt(_c_enc, key32, iv16)
print(_c_dec == 'hello world')

-- Incremental cipher stream.
local enc_stream = crypto.cipher.aes256.cbc.encrypt.new(key32)
enc_stream:init(key32, iv16)
local part1 = enc_stream:update('hello ')
local part2 = enc_stream:update('world')
local tail = enc_stream:result()
enc_stream:free()
print(part1, part2, tail)

--------------------------------------------------------------------------------
-- crypto.digest and crypto.hmac
--------------------------------------------------------------------------------

-- One-shot digest via the callable algorithm.
---@type string
local _cd = crypto.digest.sha256('hello world')

-- Incremental digest stream.
local dstream = crypto.digest.sha256.new()
dstream:update('hello ')
dstream:update('world')
local _cd_inc = dstream:result()

-- HMAC.
---@type string
local _hmac = crypto.hmac.sha256('secret-key', 'message')
---@type string
local _hmac_hex = crypto.hmac.sha256_hex('secret-key', 'message')
print(_cd, _cd_inc, _hmac, _hmac_hex)
