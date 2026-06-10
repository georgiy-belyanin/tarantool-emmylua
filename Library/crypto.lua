---@meta

---# Builtin `crypto` module
---
---"Crypto" is short for "Cryptography", which generally refers to the production
---of a digest value from a function (usually a
---[Cryptographic hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function)),
---applied against a string. Tarantool's `crypto` module supports ten types of
---cryptographic hash functions
---([AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard),
---[DES](https://en.wikipedia.org/wiki/Data_Encryption_Standard),
---[DSS](https://en.wikipedia.org/wiki/Payment_Card_Industry_Data_Security_Standard),
---[MD4](https://en.wikipedia.org/wiki/Md4),
---[MD5](https://en.wikipedia.org/wiki/Md5),
---[MDC2](https://en.wikipedia.org/wiki/MDC-2),
---[RIPEMD](http://homes.esat.kuleuven.be/~bosselae/ripemd160.html),
---[SHA-1](https://en.wikipedia.org/wiki/Sha-1),
---[SHA-2](https://en.wikipedia.org/wiki/Sha-2)).
---Some of the crypto functionality is also present in the
---[digest](doc://digest) module.
---@class crypto
---@field cipher crypto.cipher Encrypt and decrypt strings using cipher algorithms.
---@field digest crypto.digest Get a digest derived from a string.
---@field hmac crypto.hmac Get an HMAC message authentication code derived from a key and a string.
local crypto = {}

--------------------------------------------------------------------------------
-- crypto.cipher
--------------------------------------------------------------------------------

---An incremental cipher object created by a `crypto.cipher.{algorithm}.{cipher_mode}.encrypt.new()`
---or `crypto.cipher.{algorithm}.{cipher_mode}.decrypt.new()` call.
---
---Suppose that a cipher is done for a string `'A'`, then a new part `'B'` is appended
---to the string, then a new cipher is required. The new cipher could be recomputed
---for the whole string `'AB'`, but it is faster to take what was computed before for
---`'A'` and apply changes based on the new part `'B'`. This is called multi-step or
---"incremental" digesting, which Tarantool supports for all crypto functions.
---
---**Example:**
---
--- ```lua
--- crypto = require('crypto')
---
--- -- print aes-192 digest of 'AB', with one step, then incrementally
--- key = 'key/key/key/key/key/key/'
--- iv =  'iviviviviviviviv'
--- print(crypto.cipher.aes192.cbc.encrypt('AB', key, iv))
--- c = crypto.cipher.aes192.cbc.encrypt.new(key)
--- c:init(nil, iv)
--- c:update('A')
--- c:update('B')
--- print(c:result())
--- c:free()
--- ```
---@class crypto.cipher.stream
local cipher_stream = {}

---Initialize the incremental cipher object.
---
---@param key? string secret key
---@param initialization_vector? string initialization vector
function cipher_stream:init(key, initialization_vector) end

---Add a new part to the data being ciphered incrementally.
---
---@param data string the next part of the data to be ciphered
function cipher_stream:update(data) end

---Get the result of the incremental cipher.
---
---@return string result the ciphered data
function cipher_stream:result() end

---Free the resources held by the incremental cipher object.
function cipher_stream:free() end

---A `crypto.cipher.{algorithm}.{cipher_mode}.encrypt` or
---`crypto.cipher.{algorithm}.{cipher_mode}.decrypt` codec.
---
---Calling it ciphers a string in one step. The [new()](lua://crypto.cipher.codec.new)
---field provides an incremental ([crypto.cipher.stream](lua://crypto.cipher.stream))
---alternative.
---@class crypto.cipher.codec
---@field new fun(key?: string): crypto.cipher.stream Create an incremental cipher object.
---@overload fun(string: string, key: string, initialization_vector?: string): string
local cipher_codec = {}

---A cipher mode (`cbc`, `cfb`, `ecb`, or `ofb`) of a cipher algorithm.
---@class crypto.cipher.mode
---@field encrypt crypto.cipher.codec Encrypt a string.
---@field decrypt crypto.cipher.codec Decrypt a string.

---A cipher algorithm (`aes128`, `aes192`, `aes256`, or `des`).
---@class crypto.cipher.algorithm
---@field cbc crypto.cipher.mode Cipher Block Chaining mode.
---@field cfb crypto.cipher.mode Cipher Feedback mode.
---@field ecb crypto.cipher.mode Electronic Codebook mode.
---@field ofb crypto.cipher.mode Output Feedback mode.

---Pass or return a cipher derived from the string, key, and (optionally,
---sometimes) initialization vector. The four choices of algorithms:
---
---* aes128 - aes-128 (with 192-bit binary strings using AES)
---* aes192 - aes-192 (with 192-bit binary strings using AES)
---* aes256 - aes-256 (with 256-bit binary strings using AES)
---* des    - des (with 56-bit binary strings using DES, though DES is not
---  recommended)
---
---Four choices of block cipher modes are also available:
---
---* cbc - Cipher Block Chaining
---* cfb - Cipher Feedback
---* ecb - Electronic Codebook
---* ofb - Output Feedback
---
---For more information, read the article about
---[Encryption Modes](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation)
---
---**Example:**
---
--- ```lua
--- _16byte_iv='1234567890123456'
--- _16byte_pass='1234567890123456'
--- e=crypto.cipher.aes128.cbc.encrypt('string', _16byte_pass, _16byte_iv)
--- crypto.cipher.aes128.cbc.decrypt(e,  _16byte_pass, _16byte_iv)
--- ```
---@class crypto.cipher
---@field aes128 crypto.cipher.algorithm aes-128 (with 192-bit binary strings using AES)
---@field aes192 crypto.cipher.algorithm aes-192 (with 192-bit binary strings using AES)
---@field aes256 crypto.cipher.algorithm aes-256 (with 256-bit binary strings using AES)
---@field des crypto.cipher.algorithm des (with 56-bit binary strings using DES, though DES is not recommended)

--------------------------------------------------------------------------------
-- crypto.digest
--------------------------------------------------------------------------------

---An incremental digest object created by a `crypto.digest.{algorithm}.new()` call.
---
---Suppose that a digest is done for a string `'A'`, then a new part `'B'` is appended
---to the string, then a new digest is required. The new digest could be recomputed
---for the whole string `'AB'`, but it is faster to take what was computed before for
---`'A'` and apply changes based on the new part `'B'`. This is called multi-step or
---"incremental" digesting, which Tarantool supports for all crypto functions.
---
---**Example:**
---
--- ```lua
--- crypto = require('crypto')
---
--- -- print sha-256 digest of 'AB', with one step, then incrementally
--- print(crypto.digest.sha256('AB'))
--- c = crypto.digest.sha256.new()
--- c:init()
--- c:update('A')
--- c:update('B')
--- print(c:result())
--- c:free()
--- ```
---@class crypto.digest.stream
local digest_stream = {}

---Initialize the incremental digest object.
function digest_stream:init() end

---Add a new part to the data being digested incrementally.
---
---@param data string the next part of the data to be digested
function digest_stream:update(data) end

---Get the result of the incremental digest.
---
---@return string result the digest
function digest_stream:result() end

---Free the resources held by the incremental digest object.
function digest_stream:free() end

---A `crypto.digest.{algorithm}` function.
---
---Calling it returns a digest of a string in one step. The
---[new()](lua://crypto.digest.fun.new) field provides an incremental
---([crypto.digest.stream](lua://crypto.digest.stream)) alternative.
---@class crypto.digest.fun
---@field new fun(): crypto.digest.stream Create an incremental digest object.
---@overload fun(string: string): string
local digest_fun = {}

---Pass or return a digest derived from the string. The eleven
---algorithm choices:
---
---* dss - dss (using DSS)
---* dss1 - dss (using DSS-1)
---* md4 - md4 (with 128-bit binary strings using MD4)
---* md5 - md5 (with 128-bit binary strings using MD5)
---* mdc2 - mdc2 (using MDC2)
---* ripemd160 - ripemd (with 160-bit binary strings using RIPEMD-160)
---* sha1 - sha-1 (with 160-bit binary strings using SHA-1)
---* sha224 - sha-224 (with 224-bit binary strings using SHA-2)
---* sha256 - sha-256 (with 256-bit binary strings using SHA-2)
---* sha384 - sha-384 (with 384-bit binary strings using SHA-2)
---* sha512 - sha-512(with 512-bit binary strings using SHA-2).
---
---**Example:**
---
--- ```lua
--- crypto.digest.md4('string')
--- crypto.digest.sha512('string')
--- ```
---@class crypto.digest
---@field dss crypto.digest.fun dss (using DSS)
---@field dss1 crypto.digest.fun dss (using DSS-1)
---@field md4 crypto.digest.fun md4 (with 128-bit binary strings using MD4)
---@field md5 crypto.digest.fun md5 (with 128-bit binary strings using MD5)
---@field mdc2 crypto.digest.fun mdc2 (using MDC2)
---@field ripemd160 crypto.digest.fun ripemd (with 160-bit binary strings using RIPEMD-160)
---@field sha1 crypto.digest.fun sha-1 (with 160-bit binary strings using SHA-1)
---@field sha224 crypto.digest.fun sha-224 (with 224-bit binary strings using SHA-2)
---@field sha256 crypto.digest.fun sha-256 (with 256-bit binary strings using SHA-2)
---@field sha384 crypto.digest.fun sha-384 (with 384-bit binary strings using SHA-2)
---@field sha512 crypto.digest.fun sha-512 (with 512-bit binary strings using SHA-2)

--------------------------------------------------------------------------------
-- crypto.hmac
--------------------------------------------------------------------------------

---Pass a key and a string. The result is an
---[HMAC](https://en.wikipedia.org/wiki/HMAC)
---message authentication code. The eight
---algorithm choices:
---
---* md4 or md4_hex - md4 (with 128-bit binary strings using MD4)
---* md5 or md5_hex - md5 (with 128-bit binary strings using MD5)
---* ripemd160 or ripemd160_hex - ripemd (with 160-bit binary strings using RIPEMD-160)
---* sha1 or sha1_hex - sha-1 (with 160-bit binary strings using SHA-1)
---* sha224 or sha224_hex - sha-224 (with 224-bit binary strings using SHA-2)
---* sha256 or sha256_hex - sha-256 (with 256-bit binary strings using SHA-2)
---* sha384 or sha384_hex - sha-384 (with 384-bit binary strings using SHA-2)
---* sha512 or sha512_hex - sha-512(with 512-bit binary strings using SHA-2).
---
---**Example:**
---
--- ```lua
--- crypto.hmac.md4('key', 'string')
--- crypto.hmac.md4_hex('key', 'string')
--- ```
---@class crypto.hmac
---@field md4 fun(key: string, string: string): string md4 (with 128-bit binary strings using MD4)
---@field md4_hex fun(key: string, string: string): string md4 (with 128-bit binary strings using MD4), hexadecimal result
---@field md5 fun(key: string, string: string): string md5 (with 128-bit binary strings using MD5)
---@field md5_hex fun(key: string, string: string): string md5 (with 128-bit binary strings using MD5), hexadecimal result
---@field ripemd160 fun(key: string, string: string): string ripemd (with 160-bit binary strings using RIPEMD-160)
---@field ripemd160_hex fun(key: string, string: string): string ripemd (with 160-bit binary strings using RIPEMD-160), hexadecimal result
---@field sha1 fun(key: string, string: string): string sha-1 (with 160-bit binary strings using SHA-1)
---@field sha1_hex fun(key: string, string: string): string sha-1 (with 160-bit binary strings using SHA-1), hexadecimal result
---@field sha224 fun(key: string, string: string): string sha-224 (with 224-bit binary strings using SHA-2)
---@field sha224_hex fun(key: string, string: string): string sha-224 (with 224-bit binary strings using SHA-2), hexadecimal result
---@field sha256 fun(key: string, string: string): string sha-256 (with 256-bit binary strings using SHA-2)
---@field sha256_hex fun(key: string, string: string): string sha-256 (with 256-bit binary strings using SHA-2), hexadecimal result
---@field sha384 fun(key: string, string: string): string sha-384 (with 384-bit binary strings using SHA-2)
---@field sha384_hex fun(key: string, string: string): string sha-384 (with 384-bit binary strings using SHA-2), hexadecimal result
---@field sha512 fun(key: string, string: string): string sha-512 (with 512-bit binary strings using SHA-2)
---@field sha512_hex fun(key: string, string: string): string sha-512 (with 512-bit binary strings using SHA-2), hexadecimal result

return crypto
