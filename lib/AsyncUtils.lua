local TableUtils = require(script.Parent.TableUtils)
local AsyncUtils = {}

local baseRandomStream = Random.new()

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
	backoffOptions =
		TableUtils.Assign(
		{
			maxTries = 3,
			attemptNumber = 0,
			retryPeriodInSeconds = 5,
			initialDelayInSeconds = 2,
			randomStream = baseRandomStream,
			onRetry = function()
			end
		},
		backoffOptions
	)
	assert(backoffOptions.maxTries > 0, "You must try a function at least once")
	local response = getPromise()
	if backoffOptions.maxTries == 1 then
		return response
	else
		return response:catch(
			function()
				local waitTime =
					(backoffOptions.retryPeriodInSeconds ^ backoffOptions.attemptNumber) * backoffOptions.randomStream:NextNumber() +
					backoffOptions.initialDelayInSeconds
				backoffOptions.onRetry(waitTime)
				wait(waitTime)
				AsyncUtils.tryWithBackoff(
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
end

return AsyncUtils
