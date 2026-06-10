---@meta

---@class box.stat.default
---@field total number total number of requests processed since the server started
---@field rps number average number of requests per second in the last 5 seconds

---@class box.stat.default_with_current: box.stat.default
---@field current number current value

---`box.stat()` result: the total number of requests and the average number of requests per second, broken down by request type.
---@class box.stat.info
---@field SELECT box.stat.default
---@field INSERT box.stat.default
---@field REPLACE box.stat.default
---@field UPDATE box.stat.default
---@field UPSERT box.stat.default
---@field DELETE box.stat.default
---@field CALL box.stat.default
---@field EVAL box.stat.default
---@field AUTH box.stat.default
---@field ERROR box.stat.default the count of requests that resulted in an error
---@field BEGIN box.stat.default
---@field COMMIT box.stat.default
---@field ROLLBACK box.stat.default
---@field PREPARE box.stat.default
---@field EXECUTE box.stat.default

---`box.stat.net()` result.
---@class box.stat.net
---@field SENT box.stat.default bytes sent to iproto (total and rps)
---@field RECEIVED box.stat.default bytes received from iproto (total and rps)
---@field CONNECTIONS box.stat.default_with_current iproto connections (current, rps, total)
---@field REQUESTS box.stat.default_with_current iproto requests (current, rps, total)
---@field REQUESTS_IN_PROGRESS box.stat.default_with_current requests being currently processed by the TX thread
---@field STREAMS box.stat.default_with_current active streams
---@field REQUESTS_IN_STREAM_QUEUE box.stat.default_with_current requests waiting in stream queues

---`box.stat.memtx().data` -- memory (in bytes) allocated for memtx tuples.
---@class box.stat.memtx.data
---@field garbage number amount of memory that is unused and scheduled to be freed (freed lazily on memory allocation)
---@field total number total amount of memory allocated for data tuples (includes `read_view` and `garbage`)
---@field read_view number amount of memory held for read views (system and user (EE-only) read views)

---`box.stat.memtx().index` -- memory (in bytes) allocated for indexing memtx tuples.
---@class box.stat.memtx.index
---@field read_view number amount of memory held for read views
---@field total number total amount of memory allocated for indexing data (includes `read_view`)

---Statistics reported per transaction section (total/avg/max number of bytes).
---@class box.stat.memtx.tx.values
---@field total number number of bytes currently allocated for all transactions within the section scope
---@field avg number average number of bytes that a single transaction uses
---@field max number maximal number of bytes that a single transaction uses

---Memory allocation related to transactions.
---@class box.stat.memtx.tx.txn
---@field statements box.stat.memtx.tx.values transaction statements
---@field user box.stat.memtx.tx.values memory allocated by a user via the C API `box_txn_alloc()`
---@field system box.stat.memtx.tx.values memory allocated for internal needs (for example, logs) and savepoints

---A statistics block for stories or retained tuples.
---@class box.stat.memtx.tx.tuple_block
---@field count number number of stories or retained tuples
---@field total number number of bytes allocated for stories or retained tuples

---Memory allocated for a tuple category (stories and retained tuples).
---@class box.stat.memtx.tx.tuple_category
---@field stories box.stat.memtx.tx.tuple_block
---@field retained box.stat.memtx.tx.tuple_block

---Memory allocated for storing tuples, by category.
---@class box.stat.memtx.tx.tuples
---@field tracking box.stat.memtx.tx.tuple_category tuples used by MVCC for tracking transaction reads
---@field used box.stat.memtx.tx.tuple_category tuples used by active read-write transactions
---@field read_view box.stat.memtx.tx.tuple_category tuples used by read-only transactions

---Memory allocation related to multiversion concurrency control (MVCC).
---@class box.stat.memtx.tx.mvcc
---@field trackers box.stat.memtx.tx.values memory allocated for trackers of transaction reads
---@field conflicts box.stat.memtx.tx.values memory allocated for conflicts
---@field tuples box.stat.memtx.tx.tuples memory allocated for storing tuples

---`box.stat.memtx().tx` -- statistics of the memtx transactional manager.
---@class box.stat.memtx.tx
---@field txn box.stat.memtx.tx.txn memory allocation related to transactions
---@field mvcc box.stat.memtx.tx.mvcc memory allocation related to MVCC

---`box.stat.memtx()` result.
---@class box.stat.memtx.info
---@field data box.stat.memtx.data memory allocated for memtx tuples
---@field index box.stat.memtx.index memory allocated for indexing memtx tuples
---@field tx box.stat.memtx.tx statistics of the memtx transactional manager

---`box.stat.vinyl().disk` -- on-disk data.
---@class box.stat.vinyl.disk
---@field data number amount of data that has gone into `{lsn}.run` files
---@field index number amount of data that has gone into `{lsn}.index` files
---@field data_compacted number sum size of data stored at the last LSM tree level (in bytes), without disk compression

---`box.stat.vinyl().memory` -- memory used for write buffers and caches.
---@class box.stat.vinyl.memory
---@field tuple_cache number size of memory (in bytes) occupied by tuples stored in the cache
---@field tuple number size of memory (in bytes) occupied by all allocated tuples
---@field tx number transactional memory (usually 0)
---@field level0 number the "level0" (L0) in-memory storage area for an LSM tree
---@field page_index number amount used for page-index structures
---@field bloom_filter number amount used for bloom-filter structures

---`box.stat.vinyl().regulator` -- disk-IO regulator statistics.
---@class box.stat.vinyl.regulator
---@field dump_bandwidth number estimated average rate at which dumps are done
---@field dump_watermark number the point (in bytes) when dumping must occur
---@field write_rate number actual average rate at which recent writes to disk are done
---@field rate_limit number write rate limit (in bytes per second) imposed on transactions
---@field blocked_writers number number of fibers currently blocked waiting for vinyl L0 memory quota

---`box.stat.vinyl().scheduler` -- dump/compaction task counters.
---@class box.stat.vinyl.scheduler
---@field compaction_input number amount of data that is being compacted
---@field compaction_queue number amount of data waiting to be compacted
---@field compaction_time number total time spent by all worker threads performing compaction, in seconds
---@field compaction_output number amount of data that has been compacted
---@field tasks_inprogress number dump/compaction tasks currently running
---@field tasks_completed number dump/compaction tasks successfully completed
---@field tasks_failed number dump/compaction tasks aborted due to errors
---@field dump_time number total time spent by all worker threads performing dumps, in seconds
---@field dump_count number count of completed dumps
---@field dump_input number amount of data dumped (input)
---@field dump_output number amount of data dumped (output)

---`box.stat.vinyl().tx` -- transactional activity.
---@class box.stat.vinyl.tx
---@field conflict number conflicts that caused a transaction to roll back
---@field commit number count of commits (successful transaction ends)
---@field rollback number count of rollbacks (unsuccessful transaction ends)
---@field statements number usually 0
---@field transactions number number of transactions that are currently running
---@field gap_locks number number of gap locks that are outstanding during execution of a request
---@field read_views number whether a transaction has entered a read-only state to avoid conflict temporarily (usually 0)

---`box.stat.vinyl()` result.
---@class box.stat.vinyl.info
---@field disk box.stat.vinyl.disk
---@field memory box.stat.vinyl.memory
---@field regulator box.stat.vinyl.regulator
---@field scheduler box.stat.vinyl.scheduler
---@field tx box.stat.vinyl.tx

---# Builtin `box.stat` submodule
---
---The `box.stat` submodule provides access to request and storage-engine statistics.
---Call `box.stat()` to get the total and per-second number of requests, broken down by request type.
---@class box.stat
---@overload fun(): box.stat.info
box.stat = {}

---`box.stat.net` accessor -- shows network activity.
---Call `box.stat.net()` for cumulative statistics, or use `box.stat.net.thread` for per-network-thread statistics.
---@class box.stat.net.accessor
---@field thread box.stat.net.thread_accessor network activity per network thread
---@overload fun(): box.stat.net
box.stat.net = {}

---`box.stat.net.thread` accessor -- network activity per [network thread](doc://thread_model).
---Call `box.stat.net.thread()` for all threads, or index it (`box.stat.net.thread[1]`) for a single network thread.
---@class box.stat.net.thread_accessor
---@field [integer] box.stat.net
---@overload fun(): box.stat.net[]
box.stat.net.thread = {}

---`box.stat.memtx` accessor -- shows `memtx` storage engine activity.
---Call `box.stat.memtx()` for the full statistics, or `box.stat.memtx.tx()` for the transactional manager part.
---@class box.stat.memtx.accessor
---@field tx fun(): box.stat.memtx.tx statistics of the memtx transactional manager
---@overload fun(): box.stat.memtx.info
box.stat.memtx = {}

---Shows `vinyl` storage engine activity, for example `box.stat.vinyl().tx` has the number of commits and rollbacks.
---@class box.stat.vinyl.accessor
---@overload fun(): box.stat.vinyl.info
box.stat.vinyl = {}

---Resets the statistics of `box.stat()`, `box.stat.net()`, `box.stat.memtx()`, `box.stat.vinyl()`, and [`box.space.index`](lua://box.index).
function box.stat.reset() end
