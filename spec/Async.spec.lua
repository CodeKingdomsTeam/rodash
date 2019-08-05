local Async = require "Async"
local Functions = require "Functions"
local Promise = require "roblox-lua-promise"
local match = require "luassert.match"

local function advanceAndAssertPromiseResolves(promise, assertion)
	local andThen = spy.new(assertion)
	local err = spy.new(warn)
	promise:andThen(andThen):catch(err)
	if tick() == 0 then
		assert.spy(andThen).was_not_called()
		wait(1)
		clock:process()
	end
	assert.spy(andThen).was_called()
	assert.spy(err).was_not_called()
end

local function advanceAndAssertPromiseRejects(promise, message)
	local err = spy.new(warn)
	promise:catch(err)
	if tick() == 0 then
		assert.spy(err).was_not_called()
		wait(1)
		clock:process()
	end
	assert(err.calls[1].vals[1]:find(message))
end

describe(
	"Async",
	function()
		before_each(
			function()
				clock:reset()
			end
		)
		describe(
			"parallel",
			function()
				it(
					"resolves for an array of promises",
					function()
						local one = Async.resolve(1)
						local two = Async.resolve(2)
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseResolves(
							Async.parallel({one, two, three}),
							function(result)
								assert.equal(tick(), 1)
								assert.are_same({1, 2, 3}, result)
							end
						)
					end
				)
				it(
					"resolves for a mixed array",
					function()
						local one = 1
						local two = 2
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseResolves(
							Async.parallel({one, two, three}),
							function(result)
								assert.equal(tick(), 1)
								assert.are_same({1, 2, 3}, result)
							end
						)
					end
				)
				it(
					"resolves for an empty array",
					function()
						wait(1)
						advanceAndAssertPromiseResolves(
							Async.parallel({}),
							function(result)
								assert.equal(0, #result)
							end
						)
					end
				)
				it(
					"rejects if any promise rejects",
					function()
						wait(1)
						local one = Async.resolve(1)
						local two = Promise.reject("Expected error")
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseRejects(Async.parallel({one, two, three}), "Expected error")
					end
				)
			end
		)
		describe(
			"resolve",
			function()
				it(
					"resolves for multiple return values",
					function()
						local andThen =
							spy.new(
							function()
							end
						)
						Async.resolve(1, 2, 3):andThen(andThen)
						assert.spy(andThen).called_with(1, 2, 3)
					end
				)
			end
		)
		describe(
			"parallelAll",
			function()
				it(
					"resolves for an object of promises",
					function()
						local one = Async.resolve(1)
						local two = Async.resolve(2)
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseResolves(
							Async.parallelAll({one = one, two = two, three = three}),
							function(result)
								assert.equal(tick(), 1)
								assert.are_same({one = 1, two = 2, three = 3}, result)
							end
						)
					end
				)
				it(
					"resolves for a mixed object",
					function()
						local one = 1
						local two = 2
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseResolves(
							Async.parallelAll({one = one, two = two, three = three}),
							function(result)
								assert.equal(tick(), 1)
								assert.are_same({one = 1, two = 2, three = 3}, result)
							end
						)
					end
				)
				it(
					"rejects if any promise rejects",
					function()
						wait(1)
						local one = Async.resolve(1)
						local two = Promise.reject("Expected error")
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseRejects(Async.parallelAll({one = one, two = two, three = three}), "Expected error")
					end
				)
			end
		)
		describe(
			"delay",
			function()
				it(
					"promise which resolves after a delay",
					function()
						advanceAndAssertPromiseResolves(
							Async.delay(1),
							function()
								assert.equal(tick(), 1)
							end
						)
					end
				)
			end
		)
		describe(
			"finally",
			function()
				it(
					"run after a resolution",
					function()
						local handler =
							spy.new(
							function()
							end
						)
						Async.finally(Async.resolve("ok"), handler)
						assert.spy(handler).called_with(true, "ok")
					end
				)
				it(
					"run after a rejection",
					function()
						local handler =
							spy.new(
							function()
							end
						)
						Async.finally(Promise.reject("bad"), handler)
						assert.spy(handler).called_with(false, "bad")
					end
				)
			end
		)
		describe(
			"async",
			function()
				it(
					"can wrap a function that returns in a promise",
					function()
						local function cooks(food)
							wait(1)
							return "hot-" .. food
						end
						advanceAndAssertPromiseResolves(
							Async.async(cooks)("bread"),
							function(result)
								assert.equal("hot-bread", result)
							end
						)
					end
				)
				it(
					"can wrap a function that errors in a promise",
					function()
						local function burns(food)
							wait(1)
							error("Burnt " .. food)
						end
						advanceAndAssertPromiseRejects(Async.async(burns)("bread"), "Burnt bread")
					end
				)
			end
		)
		describe(
			"race",
			function()
				it(
					"resolves immediately for no promises",
					function()
						local andThen =
							spy.new(
							function()
							end
						)
						Async.race({}, 0):andThen(andThen)
						assert.spy(andThen).called_with(match.is_same({}))
					end
				)
				it(
					"resolves first promise",
					function()
						advanceAndAssertPromiseResolves(
							Async.race(
								{
									Async.delay(1):andThen(Functions.returns("One")),
									Async.delay(2):andThen(Functions.returns("Two")),
									Async.delay(3):andThen(Functions.returns("Three"))
								}
							),
							function(result)
								assert.are_same({"One"}, result)
							end
						)
					end
				)
				it(
					"resolves two promises",
					function()
						advanceAndAssertPromiseResolves(
							Async.race(
								{
									Async.delay(0.6):andThen(Functions.returns("One")),
									Async.delay(3):andThen(Functions.throws("Unexpected Error")),
									Async.delay(0.5):andThen(Functions.returns("Three"))
								},
								2
							),
							function(result)
								assert.are_same({"Three", "One"}, result)
							end
						)
					end
				)
				it(
					"rejects when not enough promises found",
					function()
						advanceAndAssertPromiseRejects(
							Async.race(
								{
									Async.delay(0.8):andThen(Functions.returns("One")),
									Async.delay(0.6):andThen(Functions.throws("Expected Error")),
									Async.delay(0.5):andThen(Functions.returns("Three"))
								},
								2
							),
							"Expected Error"
						)
					end
				)
			end
		)
		describe(
			"timeout",
			function()
				it(
					"can timeout after a delay",
					function()
						local promise = Async.delay(2)
						local timeout = Async.timeout(promise, 1, "Expected Error")
						advanceAndAssertPromiseRejects(timeout, "Expected Error")
					end
				)
				it(
					"can resolve within delay",
					function()
						local promise = Async.delay(1):andThen(Functions.returns("Ok"))
						local timeout = Async.timeout(promise, 2)
						advanceAndAssertPromiseResolves(timeout)
					end
				)
				it(
					"can reject",
					function()
						local promise = Async.delay(1):andThen(Functions.throws("Expected Error"))
						local timeout = Async.timeout(promise, 10)
						advanceAndAssertPromiseRejects(timeout, "Expected Error")
					end
				)
			end
		)
		describe(
			"retryWithBackoff",
			function()
				it(
					"calls a fn repeatedly until it fails",
					function()
						local n = 0
						local function getPromise()
							n = n + 1
							return Promise.reject("Fail " .. n)
						end
						local shouldRetry =
							spy.new(
							function()
								return true
							end
						)
						local onRetry =
							spy.new(
							function()
							end
						)
						local onDone =
							spy.new(
							function()
							end
						)
						local onFail =
							spy.new(
							function()
							end
						)
						local andThen =
							spy.new(
							function()
							end
						)
						local err =
							spy.new(
							function()
							end
						)
						Async.retryWithBackoff(
							getPromise,
							{
								maxTries = 3,
								retryExponentInSeconds = 1,
								retryConstantInSeconds = 1,
								randomStream = Random.new(),
								shouldRetry = shouldRetry,
								onRetry = onRetry,
								onDone = onDone,
								onFail = onFail
							}
						):andThen(andThen):catch(err)
						assert.spy(andThen).was_not_called()
						assert.spy(onRetry).was_called_with(2, "Fail 1")
						wait(2)
						clock:process()
						assert.spy(andThen).was_not_called()
						assert.spy(onRetry).was_called_with(3, "Fail 2")
						wait(3)
						clock:process()
						assert.spy(andThen).was_not_called()
						assert.equal(2, #onRetry.calls)
						assert.spy(andThen).was_not_called()
						assert.spy(onFail).was_called_with("Fail 3")
						assert.spy(onDone).was_not_called()
						assert(err.calls[1].vals[1]:find("Fail 3"))
						assert.equal(2, #onRetry.calls)
					end
				)
				it(
					"calls a fn repeatedly until it succeeds",
					function()
						local n = 0
						local function getPromise()
							n = n + 1
							if n < 4 then
								return Promise.reject("Fail " .. n)
							else
								return Async.resolve("Success")
							end
						end
						local shouldRetry =
							spy.new(
							function()
								return true
							end
						)
						local onRetry =
							spy.new(
							function()
							end
						)
						local onDone =
							spy.new(
							function()
							end
						)
						local onFail =
							spy.new(
							function()
							end
						)
						local andThen =
							spy.new(
							function()
							end
						)
						Async.retryWithBackoff(
							getPromise,
							{
								maxTries = 5,
								retryExponentInSeconds = 1,
								retryConstantInSeconds = 1,
								randomStream = Random.new(),
								shouldRetry = shouldRetry,
								onRetry = onRetry,
								onDone = onDone,
								onFail = onFail
							}
						):andThen(andThen)
						assert.spy(andThen).was_not_called()
						assert.spy(onRetry).was_called_with(2, "Fail 1")
						wait(2)
						clock:process()
						assert.spy(andThen).was_not_called()
						assert.spy(onRetry).was_called_with(3, "Fail 2")
						wait(3)
						clock:process()
						assert.spy(andThen).was_not_called()
						assert.spy(onRetry).was_called_with(4, "Fail 3")
						wait(4)
						clock:process()
						assert.spy(andThen).was_called_with("Success")
						assert.spy(onFail).was_not_called()
						assert.spy(onDone).was_called_with("Success", 9)
						assert.equal(3, #onRetry.calls)
					end
				)
			end
		)
	end
)
