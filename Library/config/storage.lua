---@meta

---# Builtin `config.storage` submodule
---
---**⚠️ Enterprise Edition only.** Centralized configuration storages are supported by the [Tarantool Enterprise Edition](https://www.tarantool.io/compare/) only.
---
---*Since 3.0.0*
---
---The `config.storage` API allows you to interact with a Tarantool-based [centralized configuration storage](doc://configuration_etcd).
---@class config.storage
local storage = {}

---@class config.storage.put_result
---@field revision integer a revision after performing the operation

---@class config.storage.value_info
---@field path string a path
---@field mod_revision integer the last revision at which this value was modified
---@field value string a value

---@class config.storage.get_result
---@field data config.storage.value_info a table containing the information about the value
---@field revision integer a revision after performing the operation

---@class config.storage.info_result
---@field status 'connected' | 'disconnected' a connection status. `connected` if any instance from the quorum is available to the current instance; `disconnected` if the current instance doesn't have a connection with the quorum

---@class config.storage.txn_request
---@field predicates? table[] a list of predicates to check. Each predicate is a list `{target, operator, value[, path]}`
---@field on_success? table[] a list with operations to execute if all predicates in the list evaluate to `true`
---@field on_failure? table[] a list with operations to execute if any of a predicate evaluates to `false`

---@class config.storage.txn_data
---@field responses any[] the list of responses for all operations
---@field is_success boolean a boolean value indicating whether the predicate is evaluated to `true`

---@class config.storage.txn_result
---@field data config.storage.txn_data a table containing response data
---@field revision integer a revision after performing the operation

---Put a value by the specified path.
---
---@param path string a path to put the value by
---@param value string a value to put
---@return config.storage.put_result
function storage.put(path, value) end

---Get a value stored by the specified path or prefix.
---
---@param path string a path or prefix to get a value by; prefixes end with `/`
---@return config.storage.get_result
function storage.get(path) end

---Delete a value stored by the specified path or prefix.
---
---@param path string a path or prefix to delete the value by; prefixes end with `/`
---@return config.storage.get_result
function storage.delete(path) end

---Get information about an instance's connection state.
---
---@return config.storage.info_result
function storage.info() end

---Make an atomic request.
---
---@param request config.storage.txn_request a table describing the atomic request
---@return config.storage.txn_result
function storage.txn(request) end

return storage
