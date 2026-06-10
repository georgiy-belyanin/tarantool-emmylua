---@meta

---# Rock `membership`
---
---This module is a `membership` library for Tarantool based on a gossip protocol.
---
---This library builds a mesh from multiple Tarantool instances. The mesh monitors itself, helps members
---discover everyone else in the group and get notified about their status changes with low latency.
---It is built upon the ideas from Consul or, more precisely, the SWIM algorithm.
---
---The `membership` module works over UDP protocol and can operate even before the `box.cfg` initialization.
local membership = {}

---@alias membership.status
---| "alive" # a member that replies to ping-messages is `alive` and well.
---| "suspect" # if any member in the group cannot get a reply from another member, the latter becomes a `suspect`.
---| "dead" # a `suspect` becomes `dead` after a timeout.
---| "left" # a member gets the `left` status after executing the `leave()` function.
---| "non-decryptable" # a member that cannot be decrypted with the configured encryption key.

---A member is represented by a table with the following fields.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> membership.myself()
--- ---
--- uri: localhost:33001
--- status: alive
--- incarnation: 1
--- payload:
---     uuid: 2d00c500-2570-4019-bfcc-ab25e5096b73
--- timestamp: 1522427330993752
--- ...
--- ```
---
---@class membership.member
---@field uri string a Uniform Resource Identifier.
---@field status membership.status the current status of the member.
---@field incarnation number a value incremented every time the instance becomes a `suspect`, `dead`, or updates its payload.
---@field payload table auxiliary data that can be used by various modules.
---@field timestamp number a value of `fiber.time64()` corresponding to the last update of `status` or `incarnation`. It is always local and does not depend on other members' clock setting.

--------------------------------------------------------------------------------
-- Common functions
--------------------------------------------------------------------------------

---Initialize the `membership` module.
---
---This binds a UDP socket to `0.0.0.0:<port>`, sets the `advertise_uri` parameter to
---`<advertise_host>:<port>`, and `incarnation` to `1`.
---
---The `init()` function can be called several times, the old socket will be closed and a new one opened.
---
---If the `advertise_uri` changes during the next `init()`, the old URI is considered `DEAD`. In order to
---leave the group gracefully, use the [`leave()`](lua://membership.leave) function.
---
---@param advertise_host string a hostname or IP address to advertise to other members
---@param port number a UDP port to bind
---@return boolean # `true`
function membership.init(advertise_host, port) end

---Get the [member data structure](lua://membership.member) of the current instance.
---
---@return membership.member
function membership.myself() end

---Get the [member data structure](lua://membership.member) for a given URI.
---
---@param uri string the given member's `advertise_uri`
---@return membership.member
function membership.get_member(uri) end

---Obtain all members known to the current instance.
---
---Editing this table has no effect.
---
---@return table<string, membership.member> # a table with URIs as keys and corresponding member data structures as values
function membership.members() end

---A shorthand for `pairs(membership.members())`.
---
---It can be used in the following way:
---
--- ```lua
--- for uri, member in membership.pairs() do
---     -- do something
--- end
--- ```
---
---@return fun(): string, membership.member # a Lua iterator
function membership.pairs() end

---Add a member with the given URI to the group and propagate this event to other members.
---
---Adding a member to a single instance is enough as everybody else in the group will receive the update
---with time. It does not matter who adds whom.
---
---@param uri string the `advertise_uri` of the member to add
---@return boolean? # `true`, or `nil` in case of an error
function membership.add_member(uri) end

---Send a message to a member to make sure it is in the group.
---
---If the member is `alive` but not in the group, it is added. If it already is in the group, nothing happens.
---
---@param uri string the `advertise_uri` of the member to ping
---@return boolean # `true` if the member responds within 0.2 seconds, otherwise `no response`
function membership.probe_uri(uri) end

---Discover members in the local network by sending a UDP broadcast message to all networks discovered
---by a `getifaddrs()` C call.
---
---@return boolean # `true` if the broadcast was sent, `false` if `getaddrinfo()` fails
function membership.broadcast() end

---Update `myself().payload` and disseminate it along with the member status.
---
---Increments `incarnation`.
---
---@param key string a key to set in the payload table
---@param value any auxiliary data
---@return boolean # `true`
function membership.set_payload(key, value) end

---Gracefully leave the `membership` group.
---
---The node will be marked with the `left` status and no other members will ever try to reconnect it.
---
---@return boolean # `true`
function membership.leave() end

---Check whether encryption is enabled.
---
---@return boolean # `true` if encryption is enabled, `false` otherwise
function membership.is_encrypted() end

--------------------------------------------------------------------------------
-- Encryption functions
--------------------------------------------------------------------------------

---Set the key used for low-level message encryption.
---
---The key is either trimmed or padded automatically to be exactly 32 bytes. If the `key` value is `nil`,
---the encryption is disabled.
---
---The encryption is handled by the `crypto.cipher.aes256.cbc` Tarantool module.
---
---For proper communication, all members must be configured to use the same encryption key. Otherwise,
---members report either `dead` or `non-decryptable` in their status.
---
---@param key string? encryption key
function membership.set_encryption_key(key) end

---Retrieve the encryption key that is currently in use.
---
---@return string? # the encryption key, or `nil` if the encryption is disabled
function membership.get_encryption_key() end

--------------------------------------------------------------------------------
-- Subscription functions
--------------------------------------------------------------------------------

---Subscribe for updates in the members table.
---
---@return fiber.cond # a `fiber.cond` object broadcasted whenever the members table changes
function membership.subscribe() end

---Remove the subscription on `cond` obtained by the [`subscribe()`](lua://membership.subscribe) function.
---
---The `cond`'s validity is not checked.
---
---@param cond fiber.cond the `fiber.cond` object obtained from `subscribe()`
function membership.unsubscribe(cond) end

return membership
