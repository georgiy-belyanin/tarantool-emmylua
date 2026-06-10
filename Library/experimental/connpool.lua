---@meta

---# Builtin `experimental.connpool` submodule
---
---*Since 3.1.0*
---
---**Important**: `experimental.connpool` is an experimental module and is subject to changes.
---
---The `experimental.connpool` module provides a set of features for connecting to remote cluster instances and for executing remote procedure calls on an instance that satisfies the specified criteria.
---
---**Note**: Note that the execution time for `experimental.connpool` functions depends on the number of instances and the time required to connect to each instance.
---
---To load the `experimental.connpool` module, use the `require()` directive:
---
--- ```lua
--- local connpool = require('experimental.connpool')
--- ```
local connpool = {}

---@alias connpool.mode
---| 'ro' # consider only read-only instances.
---| 'rw' # consider only read-write instances.
---| 'prefer_ro' # consider read-only instances, then read-write instances.
---| 'prefer_rw' # consider read-write instances, then read-only instances.

---@class connpool.call_options
---@field labels? table the [labels](doc://configuration_reference_labels) an instance has.
---@field roles? string[] the [roles](doc://configuration_application_roles) of an instance.
---@field prefer_local? boolean whether to prefer a local or remote instance to execute `call()` on: if `true` (default), `call()` tries to execute the specified function on a local instance. If `false`, `call()` tries to connect to a random candidate until a connection is established.
---@field mode? connpool.mode a mode that allows filtering candidates based on their read-only status. If `nil` (default), don't check the read-only status of instances.
---@field instances? string[] the names of instances to consider as candidates.
---@field replicasets? string[] the names of replica sets whose instances are considered as candidates.
---@field groups? string[] the names of groups whose instances are considered as candidates.
---@field timeout? number a connection timeout (in seconds).
---@field buffer? buffer a [buffer](lua://buffer) used to read a returned value.
---@field on_push? fun(ctx: any, msg: any) a function to execute when the client receives an out-of-band message. Learn more from [box_session-push](doc://box_session-push).
---@field on_push_ctx? any an argument of the function executed when the client receives an out-of-band message. Learn more from [box_session-push](doc://box_session-push).
---@field is_async? boolean whether to wait for the result of the call.

---Execute the specified function on a remote instance.
---
---**Note**: The function is executed on behalf of the user that maintains replication in the cluster. Ensure that this user has the `execute` [permission](doc://configuration_credentials_managing_users_roles_granting_privileges) for the function to execute.
---
---**Example**
---
---In the example below, the following conditions are specified to choose an instance to execute the [vshard.storage.buckets_count](doc://storage_api-buckets_count) function:
---
---*   An instance has the `roles.crud-storage` role.
---*   An instance has the `dc` label set to `east`.
---*   An instance is read-only.
---
--- ```lua
--- local connpool = require('experimental.connpool')
--- local buckets_count = connpool.call('vshard.storage.buckets_count',
---         nil,
---         { roles = { 'roles.crud-storage' },
---           labels = { dc = 'east' },
---           mode = 'ro' }
--- )
--- ```
---
---@async
---@param func_name string a name of the function to execute.
---@param args? table function arguments.
---@param opts? connpool.call_options options used to select candidates on which the function should be executed.
---@return any ret a function's return value.
function connpool.call(func_name, args, opts) end

---@class connpool.connect_options
---@field connect_timeout? number a connection timeout (in seconds).
---@field wait_connected? boolean whether to block the connection until it is established: if `true` (default), the connection is blocked until it is established. If `false`, the connection is returned immediately.
---@field fetch_schema? boolean whether to fetch schema changes from a remote instance.

---Create a connection to the specified instance.
---
---**Example**
---
---In the example below, `connect()` is used to create the active connection to `storage-b-002`:
---
--- ```lua
--- local connpool = require('experimental.connpool')
--- local conn = connpool.connect("storage-b-002", { fetch_schema = true })
--- ```
---
---Once you have a connection, you can execute requests on the remote instance, for example, select data from a space using [conn.space.\<space-name\>:select()](doc://conn-select).
---
---@async
---@param instance_name string an instance name.
---@param opts? connpool.connect_options none, any, or all of the connection parameters.
---@return net.box.conn conn a [net.box](doc://net_box-module) connection.
function connpool.connect(instance_name, opts) end

---@class connpool.filter_options
---@field labels? table the [labels](doc://configuration_reference_labels) an instance has.
---@field roles? string[] the [roles](doc://configuration_application_roles) of an instance.
---@field mode? 'ro' | 'rw' a mode that allows filtering candidates based on their read-only status. If `nil` (default), don't check the read-only status of instances. `ro` -- consider only read-only instances. `rw` -- consider only read-write instances.
---@field instances? string[] the names of instances to consider as candidates.
---@field replicasets? string[] the names of replica sets whose instances are considered as candidates.
---@field groups? string[] the names of groups whose instances are considered as candidates.

---Get names of instances that match the specified conditions.
---
---**Example**
---
---In the example below, `filter()` should return a list of instances with the `roles.crud-storage` role and specified label value:
---
--- ```lua
--- local connpool = require('experimental.connpool')
--- local instance_names = connpool.filter({ roles = { 'roles.crud-storage' },
---                                          labels = { dc = 'east' } })
--- ```
---
---@async
---@param opts? connpool.filter_options none, any, or all of the filter parameters.
---@return string[] instance_names an array of instance names.
function connpool.filter(opts) end

return connpool
