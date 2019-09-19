--[[
	Building upon the functionality of [Roblox Lua Promise](https://github.com/LPGhatguy/roblox-lua-promise)
	and borrowing ideas from [Bluebird](http://bluebirdjs.com/docs/getting-started.html),
	these functions improve the experience of working with asynchronous code in Roblox.

	Promises can be thought of as a variable whose value might not be known immediately when they
	are defined. They allow you to pass around a "promise" to the value, rather than yielding or
	waiting until the value has resolved. This means you can write functions which pass any
	promises to right places in your code, and delay running any code which requires the value
	until it is ready.
]]
local t = require(script.Parent.Parent.t)
local Tables = require(script.Parent.Tables)
local Functions = require(script.Parent.Functions)
local Promise = require(script.Parent.Parent.Promise)
local Async = {}

local baseRandomStream = Random.new()

--[[
	Yields completion of a promise `promise:await()`, but returns immediately with the value if it
	isn't a promise.
	@trait Yieldable
	@example
		local heat = function(item)
			return dash.delay(1).returns("hot " .. item)
		end
		local recipe = {"wrap", heat("steak"), heat("rice")}
		local burrito = dash.map(recipe, dash.await)
		dash.debug("{:#?}", burrito)
		-->> {"wrap", "hot steak", "hot rice"} (2 seconds)
]]
--: <T>(Promise<T> | T -> yield T)
function Async.await(value)
	if Async.isPromise(value) then
		return value:await()
	end
	return value
end

--[[
	Wraps `Promise.is` but catches any errors thrown in attempting to ascertain if _value_ is a
	promise, which will occur if the value throws when trying to access missing keys.
]]
--: <T>(T -> bool)
function Async.isPromise(value)
	local ok, isPromise =
		pcall(
		function()
			return Promise.is(value)
		end
	)
	return ok and isPromise
end

--[[
    Given an _array_ of values, this function returns a promise which
    resolves once all of the array elements have resolved, or rejects
    if any of the array elements reject.
	
	@returns an array mapping the input to resolved elements.
	@example
		local heat = function(item)
			local oven = dash.parallel({item, dash.delay(1)})
			return oven:andThen(function(result)
				return "hot-" .. result[1] 
			end)
		end
		local meal =dash.parallel({heat("cheese"), "tomato"})
		meal:await() --> {"hot-cheese", "tomato"} (1 second later)
	@rejects passthrough
	@usage This function is like `Promise.all` but allows objects in the array which aren't
		promises. These are considered resolved immediately.
	@usage Promises that return nil values will cause the return array to be sparse.
	@see [Promise](https://github.com/LPGhatguy/roblox-lua-promise)
]]
--: <T>((Promise<T> | T)[] -> Promise<T[]>)
function Async.parallel(array)
	assert(t.table(array), "BadInput: array must be an array")
	local promises =
		Tables.map(
		array,
		function(object)
			if Async.isPromise(object) then
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
	
	@returns a dictionary mapping the input to resolved elements.
	@rejects passthrough
	@example
		local heat = function(item)
			local oven = dash.parallel({item, dash.delay(1)})
			return oven:andThen(function(result)
				return "hot-" .. result[1] 
			end)
		end
		local toastie = dash.parallelAll({
			bread = "brown",
			filling = heat("cheese")
		})
		toastie:await() --> {bread = "brown", filling = "hot-cheese"} (1 second later)
	@example
		local fetch = dash.async(function(url)
			local HttpService = game:GetService("HttpService")
			return HttpService:GetAsync(url)
		end)
		dash.parallelAll({
			main = fetch("http://example.com/burger"),
			side = fetch("http://example.com/fries") 
		}):andThen(function(meal)
			print("Meal", dash.pretty(meal))
		end)
	@usage Values which are not promises are considered resolved immediately.
]]
--: <T>((Promise<T> | T){}) -> Promise<T{}>
function Async.parallelAll(dictionary)
	assert(t.table(dictionary), "BadInput: dictionary must be a table")
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
			return dash.resolve("mashed", veg)
		end
		mash("potato"):andThen(function(style, veg)
			dash.debug("{} was {}", veg, style)
		end)
		-- >> potato was mashed
	@usage As `dash.resolve(promise) --> promise`, this function can also be used to ensure a value is a promise.
]]
--: T -> Promise<T>
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
	@example
		-- Here promise resolves to the result of fetch, or resolves to "No burger for you" if the
		-- fetch takes more than 2 seconds.
		local fetch = dash.async(function(url)
			local HttpService = game:GetService("HttpService")
			return HttpService:GetAsync(url)
		end)
		local promise = dash.race(
			dash.delay(2):andThen(dash.returns("No burger for you"),
			fetch("http://example.com/burger")
		)
	@usage Note that Promises which return nil values will produce a sparse array.
	@usage The size of _array_ must be equal to or larger than _n_.
	@see `dash.async`
]]
--: <T>(Promise<T>[], uint?) -> Promise<T[]>
function Async.race(array, n)
	n = n or 1
	assert(n >= 0, "BadInput: n must be an integer >= 0")
	assert(#array >= n, "OutOfBoundsError: n must be less than #array")
	local function handler(resolve, reject)
		local results = {}
		local function finally(ok, result)
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
		local function awaitElement(promise)
			Async.finally(promise, finally)
		end
		Tables.map(array, awaitElement)
		if n == 0 then
			resolve(results)
		end
	end
	return Promise.new(handler)
end

--[[
	Returns a promise which completes after the _promise_ input has completed, regardless of
	whether it has resolved or rejected. The _fn_ is passed `true` if the promise did not error,
	otherwise `false`, and the promise's _result_ as the second argument.
	@param fn _function(ok, result)_
	@example
		local getHunger = dash.async(function(player)
			if player.health == 0 then
				error("Player is dead!")
			else
				return game.ReplicatedStorage.GetHunger:InvokeServer( player )
			end
		end)
		local localPlayer = game.Players.LocalPlayer
		local isHungry = getHunger( localPlayer ):finally(function(isAlive, result)
			return isAlive and result < 5
		end)
]]
--: <T, R>(Promise<T>, (bool, T) -> R) -> Promise<R>
function Async.finally(promise, fn)
	assert(Async.isPromise(promise), "BadInput: promise must be a promise")
	return promise:andThen(
		function(...)
			return fn(true, ...)
		end
	):catch(
		function(...)
			return fn(false, ...)
		end
	)
end

--[[
	Returns a promise which never resolves or rejects.
	@usage Useful in combination with `dash.race` where a resolution or rejection should be ignored.
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
		let eatGreens = function() return dash.never end
		dash.timeout(eatGreens(), 10, "TasteError"):await()
		--> throws "TasteError" (after 10s)
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
	Like `dash.compose` but takes functions that can return a promise. Returns a promise that resolves
	once all functions have resolved. Like compose, functions receive the resolution of the
	previous promise as argument(s).
	@example
		local function fry(item)
			return dash.delay(1):andThen(dash.returns("fried " .. item))
		end
		local function cheesify(item)
			return dash.delay(1):andThen(dash.returns("cheesy " .. item))
		end
		local prepare = dash.series(fry, cheesify)
		prepare("nachos"):await() --> "cheesy fried nachos" (after 2s)
	@see `dash.parallel`
	@see `dash.delay`
]]
--: <A>((...A -> Promise<A>)[]) -> ...A -> Promise<A>
function Async.series(...)
	local fnCount = select("#", ...)
	local fns = {...}
	return Async.async(
		function(...)
			local result = {fns[1](...)}
			for i = 2, fnCount do
				result = {Async.resolve(fns[i](unpack(result))):await()}
			end
			return unpack(result)
		end
	)
end

--[[
	Returns a promise which resolves after the given delayInSeconds.
	@example dash.delay(1):andThen(function() print("Delivered") end)
	-->> Delivered (1 second later)
]]
--: number -> Promise<nil>
function Async.delay(delayInSeconds)
	assert(t.number(delayInSeconds), "BadInput: delayInSeconds must be a number")
	return Promise.new(
		function(resolve)
			delay(delayInSeconds, resolve)
		end
	)
end

--[[
	Wraps a function which may yield in a promise. When run, async calls the
	the function in a coroutine and resolves with the output of the function
	after any asynchronous actions, and rejects if the function throws an error.
	@rejects passthrough
	@example
		local fetch = dash.async(function(url)
			local HttpService = game:GetService("HttpService")
			return HttpService:GetAsync(url)
		end)
		fetch("http://example.com/burger"):andThen(function(meal)
			print("Meal:", meal)
		end)
		-->> Meal: Cheeseburger (ideal response)
	@usage With `promise:await` the `dash.async` function can be used just like the async-await pattern in languages like JS.
	@see `dash.parallel`
]]
--: <T, A>(Yieldable<T, A>) -> ...A -> Promise<T>
function Async.async(fn)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
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
	Wraps any functions in _dictionary_ with `dash.async`, returning a new dictionary containing
	functions that return promises when called rather than yielding.
	@example
		local http = dash.asyncAll(game:GetService("HttpService"))
		http:GetAsync("http://example.com/burger"):andThen(function(meal)
			print("Meal", meal)
		end)
		-->> Meal: Cheeseburger (some time later)
	@example
		local buyDinner = dash.async(function()
			local http = dash.asyncAll(game:GetService("HttpService"))
			local order = dash.parallelAll({
				main = http:GetAsync("http://example.com/burger"),
				side = http:GetAsync("http://example.com/fries")
			})
			return http:PostAsync("http://example.com/purchase", order:await())
		end)
		buyDinner():await() --> "Purchased!" (some time later)
	@see `dash.async`
	@see `dash.parallelAll`
]]
--: <T, A>(Yieldable<T, A>{}) -> (...A -> Promise<T>){}
function Async.asyncAll(dictionary)
	assert(t.table(dictionary), "BadInput: dictionary must be a table")
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
	and error or the promise rejects. The retry behavior can be adapted using
	backoffOptions, which can customize the maximum number of retries and the backoff
	timing of the form `[0, x^attemptNumber] + y` where _x_ is an exponent that produces
	a random exponential delay and _y_ is a constant delay.
	
	@rejects passthrough
	@example
		-- Use dash.retryWithBackoff to retry a GET request repeatedly.
		local fetchPizza = dash.async(function()
			local HttpService = game:GetService("HttpService")
			return HttpService:GetAsync("https://example.com/pizza")
		end)
		dash.retryWithBackoff(fetchPizza, {
			maxTries = 3,
			onRetry = function(waitTime, errorMessage)
				print("Failed to fetch due to", errorMessage)
				print("Retrying in ", waitTime)
			end
		}):andThen(function(resultingPizza) 
			print("Great, you have: ", resultingPizza)
		end)
]]
--: <T>(Async<T>, BackoffOptions<T>) -> Promise<T>
function Async.retryWithBackoff(asyncFn, backoffOptions)
	assert(Functions.isCallable(asyncFn), "BadInput: asyncFn must be callable")
	local function backoffThenRetry(errorMessage)
		local waitTime =
			(backoffOptions.retryExponentInSeconds ^ backoffOptions.attemptNumber) * backoffOptions.randomStream:NextNumber() +
			backoffOptions.retryConstantInSeconds
		backoffOptions.onRetry(waitTime, errorMessage)
		return Async.delay(waitTime):andThen(
			function()
				return Async.retryWithBackoff(
					asyncFn,
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
	assert(backoffOptions.maxTries > 0, "BadInput: maxTries must be > 0")

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
		return Async.isPromise(response) and response or Promise.resolve(response)
	end

	local ok, response =
		pcall(
		function()
			return asyncFn()
		end
	)

	if ok then
		if Async.isPromise(response) then
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
