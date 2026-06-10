---@meta

---# Builtin `tap` module
---
---The `tap` module streamlines the testing of other modules. It allows writing
---of tests in the [TAP protocol](https://en.wikipedia.org/wiki/Test_Anything_Protocol).
---The results from the tests can be parsed by standard TAP-analyzers so they can be passed to utilities such as
---[prove](https://metacpan.org/pod/distribution/Test-Harness/bin/prove).
---Thus, one can run tests and then use the results for statistics, decision-making, and
---so on.
---
---**Example:**
---
---To run this example: put the script in a file named ./tap.lua, then make
---tap.lua executable by saying `chmod a+x ./tap.lua`, then execute using
---Tarantool as a script processor by saying ./tap.lua.
---
--- ```lua
--- #!/usr/bin/tarantool
--- local tap = require('tap')
--- test = tap.test("my test name")
--- test:plan(2)
--- test:ok(2 * 2 == 4, "2 * 2 is 4")
--- test:test("some subtests for test2", function(test)
---     test:plan(2)
---     test:is(2 + 2, 4, "2 + 2 is 4")
---     test:isnt(2 + 3, 4, "2 + 3 is not 4")
--- end)
--- test:check()
--- ```
---
---The output from the above script will look approximately like this:
---
--- ```tap
--- TAP version 13
--- 1..2
--- ok - 2 * 2 is 4
---     # Some subtests for test2
---     1..2
---     ok - 2 + 2 is 4,
---     ok - 2 + 3 is not 4
---     # Some subtests for test2: end
--- ok - some subtests for test2
--- ```
local tap = {}

---@class tap.test
---@field strict boolean Set `taptest.strict=true` if [`taptest:is()`](lua://tap.test.is) and [`taptest:isnt()`](lua://tap.test.isnt) and [`taptest:is_deeply()`](lua://tap.test.is_deeply) must be compared strictly with `nil`. Set `taptest.strict=false` if `nil` and `box.NULL` both have the same effect. The default is false. For example, if and only if `taptest.strict=true` has happened, then `taptest:is_deeply({a = box.NULL}, {})` will return `false`. Since 2.8.3, `taptest.strict` is inherited in all subtests.
local taptest = {}

---Initialize.
---
---The result of `tap.test` is an object, which will be called taptest
---in the rest of this discussion, which is necessary for `taptest:plan()`
---and all the other methods.
---
--- ```lua
--- tap = require('tap')
--- taptest = tap.test('test-name')
--- ```
---
---@param test_name string an arbitrary name to give for the test outputs.
---@return tap.test taptest
function tap.test(test_name) end

---Create a subtest (if no `func` argument specified), or
---(if all arguments are specified)
---create a subtest, run the test function and print the result.
---
---See the [example](lua://tap).
---
---@param name string an arbitrary name to give for the test outputs.
---@param fun? fun(test: tap.test) the test logic to run.
---@return tap.test taptest
function taptest:test(name, fun) end

---Indicate how many tests will be performed.
---
---@param count number
function taptest:plan(count) end

---Checks the number of tests performed.
---
---The result will be a display saying `# bad plan: ...` if the number
---of completed tests is not equal to the number of tests specified by
---`taptest:plan(...)`. (This is a purely Tarantool feature: "bad plan"
---messages are out of the TAP13 standard.)
---
---This check should only be done after all planned tests are complete,
---so ordinarily `taptest:check()` will only appear at the end of a script.
---However, as a Tarantool extension, `taptest:check()` may appear at the
---end of any subtest. Therefore there are three ways to cause the check:
---
---* by calling `taptest:check()` at the end of a script,
---* by calling a function which ends with a call to `taptest:check()`,
---* or by calling taptest:test('...', subtest-function-name) where
---  subtest-function-name does not need to end with `taptest:check()`
---  because it can be called after the subtest is complete.
---
---@return boolean # true or false.
function taptest:check() end

---Display a diagnostic message.
---
---@param message string the message to be displayed.
function taptest:diag(message) end

---This is a basic function which is used by other functions. Depending
---on the value of `condition`, print 'ok' or 'not ok' along with
---debugging information. Displays the message.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> taptest:ok(true, 'x')
--- ok - x
--- ---
--- - true
--- ...
--- tarantool> tap = require('tap')
--- ---
--- ...
--- tarantool> taptest = tap.test('test-name')
--- TAP version 13
--- ---
--- ...
--- tarantool> taptest:ok(1 + 1 == 2, 'X')
--- ok - X
--- ---
--- - true
--- ...
--- ```
---
---@param condition boolean an expression which is true or false
---@param test_name string name of the test
---@return boolean # true or false.
function taptest:ok(condition, test_name) end

---`taptest:fail('x')` is equivalent to `taptest:ok(false, 'x')`.
---Displays the message.
---
---@param test_name string name of the test
---@return boolean # true or false.
function taptest:fail(test_name) end

---`taptest:skip('x')` is equivalent to
---`taptest:ok(true, 'x' .. '# skip')`.
---Displays the message.
---
---**Example:**
---
--- ```tarantoolsession
--- tarantool> taptest:skip('message')
--- ok - message # skip
--- ---
--- - true
--- ...
--- ```
---
---@param test_name string name of the test
function taptest:skip(test_name) end

---Check whether the first argument equals the second argument.
---Displays extensive message if the result is false.
---
---@param got number actual result
---@param expected number expected result
---@param test_name string name of the test
---@return boolean # true or false.
function taptest:is(got, expected, test_name) end

---This is the negation of [`taptest:is()`](lua://tap.test.is).
---
---@param got number actual result
---@param expected number expected result
---@param test_name string name of the test
---@return boolean # true or false.
function taptest:isnt(got, expected, test_name) end

---Recursive version of `taptest:is(...)`, which can be used to
---compare tables as well as scalar values.
---
---@param got any actual result
---@param expected any expected result
---@param test_name string name of the test
---@return boolean # true or false.
function taptest:is_deeply(got, expected, test_name) end

---Verify a string against a
---[pattern](http://lua-users.org/wiki/PatternsTutorial).
---Ok if match is found.
---
--- ```lua
--- test:like(tarantool.version, '^[1-9]', "version")
--- ```
---
---@param got any actual result
---@param expected string pattern
---@param test_name string name of the test
---@return boolean # true or false.
function taptest:like(got, expected, test_name) end

---This is the negation of [`taptest:like()`](lua://tap.test.like).
---
---@param got any actual result
---@param expected string pattern
---@param test_name string name of the test
---@return boolean # true or false.
function taptest:unlike(got, expected, test_name) end

---Test whether a value has a particular type. Displays a long message if
---the value is not of the specified type.
---
---@param value any value the type of which is to be checked
---@param message? string text that will be shown to the user in case of failure
---@param extra? any
---@return boolean # true or false.
function taptest:isnil(value, message, extra) end

---Test whether a value has a particular type. Displays a long message if
---the value is not of the specified type.
---
---@param value any value the type of which is to be checked
---@param message? string text that will be shown to the user in case of failure
---@param extra? any
---@return boolean # true or false.
function taptest:isstring(value, message, extra) end

---Test whether a value has a particular type. Displays a long message if
---the value is not of the specified type.
---
---@param value any value the type of which is to be checked
---@param message? string text that will be shown to the user in case of failure
---@param extra? any
---@return boolean # true or false.
function taptest:isnumber(value, message, extra) end

---Test whether a value has a particular type. Displays a long message if
---the value is not of the specified type.
---
---@param value any value the type of which is to be checked
---@param message? string text that will be shown to the user in case of failure
---@param extra? any
---@return boolean # true or false.
function taptest:istable(value, message, extra) end

---Test whether a value has a particular type. Displays a long message if
---the value is not of the specified type.
---
---@param value any value the type of which is to be checked
---@param message? string text that will be shown to the user in case of failure
---@param extra? any
---@return boolean # true or false.
function taptest:isboolean(value, message, extra) end

---Test whether a value has a particular type. Displays a long message if
---the value is not of the specified type.
---
---@param value any value the type of which is to be checked
---@param utype string type of data that a passed value should have
---@param message? string text that will be shown to the user in case of failure
---@param extra? any
---@return boolean # true or false.
function taptest:isudata(value, utype, message, extra) end

---Test whether a value has a particular type. Displays a long message if
---the value is not of the specified type.
---
--- ```lua
--- test:iscdata(slab_info.quota_size, ffi.typeof('uint64_t'), 'memcached.slab.info().quota_size returns a cdata')
--- ```
---
---@param value any value the type of which is to be checked
---@param ctype string type of data that a passed value should have
---@param message? string text that will be shown to the user in case of failure
---@param extra? any
---@return boolean # true or false.
function taptest:iscdata(value, ctype, message, extra) end

return tap
