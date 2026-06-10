---@meta

---# Rock `metrics`
---
---*Since 2.11.1*
---
---The `metrics` module provides the ability to collect and expose [Tarantool metrics](doc://monitoring).
---
---**Note:**
---
---If you use a Tarantool version below [2.11.1](https://github.com/tarantool/tarantool/releases/tag/2.11.1),
---it is necessary to install the latest version of [metrics](https://github.com/tarantool/metrics) first.
---For Tarantool 2.11.1 and above, you can also use the external `metrics` module.
---In this case, the external `metrics` module takes priority over the built-in one.
---
---## Overview
---
---### Collectors
---
---A collector is a representation of one or more observations that change over time.
---Tarantool provides the following metric collectors:
---
---**counter**
---
---A counter is a cumulative metric that denotes a single monotonically increasing counter. Its value might only
---increase or be reset to zero on restart. For example, you can use the counter to represent the number of requests
---served, tasks completed, or errors.
---
---The design is based on the [Prometheus counter](https://prometheus.io/docs/concepts/metric_types/#counter).
---
---**gauge**
---
---A gauge is a metric that denotes a single numerical value that can arbitrarily increase and decrease.
---
---The gauge type is typically used for measured values like temperature or current memory usage.
---It could also be used for values that can increase or decrease, such as the number of concurrent requests.
---
---The design is based on the [Prometheus gauge](https://prometheus.io/docs/concepts/metric_types/#gauge).
---
---**histogram**
---
---A histogram metric is used to collect and analyze
---statistical data about the distribution of values within the application.
---Unlike metrics that track the average value or quantity of events, a histogram provides detailed visibility into the distribution of values and can uncover hidden dependencies.
---
---The design is based on the [Prometheus histogram](https://prometheus.io/docs/concepts/metric_types/#histogram).
---
---**summary**
---
---A summary metric is used to collect statistical data
---about the distribution of values within the application.
---
---Each summary provides several measurements:
---
---* total count of measurements
---* sum of measured values
---* values at specific quantiles
---
---Similar to histograms, the summary also operates with value ranges. However, unlike histograms,
---it uses quantiles (defined by a number between 0 and 1) for this purpose. In this case,
---it is not required to define fixed boundaries. For summary type, the ranges depend
---on the measured values and the number of measurements.
---
---The design is based on the [Prometheus summary](https://prometheus.io/docs/concepts/metric_types/#summary).
---
---### Labels
---
---A label is a piece of metainfo that you associate with a metric in the key-value format.
---For details, see [labels in Prometheus](https://prometheus.io/docs/practices/naming/#labels) and [tags in Graphite](https://graphite.readthedocs.io/en/latest/tags.html).
---
---Labels are used to differentiate between the characteristics of a thing being
---measured. For example, in a metric associated with the total number of HTTP
---requests, you can represent methods and statuses as label pairs:
---
--- ```lua
--- http_requests_total_counter:inc(1, { method = 'POST', status = '200' })
--- ```
---
---The example above allows extracting the following time series:
---
---1. The total number of requests over time with `method = "POST"` (and any status).
---2. The total number of requests over time with `status = 500` (and any method).
---
---## Configuring metrics
---
---To configure metrics, use [metrics.cfg()](lua://metrics.cfg).
---This function can be used to turn on or off the specified metrics or to configure labels applied to all collectors.
---Moreover, you can use the following shortcut functions to set-up metrics or labels:
---
---- [metrics.enable_default_metrics()](lua://metrics.enable_default_metrics)
---- [metrics.set_global_labels()](lua://metrics.set_global_labels)
---
---**Note:**
---
---Starting from version 3.0, metrics can be configured using a [configuration file](doc://configuration_file) in the [metrics](doc://configuration_reference_metrics) section.
---
---## Custom metrics
---
---To create a custom metric, follow the steps below:
---
---1. **Create a metric.** To create a new metric, you need to call a function corresponding to the
---   desired collector type. For example, call [metrics.counter()](lua://metrics.counter) or
---   [metrics.gauge()](lua://metrics.gauge) to create a new counter or gauge, respectively.
---2. **Observe a value.** You can observe a value in two ways: at the appropriate place (for example,
---   in an API request handler or trigger) by calling [counter_obj:inc()](lua://metrics.counter.inc),
---   or at the time of requesting the data collected by metrics, inside
---   [metrics.register_callback()](lua://metrics.register_callback).
---
---**Example:**
---
--- ```lua
--- local metrics = require('metrics')
--- local bands_replace_count = metrics.counter('bands_replace_count', 'The number of data operations')
--- ```
local metrics = {}

---@class metrics.cfg.options
---@field include? string | table (Default: `all`) `all` to enable all supported default metrics, `none` to disable all default metrics, table with names of the default metrics to enable a specific set of metrics.
---@field exclude? table (Default: `{}`) A table containing the names of the default metrics that you want to disable. Has higher priority than `include`.
---@field labels? table (Default: `{}`) A table containing label names as string keys, label values as values. See also: [Labels](lua://metrics.cfg).

---Entrypoint to setup the module.
---
---You can work with `metrics.cfg` as a table to read values, but you must call
---`metrics.cfg{}` as a function to update them.
---
---Supported default metric names (for `cfg.include` and `cfg.exclude` tables):
---
---* `all` (metasection including all metrics)
---* `network`
---* `operations`
---* `system`
---* `replicas`
---* `info`
---* `slab`
---* `runtime`
---* `memory`
---* `spaces`
---* `fibers`
---* `cpu`
---* `vinyl`
---* `memtx`
---* `luajit`
---* `clock`
---* `event_loop`
---* `config`
---
---See [metrics reference](doc://metrics-reference) for details.
---All metric collectors from the collection have `metainfo.default = true`.
---
---`cfg.labels` are the global labels to be added to every observation.
---
---Global labels are applied only to metric collection. They have no effect
---on how observations are stored.
---
---Global labels can be changed on the fly.
---
---`label_pairs` from observation objects have priority over global labels.
---If you pass `label_pairs` to an observation method with the same key as
---some global label, the method argument value will be used.
---
---Note that both label names and values in `label_pairs` are treated as strings.
---
---@class metrics.cfg
---@overload fun(config?: metrics.cfg.options)
metrics.cfg = {}

---@class metrics.collect.options
---@field invoke_callbacks? boolean If `true`, [invoke_callbacks()](lua://metrics.invoke_callbacks) is triggered before actual collect.
---@field default_only? boolean If `true`, observations contain only default metrics (`metainfo.default = true`).

---An observation object returned by a collector's `collect()` method.
---@class metrics.observation
---@field label_pairs table `label_pairs` key-value table
---@field timestamp ffi.cdata* current system time (in microseconds)
---@field value number current value
---@field metric_name string collector

---Collect observations from each collector.
---
---@param opts? metrics.collect.options table of collect options.
---@return metrics.observation[]
function metrics.collect(opts) end

---List all collectors in the registry. Designed to be used in exporters.
---
---See also: [Creating custom plugins](lua://metrics.invoke_callbacks)
---
---@return metrics.collector[] # A list of created collectors.
function metrics.collectors() end

---Register a new counter.
---
---See also: [Creating custom metrics](lua://metrics.counter)
---
---@param name string collector name. Must be unique.
---@param help? string collector description.
---@param metainfo? table collector metainfo.
---@return metrics.counter counter_obj A counter object.
function metrics.counter(name, help, metainfo) end

---Register a new gauge.
---
---See also: [Creating custom metrics](lua://metrics.gauge)
---
---@param name string collector name. Must be unique.
---@param help? string collector description.
---@param metainfo? table collector metainfo.
---@return metrics.gauge gauge_obj A gauge object.
function metrics.gauge(name, help, metainfo) end

---Register a new histogram.
---
---**Note:**
---
---A histogram is basically a set of collectors:
---
---* `name .. "_sum"` -- a counter holding the sum of added observations.
---* `name .. "_count"` -- a counter holding the number of added observations.
---* `name .. "_bucket"` -- a counter holding all bucket sizes under the label
---  `le` (less or equal). To access a specific bucket -- `x` (where `x` is a number),
---  specify the value `x` for the label `le`.
---
---See also: [Creating custom metrics](lua://metrics.histogram)
---
---@param name string collector name. Must be unique.
---@param help? string collector description.
---@param buckets? number[] histogram buckets (an array of sorted positive numbers). The infinity bucket (`INF`) is appended automatically. Default: `{.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}`.
---@param metainfo? table collector metainfo.
---@return metrics.histogram histogram_obj A histogram object.
function metrics.histogram(name, help, buckets, metainfo) end

---@class metrics.summary.params
---@field max_age_time? number Sets the duration of each bucket's lifetime -- that is, how many seconds the observations are kept before they are discarded.
---@field age_buckets_count? number Sets the number of buckets in the sliding time window.

---Register a new summary. Quantile computation is based on the
---["Effective computation of biased quantiles over data streams"](https://ieeexplore.ieee.org/document/1410103)
---algorithm.
---
---**Note:**
---
---A summary represents a set of collectors:
---
---* `name .. "_sum"` -- a counter holding the sum of added observations.
---* `name .. "_count"` -- a counter holding the number of added observations.
---* `name` holds all the quantiles under observation that find themselves
---  under the label `quantile` (less or equal).
---  To access bucket `x` (where `x` is a number),
---  specify the value `x` for the label `quantile`.
---
---See also: [Creating custom metrics](lua://metrics.summary)
---
---@param name string collector name. Must be unique.
---@param help? string collector description.
---@param objectives? table<number, number> a list of "targeted" φ-quantiles in the `{quantile = error, ... }` form. The targeted φ-quantile is specified in the form of a φ-quantile and the tolerated error. For example, `{[0.5] = 0.1}` means that the median (= 50th percentile) is to be returned with a 10-percent error. The φ-quantile must be in the interval `[0, 1]`. A lower tolerated error for a φ-quantile results in higher memory and CPU usage during summary calculation.
---@param params? metrics.summary.params table of the summary parameters used to configuring the sliding time window. Each bucket stores observations for `max_age_time * age_buckets_count` seconds before it is reset. Default value: `{max_age_time = math.huge, age_buckets_count = 1}`.
---@param metainfo? table collector metainfo.
---@return metrics.summary summary_obj A summary object.
function metrics.summary(name, help, objectives, params, metainfo) end

---Same as `metrics.cfg{include=include, exclude=exclude}`, but `include={}` is
---treated as `include='all'` for backward compatibility.
---
---@param include? string | table
---@param exclude? table
function metrics.enable_default_metrics(include, exclude) end

---Invoke all registered callbacks. Has to be called before each [collect()](lua://metrics.collect).
---You can also use `collect{invoke_callbacks = true}` instead.
---If you're using one of the default exporters,
---`invoke_callbacks()` will be called by the exporter.
---
---See also: [Creating custom plugins](lua://metrics.collectors)
function metrics.invoke_callbacks() end

---Register a function named `callback`, which will be called right before metric
---collection on plugin export.
---
---This method is most often used for gauge metrics updates.
---
---**Example:**
---
--- ```lua
--- local metrics = require('metrics')
--- local bands_waste_size = metrics.gauge('bands_waste_size', 'Memory wasted')
--- metrics.register_callback(function()
---     bands_waste_size:set(box.slab.info().arena_used - box.slab.info().items_used)
--- end)
--- ```
---
---See also: [Custom metrics](lua://metrics.counter)
---
---@param callback fun() a function that takes no parameters.
function metrics.register_callback(callback) end

---Same as `metrics.cfg{ labels = label_pairs }`.
---Learn more in [metrics.cfg()](lua://metrics.cfg).
---
---@param label_pairs table
function metrics.set_global_labels(label_pairs) end

---Unregister a function named `callback` that is called right before metric
---collection on plugin export.
---
---**Example:**
---
--- ```lua
--- local cpu_callback = function()
---     local cpu_metrics = require('metrics.psutils.cpu')
---     cpu_metrics.update()
--- end
---
--- metrics.register_callback(cpu_callback)
---
--- -- after a while, we don't need that callback function anymore
---
--- metrics.unregister_callback(cpu_callback)
--- ```
---
---@param callback fun() a function that takes no parameters.
function metrics.unregister_callback(callback) end

---## metrics.http_middleware API
---
---The `metrics` module provides middleware for monitoring HTTP latency statistics for endpoints that are created using the [http](https://github.com/tarantool/http) module.
---The latency collector observes both latency information and the number of invocations.
---The metrics collected by HTTP middleware are separated by a set of labels:
---
---* a route (`path`)
---* a method (`method`)
---* an HTTP status code (`status`)
metrics.http_middleware = {}

---Register and return a collector for the middleware.
---
---**Possible errors:**
---
---* A collector with the same type and name already exists in the registry.
---
---@param type_name? string collector type: `histogram` or `summary`. The default is `histogram`.
---@param name? string collector name. The default is `http_server_request_latency`.
---@param help? string collector description. The default is `HTTP Server Request Latency`.
---@return metrics.collector # A collector object.
function metrics.http_middleware.build_default_collector(type_name, name, help) end

---Register a collector for the middleware and set it as default.
---
---**Possible errors:**
---
---* A collector with the same type and name already exists in the registry.
---
---@param type_name? string collector type: `histogram` or `summary`. The default is `histogram`.
---@param name? string collector name. The default is `http_server_request_latency`.
---@param help? string collector description. The default is `HTTP Server Request Latency`.
function metrics.http_middleware.configure_default_collector(type_name, name, help) end

---Return the default collector.
---If the default collector hasn't been set yet, register it
---(with default [http_middleware.build_default_collector()](lua://metrics.http_middleware.build_default_collector) parameters)
---and set it as default.
---
---@return metrics.collector # A collector object.
function metrics.http_middleware.get_default_collector() end

---Set the default collector.
---
---@param collector metrics.collector middleware collector object.
function metrics.http_middleware.set_default_collector(collector) end

---Latency measuring wrap-up for the HTTP ver. `1.x.x` handler. Returns a wrapped handler.
---
---Learn more in [Collecting HTTP metrics](lua://metrics.http_middleware).
---
---**Usage:**
---
--- ```lua
--- httpd:route(route, http_middleware.v1(request_handler, collector))
--- ```
---
---@param handler fun(...): any handler function.
---@param collector? metrics.collector middleware collector object. If not set, the default collector is used (like in [http_middleware.get_default_collector()](lua://metrics.http_middleware.get_default_collector)).
---@return fun(...): any # A wrapped handler.
function metrics.http_middleware.v1(handler, collector) end

---A metrics registry.
---@class metrics.registry
local registry = {}

---Remove a collector from the registry.
---
---**Example:**
---
--- ```lua
--- local collector = metrics.gauge('some-gauge')
---
--- -- after a while, we don't need it anymore
---
--- metrics.registry:unregister(collector)
--- ```
---
---@param collector metrics.collector the collector to be removed.
function registry:unregister(collector) end

---Find a collector in the registry.
---
---**Example:**
---
--- ```lua
--- local collector = metrics.gauge('some-gauge')
---
--- collector = metrics.registry:find('gauge', 'some-gauge')
--- ```
---
---@param kind 'counter' | 'gauge' | 'histogram' | 'summary' collector kind.
---@param name string collector name.
---@return metrics.collector? # A collector object or `nil`.
function registry:find(kind, name) end

---@type metrics.registry
metrics.registry = registry

--- # Related objects

---A collector object.
---
---See also: [Creating custom plugins](lua://metrics.collectors)
---@class metrics.collector
local collector_object = {}

---Collect observations from this collector.
---To collect observations from each collector, use [metrics.collectors()](lua://metrics.collectors).
---
---`collector_object:collect()` is equivalent to the following code:
---
--- ```lua
--- for _, c in pairs(metrics.collectors()) do
---     for _, obs in ipairs(c:collect()) do
---         ...  -- handle observation
---     end
--- end
--- ```
---
---@return metrics.observation[] # A concatenation of `observation` objects across all created collectors.
function collector_object:collect() end

---A counter object.
---@class metrics.counter: metrics.collector
local counter_obj = {}

---Increment the observation for `label_pairs`.
---If `label_pairs` doesn't exist, the method creates it.
---
---See also: [Labels](lua://metrics.cfg)
---
---@param num number increment value.
---@param label_pairs? table table containing label names as keys, label values as values. Note that both label names and values in `label_pairs` are treated as strings.
function counter_obj:inc(num, label_pairs) end

---Get an array of `observation` objects for a given counter.
---
---@return metrics.observation[] # Array of `observation` objects for a given counter.
function counter_obj:collect() end

---Remove the observation for `label_pairs`.
---
---@param label_pairs? table
function counter_obj:remove(label_pairs) end

---Set the observation for `label_pairs` to 0.
---
---@param label_pairs? table table containing label names as keys, label values as values. Note that both label names and values in `label_pairs` are treated as strings.
function counter_obj:reset(label_pairs) end

---A gauge object.
---@class metrics.gauge: metrics.collector
local gauge_obj = {}

---Increment the observation for `label_pairs`.
---If `label_pairs` doesn't exist, the method creates it.
---
---@param num number
---@param label_pairs? table
function gauge_obj:inc(num, label_pairs) end

---Decrement the observation for `label_pairs`.
---
---@param num number
---@param label_pairs? table
function gauge_obj:dec(num, label_pairs) end

---Set the observation for `label_pairs` to `num`.
---
---@param num number
---@param label_pairs? table
function gauge_obj:set(num, label_pairs) end

---Get an array of `observation` objects for a given gauge.
---For the description of `observation`, see [counter_obj:collect()](lua://metrics.counter.collect).
---
---@return metrics.observation[]
function gauge_obj:collect() end

---Remove the observation for `label_pairs`.
---
---@param label_pairs? table
function gauge_obj:remove(label_pairs) end

---A histogram object.
---@class metrics.histogram: metrics.collector
local histogram_obj = {}

---Record a new value in a histogram.
---This increments all bucket sizes under the labels `le` >= `num`
---and the labels that match `label_pairs`.
---
---See also: [Labels](lua://metrics.cfg)
---
---@param num number value to put in the histogram.
---@param label_pairs? table table containing label names as keys, label values as values. All internal counters that have these labels specified observe new counter values. Note that both label names and values in `label_pairs` are treated as strings.
function histogram_obj:observe(num, label_pairs) end

---Return a concatenation of `counter_obj:collect()` across all internal
---counters of `histogram_obj`. For the description of `observation`,
---see [counter_obj:collect()](lua://metrics.counter.collect).
---
---@return metrics.observation[]
function histogram_obj:collect() end

---Works like the `remove()` function of a counter.
---
---@param label_pairs? table
function histogram_obj:remove(label_pairs) end

---A summary object.
---@class metrics.summary: metrics.collector
local summary_obj = {}

---Record a new value in a summary.
---
---See also: [Labels](lua://metrics.cfg)
---
---@param num number value to put in the data stream.
---@param label_pairs? table a table containing label names as keys, label values as values. All internal counters that have these labels specified observe new counter values. You can't add the `"quantile"` label to a summary. It is added automatically. If `max_age_time` and `age_buckets_count` are set, the observed value is added to each bucket. Note that both label names and values in `label_pairs` are treated as strings.
function summary_obj:observe(num, label_pairs) end

---Return a concatenation of `counter_obj:collect()` across all internal
---counters of `summary_obj`. For the description of `observation`,
---see [counter_obj:collect()](lua://metrics.counter.collect).
---If `max_age_time` and `age_buckets_count` are set, quantile observations
---are collected only from the head bucket in the sliding time window,
---not from every bucket. If no observations were recorded,
---the method will return `NaN` in the values.
---
---@return metrics.observation[]
function summary_obj:collect() end

---Works like the `remove()` function of a counter.
---
---@param label_pairs? table
function summary_obj:remove(label_pairs) end

return metrics
