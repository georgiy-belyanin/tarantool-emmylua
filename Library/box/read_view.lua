---@meta

---# Builtin `box.read_view` submodule
---
---The `box.read_view` submodule contains functions related to read views.
box.read_view = {}

---@class box.read_view.object
---An object that represents a [read view](doc://read_views).
---@field status 'open' | 'closed' A read view status. The possible values are `open` and `closed`.
---@field id number A unique numeric identifier of a read view.
---@field name string A read view name. You can specify a read view name in the [box.read_view.open()](lua://box.read_view.open) arguments.
---@field is_system boolean Determine whether a read view is system. For example, system read views can be created to make a [checkpoint](doc://book_cfg_checkpoint_daemon) or join a new [replica](doc://replication-architecture).
---@field timestamp number The [fiber.clock()](lua://fiber.clock) value at the moment of opening a read view.
---@field vclock table The [box.info.vclock](lua://box.info.vclock) value at the moment of opening a read view.
---@field signature number The [box.info.signature](lua://box.info.signature) value at the moment of opening a read view.
---@field space box.spaces Get access to database spaces included in a read view. You can use this field to [query space data](doc://querying_data).
local read_view_object = {}

---Get information about a read view such as a name, status, or ID.
---
---All the available fields are listed below in the object options.
---
---@return table info information about a read view
function read_view_object:info() end

---Close a read view.
---
---After the read view is closed, its [status](lua://box.read_view.object.status) is set to `closed`.
---On an attempt to use it, an error is raised.
---
function read_view_object:close() end

---@class box.read_view.open_options
---@field name? string A read view name. If `name` is not specified, a read view name is set to `unknown`.

---Create a [new read view](doc://creating_read_view).
---
---**⚠️ Enterprise Edition only.** This API is available in the [Tarantool Enterprise Edition](https://www.tarantool.io/compare/) only.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> read_view1 = box.read_view.open({name = 'read_view1'})
--- ```
---
---@param opts? box.read_view.open_options (optional) configurations options for a read view. For example, the `name` option specifies a read view name. If `name` is not specified, a read view name is set to `unknown`.
---@return box.read_view.object read_view a created read view object
function box.read_view.open(opts) end

---Return an array of all active database read views.
---
---This array might include the following read view types:
---
---*   [read views](doc://read_views) created by application code (Enterprise Edition only)
---
---*   system read views (used, for example, to make a [checkpoint](doc://book_cfg_checkpoint_daemon)
---    or join a new [replica](doc://replication-architecture))
---
---Read views created by application code also have the `space` field.
---The field lists all spaces available in a read view,
---and may be used like a read view object returned by `box.read_view.open()`.
---
---**Note:**
---
---`read_view.list()` also contains read views created using the
---[C API](doc://read_views_c_api) ([box_raw_read_view_new()](doc://box_raw_read_view_new)).
---Note that you cannot access database spaces included in such views from Lua.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> box.read_view.list()
--- ---
--- - - timestamp: 1138.98706933
---     signature: 47
---     is_system: false
---     status: open
---     vclock: &0 {1: 47}
---     name: read_view1
---     id: 1
---   - timestamp: 1172.202995842
---     signature: 49
---     is_system: false
---     status: open
---     vclock: &1 {1: 49}
---     name: read_view2
---     id: 2
--- ...
--- ```
---
---@return box.read_view.object[] read_views an array of all active database read views
function box.read_view.list() end

return box.read_view
