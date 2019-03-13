local TableUtils = require(script.Parent.TableUtils)

local FunctionUtils = {}

function FunctionUtils.defaultSerializeArgs(fnArgs)
	return TableUtils.serialize(fnArgs)
end

function FunctionUtils.memoize(fn, serializeArgs)
	serializeArgs = serializeArgs or FunctionUtils.defaultSerializeArgs
	local cache = {}
	local proxyFunction = function(...)
		local proxyArgs = {...}
		local cacheKey = serializeArgs(proxyArgs)
		if cacheKey ~= nil then
			if cache[cacheKey] == nil then
				cache[cacheKey] = fn(...)
			end
			return cache[cacheKey]
		end
	end
	return proxyFunction
end

--[[
	Creates a debounced function that delays invoking fn until after secondsDelay seconds have elapsed since the last time the debounced function was invoked.
]]
function FunctionUtils.debounce(fn, secondsDelay)
	assert(type(fn) == "function" or (type(fn) == "table" and getmetatable(fn) and getmetatable(fn).__call ~= nil))
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
function FunctionUtils.throttle(fn, secondsCooldown)
	assert(type(fn) == "function" or (type(fn) == "table" and getmetatable(fn) and getmetatable(fn).__call ~= nil))
	assert(type(secondsCooldown) == "number")

	local cached = false
	local lastResult = nil

	return function(...)
		if not cached then
			lastResult = fn(...)
			cached = true
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

return FunctionUtils
