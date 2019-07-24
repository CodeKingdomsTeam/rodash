--[[
	Building upon the functionality of [Roblox Lua Promise](https://github.com/LPGhatguy/roblox-lua-promise)
	and borrowing ideas from [Bluebird](http://bluebirdjs.com/docs/getting-started.html),
	these functions improve the experience of working with asynchronous code in Roblox.
]]
local t = require(script.Parent.t)
local Tables = require(script.Tables)
local Functions = require(script.Functions)
local Promise = require(script.Parent.Promise)
local Async = {}

local baseRandomStream = Random.new()

--[[
    Given an _array_ of values, this function returns a promise which
    resolves once all of the array elements have resolved, or rejects
    if any of the array elements reject.
	
	@returns an array mapping the input to resolved elements.
	@example
		local heat = function( item )
			local oven = _.parallel({item, _.delay(1)})
			return oven:andThen(function( result )
				return "hot-" .. result[1] 
			end)
		end
		local meal =_.parallel({heat("cheese"), "tomato"})
		meal:await() --> {"hot-cheese", "tomato"} (1 second later)
	@rejects passthrough
	@usage
		This function is like `Promise.all` but allows objects in the array which aren't promises. These are considered resolved immediately.
		Promises that return nil values will cause the return array to be sparse.
]]
--: <T>((Promise<T> | T)[]) -> Promise<T[]>
function Async.parallel(array)
	assert(t.table(array))
	local promises =
		Tables.map(
		array,
		function(object)
			if Promise.is(object) then
				return object
			else
				return Promise.resolve(object)
			end
		end
	)
	return Promise.all(promises)
end

--[[
    Given a _dictionary_ of values, this function returns a promise which
    resolves once all of the values in the dictionary have resolved, or rejects
    if any of them are promises that reject.
	
	@returns an array mapping the input to resolved elements.
	@rejects passthrough
	@example
		local heat = function( item )
			local oven = _.parallel({item, _.delay(1)})
			return oven:andThen(function( result )
				return "hot-" .. result[1] 
			end)
		end
		local toastie = _.props({
			bread = "brown",
			filling = heat("cheese")
		})
		toastie:await() --> {bread = "brown", filling = "hot-cheese"} (1 second later)
	@usage Values which are not promises are considered resolved immediately.
]]
--: <T>((Promise<T> | T){}) -> Promise<T{}>
function Async.props(dictionary)
	assert(t.table(dictionary))
	local keys = Tables.keys(dictionary)
	local values =
		Tables.map(
		keys,
		function(key)
			return dictionary[key]
		end
	)
	return Async.parallel(values):andThen(
		function(output)
			return Tables.keyBy(
				output,
				function(value, i)
					return keys[i]
				end
			)
		end
	)
end

--[[
	Like `Promise.resolve` but can take any number of arguments.
	@example
		local function mash( veg )
			return _.resolve("mashed", veg)
		end
		mash("potato"):andThen(function(style, veg)
			_.print("{} was {}", veg, style)
		end)
		-- >> potato was mashed

]]
--: ...T -> Promise<...T>
function Async.resolve(...)
	local args = {...}
	return Promise.new(
		function(resolve)
			resolve(unpack(args))
		end
	)
end

--[[
	Returns a promise which completes after the first promise in the _array_ input completes, or
	first _n_ promises if specified. If any promise rejects, race rejects with the first rejection.
	@param n the number of promises required (default = 1)
	@returns an array containing the first n resolutions, in the order that they resolved.
	@rejects passthrough
	@throws OutOfBoundsError - if the number of required promises is greater than the input length.
	@usage
		Promises which return nil values are ignored due to the in-order constraint.
		The size of _array_ must be equal to or larger than _n_.
]]
--: <T>(Promise<T>[], uint?) -> Promise<T[]>
function Async.race(array, n)
	n = n or 1
	assert(n >= 0)
	assert(#array >= n, "OutOfBoundsError")
	return Promise.new(
		function(resolve, reject)
			local results = {}
			Tables.map(
				array,
				function(promise)
					Async.finally(
						promise,
						function(ok, result)
							if #results < n then
								if ok then
									table.insert(results, result)
									if #results == n then
										resolve(results)
									end
								else
									reject(result)
								end
							end
						end
					)
				end
			)
			if n == 0 then
				resolve(results)
			end
		end
	)
end

--[[
	Returns a promise which completes after the _promise_ input has completed, regardless of
	whether it has resolved or rejected.
	@param fn _function(ok, result)_ 
	@example
		local getHunger = _.async(function( player )
			if player.health == 0 then
				error("Player is dead!")
			else
				return game.ReplicatedStorage.GetHunger:InvokeServer( player )
			end
		end)
		local localPlayer = game.Players.LocalPlayer
		local isHungry = getHunger( localPlayer ):finally(function( isAlive, result )
			return isAlive and result < 5
		end)
]]
--: <T>(Promise<...T>, (bool, ...T) -> nil) -> Promise<nil>
function Async.finally(promise, fn)
	assert(Promise.is(promise))
	return promise:andThen(
		function(...)
			fn(true, ...)
		end
	):catch(
		function(...)
			fn(false, ...)
		end
	)
end

--[[
	Returns a promise which never resolves or rejects.
	@usage Useful in combination with `_.race` where a resolution or rejection should be ignored.
]]
--: () -> never
function Async.never()
	return Promise.new(Functions.noop)
end

--[[
	Resolves to the result of `promise` if it resolves before the deadline, otherwise rejects with
	an error, which can be optionally customized.
	@param timeoutMessage (default = "TimeoutError")
	@rejects **TimeoutError** - or _timeoutMessage_
	@example
		let eatGreens = function() return _.never end
		_.timeout(eatGreens(), 10, "TasteError")
]]
--: <T>(Promise<T>, number, string?) -> Promise<T>
function Async.timeout(promise, deadlineInSeconds, timeoutMessage)
	return Async.race(
		{
			promise,
			Async.delay(deadlineInSeconds):andThen(Functions.throws(timeoutMessage or "TimeoutError"))
		}
	)
end

--[[
	Returns a promise which resolves after the given delayInSeconds.
	@example _.delay(1):andThen(function() print("Delivered") end)
	-->> Delivered (1 second later)
]]
--: number -> Promise<nil>
function Async.delay(delayInSeconds)
	assert(t.number(delayInSeconds))
	return Promise.new(
		function(resolve)
			delay(delayInSeconds, resolve)
		end
	)
end

--[[
    Returns a promise for a function which may yield. async calls the
    the function in a coroutine and resolves with the output of the function
	after any asynchronous actions, and rejects if the function throws an error.
	@rejects passthrough
	@example
		local fetch = _.async(function( url )
			local HttpService = game:GetService("HttpService")
			return HttpService:GetAsync(url)
		end)
		_.props({
			main = fetch("http://example.com/burger"),
			side = fetch("http://example.com/fries") 
		}):andThen(function( meal )
			print("Meal", _.pretty(meal))
		end)
		-->> {burger = "Cheeseburger", fries = "Curly fries"} (ideal response)
	@usage Used alongside `promise:await`, the `_.async` function forms an equivalence with the `async await` pattern in languages like JS.
]]
--: <T, Args>(Yieldable<T, ...Args>) -> (...Args) -> Promise<T>
function Async.async(fn)
	assert(Functions.isCallable(fn))
	return function(...)
		local callArgs = {...}
		return Promise.new(
			function(resolve, reject)
				coroutine.wrap(
					function()
						local ok, result = pcall(fn, unpack(callArgs))
						if ok then
							resolve(result)
						else
							reject(result)
						end
					end
				)()
			end
		)
	end
end

--[[
	Wraps any functions in _dictionary_ with `_.async`, returning a new dictionary containing
	functions that return promises when called rather than yielding.
	@example
		local buyDinner = _.async(function()
			local http = _.asyncAll(game:GetService("HttpService"))
			local order = _.props({
				main = http:GetAsync("http://example.com/burger"),
				side = http:GetAsync("http://example.com/fries")
			})
			order:await()
			return http:PostAsync("http://example.com/purchase", order)
		end)
		buyDinner():await() --> "Purchased!" (some time later)
]]
--: <T, Args>(Yieldable<T, ...Args>{}) -> (...Args -> Promise<T>){}
function Async.asyncAll(dictionary)
	assert(t.table(dictionary))
	local result =
		Tables.map(
		dictionary,
		function(value)
			if Functions.isCallable(value) then
				return Async.async(value)
			else
				return value
			end
		end
	)
	setmetatable(result, getmetatable(dictionary))
	return result
end

--[[
    Try running a function which returns a promise and retry if the function throws
    and error or the promise rejects. The retry behaviour can be adapted using
    backoffOptions, which can customize the maximum number of retries and the backoff
    timing of the form `[0, x^attemptNumber] + y` where _x_ is an exponent that produces
    a random exponential delay and _y_ is a constant delay.

	#### Backoff Options
	|Option|Type|Description|
	|---|---|---|
    | **maxTries** | _int_ | how many tries (including the first one) the function should be called |
    | **retryExponentInSeconds** | _number_ | customize the backoff exponent |
	| **retryConstantInSeconds** | _number_ | customize the backoff constant |
    | **randomStream** | _Random_ | use a Roblox "Random" instance to control the backoff |
	| **shouldRetry(response)** | _T -> bool_ | called if maxTries > 1 to determine whether a retry should occur |
    | **onRetry(waitTime, errorMessage)** | _(number, string) -> nil_ | a hook for when a retry is triggered, with the delay before retry and error message which caused the failure |
    | **onDone(response, durationInSeconds)** | _(T, number) -> nil_ | a hook for when the promise resolves |
	| **onFail(errorMessage)** | _string -> nil_ | a hook for when the promise has failed and no more retries are allowed |
	
	@rejects passthrough
]]
--: <T>(() -> Promise<T>, BackoffOptions) -> Promise<T>
function Async.retryWithBackoff(getPromise, backoffOptions)
	assert(Functions.isCallable(getPromise))
	local function backoffThenRetry(errorMessage)
		local waitTime =
			(backoffOptions.retryExponentInSeconds ^ backoffOptions.attemptNumber) * backoffOptions.randomStream:NextNumber() +
			backoffOptions.retryConstantInSeconds
		backoffOptions.onRetry(waitTime, errorMessage)
		return Async.delay(waitTime):andThen(
			function()
				return Async.retryWithBackoff(
					getPromise,
					Tables.assign(
						{},
						backoffOptions,
						{
							maxTries = backoffOptions.maxTries - 1,
							attemptNumber = backoffOptions.attemptNumber + 1
						}
					)
				)
			end
		)
	end

	local function getDurationInSeconds()
		return tick() - backoffOptions.startTime
	end

	backoffOptions =
		Tables.assign(
		{
			startTime = tick(),
			maxTries = 5,
			attemptNumber = 0,
			retryExponentInSeconds = 5,
			retryConstantInSeconds = 2,
			randomStream = baseRandomStream,
			onRetry = function()
			end,
			onDone = function()
			end,
			onFail = function()
			end,
			shouldRetry = function()
				return true
			end
		},
		backoffOptions
	)
	assert(backoffOptions.maxTries > 0, "You must try a function at least once")

	local function shouldRetry(response)
		return backoffOptions.maxTries > 1 and backoffOptions.shouldRetry(response)
	end

	local function retryIfShouldElseCallOnFailAndReturn(response, failHandler)
		if shouldRetry(response) then
			return backoffThenRetry(response)
		else
			backoffOptions.onFail(response)
			return failHandler(response)
		end
	end

	local function callOnDoneAndReturnPromise(response)
		backoffOptions.onDone(response, getDurationInSeconds())
		return Promise.is(response) and response or Promise.resolve(response)
	end

	local ok, response =
		pcall(
		function()
			return getPromise()
		end
	)

	if ok then
		if Promise.is(response) then
			return response:catch(
				function(response)
					return retryIfShouldElseCallOnFailAndReturn(response, error)
				end
			):andThen(callOnDoneAndReturnPromise)
		else
			return callOnDoneAndReturnPromise(response)
		end
	else
		return retryIfShouldElseCallOnFailAndReturn(response, Promise.reject)
	end
end

return Async
