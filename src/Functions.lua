local Tables = require(script.Parent.Tables)

local Functions = {}

function Functions.defaultSerializeArgs(fnArgs)
	return Tables.serialize(fnArgs)
end

--[[
	Cache results of a function such that subsequent calls return the cached result rather than
	call the function again.

	By default, a cached result is stored for each separate combination of serialized input args.
	Optionally memoize takes a serializeArgs function which should return a key that the result
	should be cached with for a given call signature. Return nil to avoid caching the result.
]]
function Functions.memoize(fn, serializeArgs)
	assert(type(fn) == "function")
	serializeArgs = serializeArgs or Functions.defaultSerializeArgs
	assert(type(serializeArgs) == "function")
	local cache = {}
	local proxyFunction = function(...)
		local proxyArgs = {...}
		local cacheKey = serializeArgs(proxyArgs)
		if cacheKey == nil then
			return fn(...)
		else
			if cache[cacheKey] == nil then
				cache[cacheKey] = fn(...)
			end
			return cache[cacheKey]
		end
	end
	return proxyFunction
end

function Functions.setTimeout(fn, secondsDelay)
	local cleared = false
	local timeout
	delay(
		secondsDelay,
		function()
			if not cleared then
				fn(timeout)
			end
		end
	)
	timeout = {
		clear = function()
			cleared = true
		end
	}
	return timeout
end

function Functions.setInterval(fn, secondsDelay)
	local timeout
	local callTimeout
	callTimeout = function()
		timeout =
			Functions.setTimeout(
			function()
				callTimeout()
				fn(timeout)
			end,
			secondsDelay
		)
	end
	callTimeout()

	return {
		clear = function()
			timeout:clear()
		end
	}
end

--[[
	Creates a debounced function that delays invoking fn until after secondsDelay seconds have elapsed since the last time the debounced function was invoked.
]]
function Functions.debounce(fn, secondsDelay)
	assert(Functions.isCallable(fn))
	assert(type(secondsDelay) == "number")

	local lastInvocation = 0
	local lastResult = nil

	return function(...)
		local args = {...}

		lastInvocation = lastInvocation + 1

		local thisInvocation = lastInvocation
		delay(
			secondsDelay,
			function()
				if thisInvocation ~= lastInvocation then
					return
				end

				lastResult = fn(unpack(args))
			end
		)

		return lastResult
	end
end

--[[
	Creates a throttle function that drops any repeat calls within a cooldown period and instead returns the result of the last call
]]
function Functions.throttle(fn, secondsCooldown)
	assert(Functions.isCallable(fn))
	assert(type(secondsCooldown) == "number")
	assert(secondsCooldown > 0)

	local cached = false
	local lastResult = nil

	return function(...)
		if not cached then
			cached = true
			lastResult = fn(...)
			delay(
				secondsCooldown,
				function()
					cached = false
				end
			)
		end
		return lastResult
	end
end

function Functions.isCallable(thing)
	return type(thing) == "function" or
		(type(thing) == "table" and getmetatable(thing) and getmetatable(thing).__call ~= nil)
end

return Functions
