---@meta

---# Builtin `digest` module
---
---A "digest" is a value which is returned by a function (usually a
---[Cryptographic hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function)),
---applied against a string. Tarantool's `digest`
---module supports several types of cryptographic hash functions (
---[AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard),
---[MD4](https://en.wikipedia.org/wiki/Md4),
---[MD5](https://en.wikipedia.org/wiki/Md5),
---[SHA-1](https://en.wikipedia.org/wiki/Sha-1),
---[SHA-2](https://en.wikipedia.org/wiki/Sha-2),
---[PBKDF2](https://en.wikipedia.org/wiki/PBKDF2))
---as well as a checksum function ([CRC32](https://en.wikipedia.org/wiki/Cyclic_redundancy_check)), two
---functions for [base64](https://en.wikipedia.org/wiki/Base64), and two non-cryptographic hash functions
---([guava](https://code.google.com/p/guava-libraries/wiki/HashingExplained),
---[murmur](https://en.wikipedia.org/wiki/MurmurHash)).
---Some of the digest functionality is also present in the [crypto](doc://crypto).
---
---## Incremental methods in the `digest` module
---
---Suppose that a digest is done for a string 'A', then a new part 'B' is appended
---to the string, then a new digest is required. The new digest could be recomputed
---for the whole string 'AB', but it is faster to take what was computed before for
---'A' and apply changes based on the new part 'B'. This is called multi-step or
---"incremental" digesting, which Tarantool supports with crc32 and with murmur...
---
--- ```lua
--- digest = require('digest')
---
--- -- print crc32 of 'AB', with one step, then incrementally
--- print(digest.crc32('AB'))
--- c = digest.crc32.new()
--- c:update('A')
--- c:update('B')
--- print(c:result())
---
--- -- print murmur hash of 'AB', with one step, then incrementally
--- print(digest.murmur('AB'))
--- m = digest.murmur.new()
--- m:update('A')
--- m:update('B')
--- print(m:result())
--- ```
---
---## Example
---
---In the following example, the user creates two functions, `password_insert()`
---which inserts a [SHA-1](https://en.wikipedia.org/wiki/Sha-1) digest of the word "**^S^e^c^ret Wordpass**" into a tuple
---set, and `password_check()` which requires input of a password.
---
--- ```tarantoolsession
--- tarantool> digest = require('digest')
--- ---
--- ...
--- tarantool> function password_insert()
---          >   box.space.tester:insert{1234, digest.sha1('^S^e^c^ret Wordpass')}
---          >   return 'OK'
---          > end
--- ---
--- ...
--- tarantool> function password_check(password)
---          >   local t = box.space.tester:select{12345}
---          >   if digest.sha1(password) == t[2] then
---          >     return 'Password is valid'
---          >   else
---          >     return 'Password is not valid'
---          >   end
---          > end
--- ---
--- ...
--- tarantool> password_insert()
--- ---
--- - 'OK'
--- ...
--- ```
---
---If a later user calls the `password_check()` function and enters the wrong
---password, the result is an error.
---
--- ```tarantoolsession
--- tarantool> password_check('Secret Password')
--- ---
--- - 'Password is not valid'
--- ...
--- ```
local digest = {}

---@class digest.aes256cbc
digest.aes256cbc = {}

---Returns 256-bit binary string = digest made with AES.
---
---@param string string
---@param key string
---@param iv string
---@return string
function digest.aes256cbc.encrypt(string, key, iv) end

---Returns 256-bit binary string = digest made with AES.
---
---@param string string
---@param key string
---@param iv string
---@return string
function digest.aes256cbc.decrypt(string, key, iv) end

---Returns 128-bit binary string = digest made with MD4.
---
---@param string string
---@return string
function digest.md4(string) end

---Returns 32-byte string = hexadecimal of a digest calculated with md4.
---
---@param string string
---@return string
function digest.md4_hex(string) end

---Returns 128-bit binary string = digest made with MD5.
---
---@param string string
---@return string
function digest.md5(string) end

---Returns 32-byte string = hexadecimal of a digest calculated with md5.
---
---@param string string
---@return string
function digest.md5_hex(string) end

---Returns binary string = digest made with PBKDF2.
---
---For effective encryption the `iterations` value should be
---at least several thousand. The `digest-length` value
---determines the length of the resulting binary string.
---
---**Note:**
---
---`digest.pbkdf2()` yields and should not be used in a transaction (between
---`box.begin()` and `box.commit()`/`box.rollback()`).
---PBKDF2 is a time-consuming hash algorithm. It runs in a separate coio thread.
---While calculations are performed, the fiber that calls `digest.pbkdf2()`
---yields and another fiber continues working in the tx thread.
---
---@async
---@param string string
---@param salt string
---@param iterations? integer
---@param digest_length? integer
---@return string
function digest.pbkdf2(string, salt, iterations, digest_length) end

---Returns 160-bit binary string = digest made with SHA-1.
---
---@param string string
---@return string
function digest.sha1(string) end

---Returns 40-byte string = hexadecimal of a digest calculated with sha1.
---
---@param string string
---@return string
function digest.sha1_hex(string) end

---Returns 224-bit binary string = digest made with SHA-2.
---
---@param string string
---@return string
function digest.sha224(string) end

---Returns 56-byte string = hexadecimal of a digest calculated with sha224.
---
---@param string string
---@return string
function digest.sha224_hex(string) end

---Returns 256-bit binary string =  digest made with SHA-2.
---
---@param string string
---@return string
function digest.sha256(string) end

---Returns 64-byte string = hexadecimal of a digest calculated with sha256.
---
---@param string string
---@return string
function digest.sha256_hex(string) end

---Returns 384-bit binary string =  digest made with SHA-2.
---
---@param string string
---@return string
function digest.sha384(string) end

---Returns 96-byte string = hexadecimal of a digest calculated with sha384.
---
---@param string string
---@return string
function digest.sha384_hex(string) end

---Returns 512-bit binary string = digest made with SHA-2.
---
---@param string string
---@return string
function digest.sha512(string) end

---Returns 128-byte string = hexadecimal of a digest calculated with sha512.
---
---@param string string
---@return string
function digest.sha512_hex(string) end

---@class digest.base64_options
---@field nopad? boolean result must not include '=' for padding at the end
---@field nowrap? boolean result must not include line feed for splitting lines after 72 characters
---@field urlsafe? boolean result must not include '=' or line feed, and may contain '-' or '_' instead of '+' or '/' for positions 62 and 63 in the index table

---Returns base64 encoding from a regular string.
---
---The possible options are:
---
---* `nopad` -- result must not include '=' for padding at the end,
---* `nowrap` -- result must not include line feed for splitting lines
---  after 72 characters,
---* `urlsafe` -- result must not include '=' or line feed, and may contain
---  '-' or '_' instead of '+' or '/' for positions 62 and 63 in the index
---  table.
---
---Options may be `true` or `false`, the default value is `false`.
---
---For example:
---
--- ```lua
--- digest.base64_encode(string_variable,{nopad=true})
--- ```
---
---@param string string
---@param options? digest.base64_options
---@return string
function digest.base64_encode(string, options) end

---Returns a regular string from a base64 encoding.
---
---@param string string
---@return string
function digest.base64_decode(string) end

---Returns array of random bytes with length = integer.
---
---@param integer integer
---@return string
function digest.urandom(integer) end

---@class digest.crc32.object
local crc32_object = {}

---Add a new part to the string being checksummed incrementally.
---
---@param string string
function crc32_object:update(string) end

---Get the resulting 32-bit checksum of the incrementally checksummed string.
---
---@return number
function crc32_object:result() end

---Returns 32-bit checksum made with CRC32.
---
---The `crc32` and `crc32_update` functions use the
---[Cyclic Redundancy Check](https://en.wikipedia.org/wiki/Cyclic_redundancy_check)
---polynomial value: `0x1EDC6F41` / `4812730177`.
---(Other settings are: input = reflected, output = reflected, initial value = 0xFFFFFFFF, final xor value = 0x0.)
---If it is necessary to be
---compatible with other checksum functions in other programming languages,
---ensure that the other functions use the same polynomial value.
---
---For example, in Python, install the `crcmod` package and say:
---
--- ```python
--- >>> import crcmod
--- >>> fun = crcmod.mkCrcFun('4812730177')
--- >>> fun('string')
--- 3304160206L
--- ```
---
---In Perl, install the `Digest::CRC` module and run the following code:
---
--- ```perl
--- use Digest::CRC;
--- $d = Digest::CRC->new(width => 32, poly => 0x1EDC6F41, init => 0xFFFFFFFF, refin => 1, refout => 1);
--- $d->add('string');
--- print $d->digest;
--- ```
---
---(the expected output is 3304160206).
---
---@class digest.crc32
---@overload fun(input: string): number
digest.crc32 = {}

---Initiates incremental crc32.
---See [incremental methods](lua://digest) notes.
---
---@return digest.crc32.object
function digest.crc32.new() end

---Returns a number made with consistent hash.
---
---The guava function uses the [Consistent Hashing](https://en.wikipedia.org/wiki/Consistent_hashing)
---algorithm of the Google
---guava library. The first parameter should be a hash code; the second
---parameter should be the number of buckets; the returned value will be an
---integer between 0 and the number of buckets. For example,
---
--- ```tarantoolsession
--- tarantool> digest.guava(10863919174838991, 11)
--- ---
--- - 8
--- ...
--- ```
---
---@param state number
---@param bucket number
---@return integer
function digest.guava(state, bucket) end

---@class digest.murmur.object
local murmur_object = {}

---Add a new part to the string being hashed incrementally.
---
---@param string string
function murmur_object:update(string) end

---Get the resulting MurmurHash digest of the incrementally hashed string.
---
---@return string
function murmur_object:result() end

---@class digest.murmur.new_options
---@field seed? integer

---Returns 32-bit binary string = digest made with MurmurHash.
---
---@class digest.murmur
---@overload fun(input: string): string
digest.murmur = {}

---Initiates incremental MurmurHash.
---See [incremental methods](lua://digest) notes.
---For example:
---
--- ```lua
--- murmur.new({seed=0})
--- ```
---
---@param opts? digest.murmur.new_options
---@return digest.murmur.object
function digest.murmur.new(opts) end

return digest
