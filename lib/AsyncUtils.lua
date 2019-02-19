local TableUtils = require(script.Parent.TableUtils)
local Promise = require(script.Parent.Parent.Promise)
local AsyncUtils = {}

local baseRandomStream = Random.new()

function AsyncUtils.parallel(things)
	local promises =
		TableUtils.Map(
		things,
		function(thing)
			if Promise.is(thing) then
				return thing
			else
				return Promise.resolve(thing)
			end
		end
	)
	return Promise.all(promises)
end

function AsyncUtils.delay(delayInSeconds)
	return Promise.new(
		function(resolve)
			delay(
				delayInSeconds,
				function()
					resolve()
				end
			)
		end
	)
end

function AsyncUtils.wrapAsync(fn)
	return Promise.new(
		function(resolve, reject)
			coroutine.wrap(
				function()
					local ok, result = pcall(fn)
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

function AsyncUtils.retryWithBackoff(getPromise, backoffOptions)
	local function backoffThenRetry()
		local waitTime =
			(backoffOptions.retryPeriodInSeconds ^ backoffOptions.attemptNumber) * backoffOptions.randomStream:NextNumber() +
			backoffOptions.initialDelayInSeconds
		backoffOptions.onRetry(waitTime)
		return AsyncUtils.delay(waitTime):andThen(
			function()
				return AsyncUtils.retryWithBackoff(
					getPromise,
					TableUtils.Assign(
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

	local function getDurationMs()
		return math.floor((tick() - backoffOptions.startTime) * 1000)
	end

	backoffOptions =
		TableUtils.Assign(
		{
			startTime = tick(),
			maxTries = 5,
			attemptNumber = 0,
			retryPeriodInSeconds = 5,
			initialDelayInSeconds = 2,
			randomStream = baseRandomStream,
			onRetry = function()
			end,
			onDone = function()
			end,
			onFail = function()
			end
		},
		backoffOptions
	)
	assert(backoffOptions.maxTries > 0, "You must try a function at least once")
	local ok, response =
		pcall(
		function()
			return getPromise()
		end
	)
	if not ok then
		if backoffOptions.maxTries == 1 then
			backoffOptions.onFail(response)
			return Promise.reject(response)
		else
			return backoffThenRetry()
		end
	elseif not Promise.is(response) then
		backoffOptions.onDone(response, getDurationMs())
		return Promise.resolve(response)
	elseif backoffOptions.maxTries == 1 then
		return response:catch(
			function(message)
				backoffOptions.onFail(message)
				error(message)
			end
		)
	else
		return response:andThen(
			function(response)
				backoffOptions.onDone(response, getDurationMs())
				return response
			end
		):catch(backoffThenRetry)
	end
end

return AsyncUtils
