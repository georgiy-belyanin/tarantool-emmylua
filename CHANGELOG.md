# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

* Marked `vshard.router.call*` arguments and options optional.

## [0.1.1] - 14.04.25

### Added

* Builtin `buffer` module definitions.
* Builtin `csv` module definitions.
* Partial `fun` module definitions.
* Builtin `http.client` module definitions.
* Builtin `errno` module definitions.
* Builtin `strict` module definitions.
* Partial `vshard` rock definitions.
* `box.execute()` documentation used for evaluating SQL statements.
* `box.space.*:format()` documentation and annotations.
* `box.schema.role` and `box.schema.user` documentation and type annotations.
* Annotations on a few supplementary spaces like `box.schema._cluster`.

### Changed

* Tightened some of the `box` `number` types to `integer`.
* Tightened some of the `string` `number` types to `integer`.

### Fixed

* A `box.atomic()` overload has now proper variadic arguments.
* `box.tuple` now doesn't issue diagnostics on missing field.
* Missing `fio` file handle `:read()` overload.

## [0.1.0] - 12.04.25

### Added

* General Tarantool definitions.
* Partial builtin `box` module definitions.
* Partial builtin `box.backup` submodule definitions.
* Partial builtin `box.cfg` submodule definitions.
* Partial builtin `box.error` submodule definitions.
* Partial builtin `box.index` submodule definitions.
* Partial builtin `box.schema` submodule definitions.
* Partial builtin `box.session` submodule definitions.
* Partial builtin `box.slab` submodule definitions.
* Partial builtin `box.space` submodule definitions.
* Partial builtin `box.schema` submodule definitions.
* Partial builtin `box.stat` submodule definitions.
* Partial builtin `box.tuple` submodule definitions.
* Builtin `clock` module definitions.
* Builtin `console` module definitions.
* Partial builtin `config` module definitions.
* Builtin `datetime` module definition.
* Builtin `decimal` module definition.
* Builtin `fiber` module definitions.
* Builtin `fio` module definitions.
* Builtin `iconv` module definitions.
* Builtin `jit` module definitions.
* Builtin `json` module definitions.
* Builtin `net.box` module definitions.
* Builtin `string` module definitions.
* Builtin `uri` module definitions.
* Builtin `uuid` module definitions.
* Builtin `yaml` module definitions.
