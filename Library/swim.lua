---@meta

---# Builtin `swim` module
---
---The `swim` module contains Tarantool's implementation of SWIM (Scalable Weakly-consistent Infection-style Process Group Membership Protocol).
---It is designed for large-scale Tarantool clusters to discover and monitor members, maintaining a "member table" through periodic UDP messages.
---
---SWIM avoids false positives by using indirect pings and maintains even network load regardless of cluster size.
---It supports anti-entropy for reliable member discovery, UUID-based identification, and optional payload/encryption features.
local swim = {}

---@alias swim.uuid string | cdata -- UUID as string or cdata struct tt_uuid
---@alias swim.uri string | number -- URI as 'ip:port' string or port number

---@class swim.cfg
---@field heartbeat_rate? number -- Rate of sending round messages, in seconds. Default = 1.
---@field ack_timeout? number -- Time in seconds after which a ping is unacknowledged. Default = 30.
---@field gc_mode? string -- Dead member collection mode: 'off' or 'on'. Default = 'on'.
---@field uri? swim.uri -- IP:port address or port number (127.0.0.1 assumed if IP omitted).
---@field uuid? swim.uuid -- Unique identifier among SWIM instances.

---@class swim.codec_cfg
---@field algo string -- Encryption algorithm: 'aes128', 'aes192', 'aes256', 'des', or 'none'.
---@field mode? string -- Encryption mode: 'ecb', 'cbc', 'cfb', 'ofb'. Default = 'cbc'.
---@field key string | cdata -- Private secret key.
---@field key_size? integer -- Key size in bytes (mandatory if key is cdata).

---@class swim.member_event
---@field is_new fun(self): boolean -- Returns true if member is new.
---@field is_drop fun(self): boolean -- Returns true if member is dropped.
---@field is_update fun(self): boolean -- Returns true if member is updated.
---@field is_new_status fun(self): boolean -- Returns true if status changed.
---@field is_new_uri fun(self): boolean -- Returns true if URI changed.
---@field is_new_incarnation fun(self): boolean -- Returns true if incarnation changed.
---@field is_new_generation fun(self): boolean -- Returns true if generation part changed.
---@field is_new_version fun(self): boolean -- Returns true if version part changed.
---@field is_new_payload fun(self): boolean -- Returns true if payload changed.

---@class swim.incarnation
---@field generation integer -- Persistent part (microseconds since epoch by default).
---@field version integer -- Volatile part (increments on changes).

---@class swim.member_object
---@field status fun(self): string -- Returns status: 'alive', 'suspected', 'left', or 'dead'.
---@field uuid fun(self): cdata -- Returns UUID as cdata struct tt_uuid.
---@field uri fun(self): string -- Returns URI as 'ip:port' string.
---@field incarnation fun(self): swim.incarnation -- Returns incarnation object.
---@field payload_cdata fun(self): cdata, integer -- Returns payload pointer and size in bytes.
---@field payload_str fun(self): string | nil -- Returns payload as string, or nil if no payload.
---@field payload fun(self): any | nil -- Returns decoded payload (as Lua object if MessagePack), or nil if no payload.
---@field is_dropped fun(self): boolean -- Returns true if member is dropped from table.

---The read-only configuration table of a SWIM instance.
---
---It is also callable to configure or reconfigure the instance:
---`swim_object:cfg({heartbeat_rate = 0.5})`. All components are dynamic and can be
---set multiple times. The first call requires `uri` and `uuid`.
---
---@class swim.object.cfg: swim.cfg
---@overload fun(self: swim.object, cfg: swim.cfg): boolean?, string -- true on success, or nil + error message on failure

---@class swim.object
---@field cfg swim.object.cfg -- Read-only configuration table, also callable to reconfigure the instance.
local swim_object = {}

---Delete a SWIM instance immediately.
---
---Memory is freed, member table entry is deleted, and instance becomes unusable.
---
---**Example:** `swim_object:delete()`
---
function swim_object:delete() end

---Check if SWIM instance is configured.
---
---Returns false if created without `cfg` and not yet configured with `:cfg()`.
---
---**Example:** `swim_object:is_configured()`
---
---@return boolean
function swim_object:is_configured() end

---Return the size of the member table (at least 1, including self).
---
---**Example:** `swim_object:size()`
---
---@return integer
function swim_object:size() end

---
---Gracefully leave the cluster.
---
---Sends 'left' message to all members before deletion. Instance becomes unusable afterward.
---
---**Example:** `swim_object:quit()`
---
function swim_object:quit() end

---Explicitly add a member into the member table.
---
---Useful for bootstrapping when joining a cluster.
---
---**Example:**
--- ```lua
--- swim.member_object = swim_object:add_member({uuid = ..., uri = ...})
--- ```
---
---@param cfg table -- Must contain `uuid` and `uri`
---@return boolean | nil, string -- true on success, or nil + error message on failure
function swim_object:add_member(cfg) end

---Explicitly and immediately remove a member from the member table.
---
---**Example:** `swim_object:remove_member('00000000-0000-1000-8000-000000000001')`
---
---@param uuid swim.uuid
---@return boolean | nil, string -- true on success, or nil + error message on failure
function swim_object:remove_member(uuid) end

---Send a ping request to the specified URI address.
---
---If a member responds, its info is added to the member table.
---
---**Example:** `swim_object:probe_member(3333)`
---
---@param uri swim.uri
---@return boolean | nil, string -- true on success, or nil + error message on failure
function swim_object:probe_member(uri) end

---Broadcast a ping request to all network interfaces.
---
---Similar to `probe_member` but to many members at once.
---
---**Example:** `swim_object:broadcast(3334)`
---
---@param port? number -- Destination port (defaults to currently bound port)
---@return boolean | nil, string -- true on success, or nil + error message on failure
function swim_object:broadcast(port) end

---Set a payload as formatted Lua data (serialized in MessagePack).
---
---Payload is disseminated across the cluster (max 1200 bytes).
---
---**Example:** `swim_object:set_payload({field1 = 100, field2 = 200})`
---
---@param payload any -- Set to nil to remove payload
---@return boolean | nil, string -- true on success, or nil + error message on failure
function swim_object:set_payload(payload) end

---Set a payload as raw data (no MessagePack serialization).
---
---Useful for pre-formatted data or cdata.
---
---**Example:**
--- ```lua
--- cdata = ffi.new('char[?]', 2)
--- cdata[0] = 1; cdata[1] = 2
--- swim_object:set_payload_raw(cdata, 2)
--- ```
---
---@param payload string | cdata
---@param size? integer -- Mandatory if payload is cdata
---@return boolean | nil, string -- true on success, or nil + error message on failure
function swim_object:set_payload_raw(payload, size) end

---Enable encryption for all messages.
---
---All instances must use same `algo`, `mode`, and `key`.
---
---**Example:**
--- ```lua
--- swim_object:set_codec({algo = 'aes128', mode = 'cbc', key = 'secretkey12345678'})
--- ```
---
---@param codec_cfg swim.codec_cfg
---@return boolean | nil, string -- true on success, or nil + error message on failure
function swim_object:set_codec(codec_cfg) end

---
---Return self as a swim member object.
---
---**Example:** `swim.member_object = swim_object:self()`
---
---@return swim.member_object -- Never nil
function swim_object:self() end

---Return a swim member object by UUID.
---
---**Example:**
--- ```lua
--- swim.member_object = swim_object:member_by_uuid('00000000-0000-1000-8000-000000000001')
--- ```
---
---@param uuid swim.uuid
---@return swim.member_object | nil -- nil if not found
function swim_object:member_by_uuid(uuid) end

---Set up an iterator for swim member objects.
---
---Use in a 'for' loop. Only one iterator allowed per SWIM instance at a time.
---
---**Example:**
--- ```lua
--- for uuid, member in swim_object:pairs() do
---   print(uuid, member:status())
--- end
--- ```
---
---@return fun(): swim.uuid, swim.member_object -- Iterator function
function swim_object:pairs() end

---Create or manage an "on_member_event" trigger.
---
---Trigger function is called when a member is added, updated, or dropped.
---
---**Example:**
--- ```lua
--- swim_object:on_member_event(function(member, event, ctx)
---   if event:is_new() then print("New member:", member:uuid()) end
--- end, context)
--- ```
---
---@param trigger_function? fun(member: swim.member_object, event: swim.member_event, ctx: any)
---@param old_trigger_or_ctx? fun() | any -- Old trigger to replace, or context if no trigger_function
---@param ctx? any -- Context passed to trigger function
---@return fun() | nil -- Returns trigger function or nil
function swim_object:on_member_event(trigger_function, old_trigger_or_ctx, ctx) end

---Create a new SWIM instance.
---
---Multiple instances can exist in a single process.
---If `cfg` is provided, equivalent to `s = swim.new(); s:cfg(cfg)` with generation set.
---
---**Example:**
--- ```lua
--- swim_object = swim.new({
---   uri = 3333,
---   uuid = '00000000-0000-1000-8000-000000000001',
---   heartbeat_rate = 0.1
--- })
--- ```
---
---@param cfg? swim.cfg -- Optional configuration (generation can only be set here)
---@return swim.object
function swim.new(cfg) end

return swim
