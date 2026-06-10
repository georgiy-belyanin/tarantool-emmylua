# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

* More `box.space` supplementary spaces.
* Trigger functions to `box.ctl` and functions for managing the cluster.
* `box.schema.func` definitions.
* `box.schema.sequence` definitions.
* Builtin `msgpack` module declarations.
* Builtin `digest` module declarations.
* Builtin `crypto` module declarations.
* Builtin `key_def` module declarations.
* Builtin `merger` module declarations.
* Builtin `popen` module declarations.
* Builtin `swim` module declarations.
* Builtin `varbinary` module declarations.
* Builtin `pickle` module declarations.
* Builtin `compat` module declarations.
* Tarantool stdlib extensions: `table.deepcopy`/`table.copy`, `os.environ`/`os.setenv`, `debug.sourcedir`/`debug.sourcefile`, and the `utf8` module.
* Builtin `tap` module declarations.
* Builtin `ulid` module declarations.
* Global `tonumber64`/`dostring` and `package.searchroot`/`package.setsearchroot`.
* Builtin `compress` module declarations with `zlib`, `zstd`, and `lz4` submodules (Enterprise Edition).
* Builtin `box.read_view` submodule declarations (Enterprise Edition).
* `config.storage` submodule declarations (Enterprise Edition).
* `experimental.connpool` submodule declarations.
* `box.prepare()`, `box.unprepare()`, the prepared statement object, and the `box.NULL` constant.
* Enterprise Edition `box.cfg` options: audit logging, flight recorder, authentication and password policy, `wal_ext`, and `secure_erasing`.
* Documented `box.error.*` database error code constants.
* Completed `box.index`: added `compact`, `drop`, `random`, `rename`, and `stat` methods.

### Fixed

* `box.schema.role.grant()` missing a parameter.
* `box.on_rollback()` was mistakenly declared as a second `box.on_commit()`.
* The `box.iterator` alias is now the iterator-direction union (it was modelled as a table), so `select`/`pairs`/`count` accept directions such as `"GE"`; `after`/`fetch_pos` moved to `box.space.select_options`.

## [0.2.0] - 28.05.25

### Added

* Builtin `socket` module declarations.
* Builtin `xlog` module declarations.
* Builtin `box.iproto` submodule declarations.
* `box.tuple.format` submodule.
* Various `box.space.format` fields (e.g. `foreign_keys`, `constraint`).

### Fixed

* Marked `vshard.router.call*` arguments and options optional.
* Added missing `map`, `any`, `double` tuple type names.
* Overloads of `box.space.*:format()` are now resolved properly.

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
