local Functions = require "Functions"
local Tables = require "Tables"

describe(
	"Functions",
	function()
		local callSpy
		before_each(
			function()
				callSpy =
					spy.new(
					function(...)
						return {..., n = select("#", ...)}
					end
				)
			end
		)
		describe(
			"id",
			function()
				it(
					"passes through args",
					function()
						assert.are.same({1, 2, 3}, {Functions.id(1, 2, 3)})
					end
				)
			end
		)
		describe(
			"noop",
			function()
				it(
					"eliminates args",
					function()
						assert.are.same({}, {Functions.noop(1, 2, 3)})
					end
				)
			end
		)
		describe(
			"returns",
			function()
				it(
					"returns as expected",
					function()
						assert.are.same({1, 2, 3}, {Functions.returns(1, 2, 3)(4, 5, 6)})
					end
				)
			end
		)
		describe(
			"throws",
			function()
				it(
					"throws as expected",
					function()
						assert.errors(
							function()
								Functions.throws("ExpectedError")(4, 5, 6)
							end,
							"ExpectedError"
						)
					end
				)
			end
		)
		describe(
			"once",
			function()
				it(
					"runs once as expected",
					function()
						local count = 0
						local once =
							Functions.once(
							function(amount)
								count = count + amount
								return count
							end
						)
						assert.equal(3, once(3))
						assert.equal(3, once(42))
						assert.equal(3, once(1337))
					end
				)
			end
		)
		describe(
			"compose",
			function()
				it(
					"composes functions as expected",
					function()
						local function fry(item)
							return "fried " .. item
						end
						local function cheesify(item)
							return "cheesy " .. item
						end
						local prepare = Functions.compose(fry, cheesify)
						assert.equal("cheesy fried nachos", prepare("nachos"))
					end
				)
			end
		)
		describe(
			"bind",
			function()
				it(
					"binds functions as expected",
					function()
						local function fry(item, amount)
							return "fry " .. item .. " " .. amount .. " times"
						end
						local fryChips = Functions.bind(fry, "chips")
						assert.equal("fry chips 10 times", fryChips(10))
					end
				)
			end
		)

		describe(
			"isCallable",
			function()
				it(
					"true for a function",
					function()
						assert(
							Functions.isCallable(
								function()
								end
							)
						)
					end
				)

				it(
					"true for a table with a __call metamethod",
					function()
						local tbl = {}

						setmetatable(
							tbl,
							{
								__call = function()
								end
							}
						)

						assert(Functions.isCallable(tbl))
					end
				)

				it(
					"false for a table without a __call metamethod",
					function()
						assert(not Functions.isCallable({}))
					end
				)
			end
		)

		describe(
			"memoize",
			function()
				it(
					"Can memoize with default rule",
					function()
						local c = 10
						local memoizedSum =
							Functions.memoize(
							function(a, b)
								return a + b + c
							end
						)
						assert.equal(13, memoizedSum(1, 2))
						c = 20
						assert.equal(13, memoizedSum(1, 2))
					end
				)

				it(
					"Can memoize with custom rule",
					function()
						local c = 10
						local memoizedSum =
							Functions.memoize(
							function(a, b)
								return a + b + c
							end,
							function(args)
								return args[1]
							end
						)
						assert.equal(13, memoizedSum(1, 2))
						c = 20
						assert.equal(13, memoizedSum(1, 10))
						assert.equal(33, memoizedSum(2, 11))
					end
				)

				it(
					"Can clear the cache with custom rule",
					function()
						local c = 10
						local memoizedSum =
							Functions.memoize(
							function(a, b)
								return a + b + c
							end,
							function(args)
								return args[1]
							end
						)
						assert.equal(13, memoizedSum(1, 2))
						c = 20
						assert.equal(13, memoizedSum(1, 10))
						memoizedSum:clear(1)
						assert.equal(31, memoizedSum(1, 10))
					end
				)
			end
		)
		describe(
			"setTimeout",
			function()
				it(
					"calls a timeout after a delay",
					function()
						Functions.setTimeout(callSpy, 2)
						assert.spy(callSpy).was_not_called()
						wait(3)
						clock:process()
						assert.spy(callSpy).was_called()
					end
				)
				it(
					"can be cleared",
					function()
						local timeout = Functions.setTimeout(callSpy, 2)
						assert.spy(callSpy).was_not_called()
						timeout:clear()
						wait(3)
						clock:process()
						assert.spy(callSpy).was_not_called()
					end
				)
				it(
					"can be cleared inside the timeout",
					function()
						local clearCallSpy =
							spy.new(
							function(timeout)
								timeout:clear()
							end
						)
						local timeout = Functions.setTimeout(clearCallSpy, 2)
						assert.spy(clearCallSpy).was_not_called()
						timeout:clear()
						wait(3)
						clock:process()
						assert.spy(clearCallSpy).was_not_called()
					end
				)
			end
		)

		describe(
			"setInterval",
			function()
				it(
					"calls interval repeatedly after delays",
					function()
						Functions.setInterval(callSpy, 2)
						assert.spy(callSpy).was_not_called()
						wait(3)
						clock:process()
						assert.spy(callSpy).called(1)
						wait(2)
						clock:process()
						assert.spy(callSpy).called(2)
						wait(2)
						clock:process()
						assert.spy(callSpy).called(3)
					end
				)
				it(
					"can be called immediately",
					function()
						Functions.setInterval(callSpy, 2, 0)
						wait(0)
						clock:process()
						assert.spy(callSpy).was_called()
					end
				)
				it(
					"can be cleared",
					function()
						local interval = Functions.setInterval(callSpy, 2)
						assert.spy(callSpy).was_not_called()
						wait(3)
						clock:process()
						assert.spy(callSpy).called(1)
						wait(2)
						clock:process()
						assert.spy(callSpy).called(2)
						interval:clear()
						wait(2)
						clock:process()
						assert.spy(callSpy).called(2)
					end
				)
				it(
					"can be cleared inside the interval",
					function()
						local clearCallSpy =
							spy.new(
							function(interval)
								interval:clear()
							end
						)
						Functions.setInterval(clearCallSpy, 2)
						assert.spy(clearCallSpy).was_not_called()
						wait(3)
						clock:process()
						assert.spy(clearCallSpy).called(1)
						wait(2)
						clock:process()
						assert.spy(clearCallSpy).called(1)
					end
				)
			end
		)

		describe(
			"Debounce",
			function()
				local debounced

				before_each(
					function()
						debounced = Functions.debounce(callSpy, 100)
					end
				)

				it(
					"should not call before the delay has elapsed",
					function()
						debounced("hi")

						assert.spy(callSpy).was_not_called()

						wait(99)
						clock:process()

						assert.spy(callSpy).was_not_called()
					end
				)

				it(
					"should call after the delay",
					function()
						debounced("hi")

						wait(100)
						clock:process()

						assert.spy(callSpy).was_called(1)
						assert.spy(callSpy).was_called_with("hi")
					end
				)

				it(
					"should group calls and call the debounced function with the last arguments",
					function()
						local result = debounced("hi")

						assert.are.same(result, nil)

						local result2 = debounced("guys")

						assert.are.same(result2, nil)

						wait(100)
						clock:process()

						assert.spy(callSpy).was_called(1)
						assert.spy(callSpy).was_called_with("guys")

						local result3 = debounced("stuff")

						assert.are.same({[1] = "guys", n = 1}, result3)
					end
				)
			end
		)
		describe(
			"Throttle",
			function()
				local throttled

				before_each(
					function()
						throttled = Functions.throttle(callSpy, 100)
					end
				)

				it(
					"should be called immediately",
					function()
						assert.spy(callSpy).was_not_called()
						local result = throttled("hi")
						assert.spy(callSpy).was_called()
						assert.are.same(
							{
								n = 1,
								[1] = "hi"
							},
							result
						)
					end
				)

				it(
					"should not be called subsequently but return available args",
					function()
						local result = throttled("hi")

						assert.are.same(
							{
								n = 1,
								[1] = "hi"
							},
							result
						)

						wait(50)
						clock:process()

						result = throttled("ho")

						assert.spy(callSpy).was_called(1)
						assert.are.same(
							{
								n = 1,
								[1] = "hi"
							},
							result
						)
					end
				)

				it(
					"should be called again after the timeout",
					function()
						local result = throttled("hi")

						assert.are.same(
							{
								n = 1,
								[1] = "hi"
							},
							result
						)

						wait(50)
						clock:process()

						result = throttled("ho")

						assert.spy(callSpy).was_called(1)
						assert.are.same(
							{
								n = 1,
								[1] = "hi"
							},
							result
						)

						wait(100)
						clock:process()

						throttled("twit")
						result = throttled("twoo")

						assert.spy(callSpy).was_called(2)
						assert.are.same(
							{
								n = 1,
								[1] = "twit"
							},
							result
						)
					end
				)
			end
		)
		describe(
			"chain",
			function()
				it(
					"works with rodash functions",
					function()
						local fn =
							Functions.chain(Tables):map(
							function(value)
								return value + 2
							end
						):filter(
							function(value)
								return value >= 5
							end
						):sum()
						assert.equals("Chain::map::filter::sum", tostring(fn))
						assert.are.same(12, fn({1, 3, 5}))
					end
				)
				it(
					"works with custom functions",
					function()
						local chain =
							Functions.chain(
							{
								addTwo = Functions.chain(Tables):map(
									function(value)
										return value + 2
									end
								),
								sumGteFive = Functions.chain(Tables):filter(
									function(value)
										return value >= 5
									end
								):sum()
							}
						)
						local fn = chain:addTwo():sumGteFive()
						assert.equals("Chain::addTwo::sumGteFive", tostring(fn))
						assert.are.same(12, fn({1, 3, 5}))
					end
				)
			end
		)
	end
)
