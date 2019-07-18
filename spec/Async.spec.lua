local Async = require "Async"
local Promise = require "roblox-lua-promise"

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
			"all",
			function()
				it(
					"resolves for an array of promises",
					function()
						local one = Promise.resolve(1)
						local two = Promise.resolve(2)
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseResolves(
							Async.all({one, two, three}),
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
							Async.all({one, two, three}),
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
							Async.all({}),
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
						local one = Promise.resolve(1)
						local two = Promise.reject("Bad promise")
						local three =
							Async.delay(1):andThen(
							function()
								return 3
							end
						)
						advanceAndAssertPromiseRejects(Async.all({one, two, three}), "Bad promise")
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
			"wrapFn",
			function()
				it(
					"can wrap a function that returns in a promise",
					function()
						local function resolves()
							wait(1)
							return "good"
						end
						advanceAndAssertPromiseResolves(
							Async.wrapFn(resolves),
							function(result)
								assert.equal("good", result)
							end
						)
					end
				)
				it(
					"can wrap a function that errors in a promise",
					function()
						local function rejects()
							wait(1)
							error("Bad fn")
						end
						advanceAndAssertPromiseRejects(Async.wrapFn(rejects), "Bad fn")
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
						local onRetry = stub.new()
						local onDone = stub.new()
						local onFail = stub.new()
						local andThen = stub.new()
						local err = stub.new()
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
								return Promise.resolve("Success")
							end
						end
						local shouldRetry =
							spy.new(
							function()
								return true
							end
						)
						local onRetry = stub.new()
						local onDone = stub.new()
						local onFail = stub.new()
						local andThen = stub.new()
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
						assert.spy(onDone).was_called_with("Success", 9000)
						assert.equal(3, #onRetry.calls)
					end
				)
			end
		)
	end
)
