--[[
	Utility functions and building blocks for functional programming styles.
]]
local Tables = require(script.Tables)

local Functions = {}

--[[
	A simple function that does nothing, and returns nil.
	@usage Shorthand for `function() end`.
]]
--: () -> nil
function Functions.noop()
end

--[[
	A simple function that does nothing, but returns its input parameters.
	@trait Chainable
	@usage This is typically referred to as the "identity" function.
]]
--: <A>(...A) -> ...A
function Functions.id(...)
	return ...
end

--[[
	Returns a function that when called, returns the original input parameters.
	@trait Chainable
	@example
		findPlayer("builderman"):andThen(_.returns("Found Dave!"))
		--> "Found Dave!" (soon after)
	@usage Useful for when you want a callback to discard the arguments passed in and instead use static ones.
]]
--: <A>(...A) -> () -> ...A
function Functions.returns(...)
	local args = {...}
	return function()
		return unpack(args)
	end
end

--[[
	Returns a function that wraps the input _fn_ but only passes the first argument to it.
]]
--: <A, B>((A) -> B) -> A -> B
function Functions.unary(fn)
	return function(first)
		return fn(first)
	end
end

--[[
	Returns a function that when called, throws the original message.
	@example
		findPlayer("builderman"):andThen(_.throws("DaveNotFound"))
		--!> "DaveNotFound" (soon after)
	@usage Useful for when you want a callback to discard the arguments passed in and instead use static ones.
]]
--: string -> () -> fail
function Functions.throws(errorMessage)
	return function()
		error(errorMessage)
	end
end

--[[
	Takes a function _fn_ and binds _arguments_ to the head of the _fn_ argument list.
	Returns a function which executes _fn_, passing the bound arguments supplied, followed by any
	dynamic arguments.
	@example
		local function damagePlayer( player, amount )
			player:Damage(amount)
		end
		local damageLocalPlayer = _.bind(damagePlayer, game.Players.LocalPlayer)
		damageLocalPlayer(5)
]]
--: <T, A, B>(((A..., B...) -> T, ...A) -> ...B -> T
function Functions.bind(fn, ...)
	local args = {...}
	return function(...)
		return fn(unpack(args), ...)
	end
end

--[[
	Takes a chainable function _fn_ and binds _arguments_ to the tail of the _fn_ argument list.
	Returns a function which executes _fn_, passing a subject ahead of the bound arguments supplied.
	@example
		local filterHurtPlayers = _.bindTail(_.filter, function(player)
			return player.Health < player.MaxHealth
		end)
		local getName = _.bindTail(_.map, function(player)
			return player.Name
		end)
		local filterHurtNames = _.compose(filterHurtPlayers, getName)
		filterHurtNames(game.Players) --> {"Frodo", "Boromir"}	
	@usage Chainable rodash function feeds are mapped to `_.fn`, such as `_.fn.map(handler)`.
]]
--: <T, A>(Chainable<T, A>, ...A) -> T -> T
function Functions.bindTail(fn, ...)
	local args = {...}
	return function(subject)
		return fn(subject, unpack(args))
	end
end

--[[
	Returns a function that when called, only calls _fn_ the first time the function is called.
	For subsequent calls, the initial return of _fn_ is returned, even if it is `nil`.
	@returns the function with method `:clear()` that resets the cached value.
	@trait Chainable
	@example
		local fry = _.once(function(item)
			return "fried " .. tiem
		end)
		fry("sardine") --> "fried sardine"
		fry("squid") --> "fried sardine"
		fry:clear()
		fry("squid") --> "fried squid"
		fry("owl") --> "fried squid"
	@throws _passthrough_ - any error thrown when called will cause `nil` to cache and pass through the error.
	@usage Useful for when you want to lazily compute something expensive that doesn't change.
]]
--: <...A, B>((...A -> B), B?) -> Clearable & () -> B
function Functions.once(fn)
	local called = false
	local result = nil
	local once = {
		clear = function()
			called = false
			result = nil
		end
	}
	setmetatable(
		once,
		{
			__call = function(_, ...)
				if called then
					return result
				else
					called = true
					result = fn(...)
					return result
				end
			end
		}
	)
	return once
end

--[[
	Calls the supplied _fn_ on the subject and any additional arguments, returing the result.
	@trait Chainable
]]
function Functions.call(subject, fn, ...)
	return fn(subject, ...)
end

--[[
	Chain takes a dictionary of chainable functions and returns a Chain instance with
	methods mapped to the input functions.

	Chaining is useful when you want to simplify operating on data in a common form and perform
	sequences of operations on some data with a very concise syntax. An _actor_ function can
	check the value of the data at each step and change how the chain proceeds.
	
	Calling a _Chain_ with a subject reduces the chained operations in order on the subject. 
	@param actor called for each result in the chain to determine how the next operation should process it. (default = `_.invoke`)
	@example
		-- Define a simple chain that can operate a list of numbers.
		-- A chain function is called with the subject being processed as first argument,
		-- and any arguments passed in the chain as subsequent arguments.
		local numberChain = _.chain({
			addN = function(list, n)
				return _.map(list, function(element)
					return element + n
				end)
			end,
			sum = function(list)
				return _.sum(list)
			end
		})
		local op = numberChain:addN(2):sum()
		op({1, 2, 3}) --> 12
	@example
		-- Get the name of a player
		local function getName(player)
			return player.Name
		end)

		-- Create a chain that filters for hurt players and finds their name
		local filterHurtNames = _.fn:filter(function(player)
			return player.Health < player.MaxHealth
		end):map(getName)

		-- Run the chain on the current game players
		filterHurtNames(game.Players) --> {"Frodo Baggins", "Boromir"}

		-- For fun, let's encapsulate the functionality above by
		-- defining a chain of operations on players...
		local players = _.chain({
			filterHurtPlayers = _.fn:filter(function(player)
				return player.Health < player.MaxHealth
			end),
			-- Filter players by getting their name and checking it ends with 'Baggins'
			filterBaggins = _.fn:filter(_.fn:call(getName):endsWith("Baggins"))
		})

		local hurtHobbits = players:filterHurtPlayers():filterBaggins()
		hurtHobbits(game.Players) --> {{Name = "Frodo Baggins", ...}}

		local names = _.fn:map(getName)

		-- Chains are themselves chainable, so you can compose two chains together
		local filterHurtHobbitNames = _.compose(hurtHobbits, names)

		filterHurtHobbitNames(game.Players) --> {"Frodo Baggins"}
	@trait Chainable
	@usage The "Rodash" chain: `_.chain(_)` is aliased to `_.fn`, so instead of writing
	`_.chain(_):filter` you can simply write `_.fn:filter`, or any other chainable method.
	@usage A chained function can be made using `_.chain` or built inductively using other chained
		methods of `_.fn`.
	@usage A chainable method is one that has the subject which is passed through a chain as the
		first argument, and subsequent arguments
	@see _.chainFn - Makes a function chainable if it returns a chain.
	@see _.invoke - the identity actor
	@see _.continue - an actor for chains of asynchronous functions
	@see _.maybe - an actor for chains of partial functions
]]
--: <T>(T{}, Actor<T>) -> Chain<T>
function Functions.chain(fns, actor)
	if actor == nil then
		actor = Functions.invoke
	end
	local chain = {}
	setmetatable(
		chain,
		{
			__index = function(self, name)
				local fn = fns[name]
				assert(Functions.isCallable(fn), "Chain key " .. tostring(name) .. " is not callable")
				local feeder = function(parent, ...)
					assert(type(parent) == "table", "Chain functions must be called with ':'")
					local stage = {}
					local op = Functions.bindTail(fn, ...)
					setmetatable(
						stage,
						{
							__index = chain,
							__call = function(self, subject)
								local value = parent(subject)
								return actor(op, value)
							end,
							__tostring = function()
								return tostring(parent) .. "::" .. name
							end
						}
					)
					return stage
				end
				return feeder
			end,
			__newindex = function()
				error("Cannot assign to a chain, create one with _.chain instead.")
			end,
			__call = function(_, subject)
				return subject
			end,
			__tostring = function()
				return "Chain"
			end
		}
	)
	return chain
end

--[[
	Wraps a function, making it chainable if it returns a chain itself.

	This allows you to define custom functions in terms of the arguments they will take when called
	in a chain, and return a chained function which performs the operation, rather than explicitly
	taking the subject as first argument.
	@example
		-- In the chain example addN was defined like so:
		local function addN(list, n)
			return _.map(list, function(element)
				return element + n
			end)
		end
		numberChain = _.chain({
			addN = addN
		})
		local op = numberChain:addN(2):sum()
		op({1, 2, 3}) --> 12

		-- It is more natural to define addN as a function taking one argument,
		-- to match the way it is called in the chain:
		local function addN(n)
			-- Methods on _.fn are themselves chained, so "list" can be dropped.
			return _.fn:map(function(element)
				return element + n
			end)
		end
		-- The _.chainFn is used to wrap any functions which return chains.
		numberChain = _.chain({
			addN = _.chainFn(addN)
		})
		local op = numberChain:addN(2):sum()
		op({1, 2, 3}) --> 12

	@see _.chain
]]
function Functions.chainFn(fn)
	return function(source, ...)
		return fn(...)(source)
	end
end

--[[
	An actor which calls the supplied _fn_ with the argument tail.
	@usage This is the default _actor_ for `_.chain` and acts as an identity, meaning it has no effect on the result.
]]
--: <T>(Actor<T>)
function Functions.invoke(fn, ...)
	return fn(...)
end

--[[
	An actor which cancels execution of a chain if a method returns nil, evaluating the chain as nil.

	Can wrap any other actor which handles values that are non-nil.
	@example 
		-- We can define a chain of Rodash functions that will skip after a nil is returned.
		local maybeFn = _.chain(_, _.maybe())
		local getName = function(player)
			return player.Name
		end
		local players
		players =
			_.chain(
			{
				-- Any chainable functions can be used
				call = _.call,
				endsWith = _.endsWith,
				filterHurt = _.fn:filter(
					function(player)
						return player.Health < 100
					end
				),
				filterBaggins = _.chainFn(
					function()
						-- If getName returns nil here, endsWith will be skipped
						return _.fn:filter(maybeFn:call(getName):endsWith("Baggins"))
					end
				)
			}
		)
		local hurtHobbits = players:filterHurt():filterBaggins()
		local mapNames = _.fn:map(getName)
		local filterHurtBagginsNames = _.compose(hurtHobbits, mapNames)
		-- Here, one player record doesn't have a Name property, so it is skipped.
		local crew = {
			{
				Name = "Frodo Baggins",
				Health = 50
			},
			{
				Name = "Bilbo Baggins",
				Health = 100
			},
			{
				Health = 0
			}
		}
]]
--: <T>(Actor<T>) -> Actor<T>
function Functions.maybe(actor)
	actor = actor or Functions.invoke
	return function(fn, ...)
		local args = {...}
		if args[1] == nil then
			return
		else
			return actor(fn, ...)
		end
	end
end

--[[
	An actor getter which awaits on any promises returned by chain methods, and continues execution
	when the promise completes.

	This allows any asynchronous methods to be used in chains without modifying any of the chain's
	synchronous methods, removing any boilerplate needed to handle promises in the main code body.
	
	Can wrap any other actor which handles values after any promise resolution.
	@param actor (default = `_.invoke`) The actor to wrap.
	@example
		-- Let's define a function which returns an answer after a delay
		local getName = function(player)
			return _.delay(1):andThen(_.returns(player.Name))
		end
		local players
		players =
			_.chain(
			{
				-- Any chainable function can be used
				filter = _.filter,
				-- A chain which evaluates a promise of the player names
				mapNames = _.fn:map(getName):parallel(),
				filterHurt = _.fn:filter(
					function(player)
						return player.Health < 100
					end
				),
				mapNameIf = _.chainFn(
					function(expectedName)
						-- Methods on self work as expected
						return players:mapNames():filter(_.fn:endsWith(expectedName))
					end
				)
			},
			_.continue()
		)
		local filterHurtHobbitNames = players:filterHurt():mapNameIf("Baggins")
		local crew = {
			{
				Name = "Frodo Baggins",
				Health = 50
			},
			{
				Name = "Bilbo Baggins",
				Health = 100
			},
			{
				Name = "Boromir",
				Health = 0
			}
		}
		filterHurtHobbitNames(crew):await() --> {"Frodo Baggins"} (some time later)
	@rejects passthrough
	@see _.chain
]]
--: <T>(Actor<T>) -> Actor<T>
function Functions.continue(actor)
	actor = actor or Functions.invoke
	return function(fn, value, ...)
		local Async = require(script.Async)
		return Async.resolve(value):andThen(
			function(...)
				return actor(fn, ...)
			end
		)
	end
end

local getChain =
	Functions.once(
	function(subject)
		return Functions.chain(subject)
	end
)
Functions.fn = {}
setmetatable(
	Functions.fn,
	{
		__index = function(self, key)
			local _ = require(script)
			return getChain(_)[key]
		end,
		__call = function(self, subject)
			return subject
		end,
		__tostring = function()
			return "_.fn"
		end
	}
)

--[[
	Returns a function that calls the argument functions in left-right order on an input, passing
	the return of the previous function as argument(s) to the next.
	@example
		local function fry(item) return "fried " .. item end
		local function cheesify(item) return "cheesy " .. item end
		local prepare = _.compose(fry, cheesify)
		prepare("nachos") --> "cheesy fried nachos"
	@usage Useful for when you want to lazily compute something expensive that doesn't change.
	@trait Chainable
]]
--: <A>((...A -> ...A)[]) -> ...A -> A
function Functions.compose(...)
	local fnCount = select("#", ...)
	if fnCount == 0 then
		return Functions.id
	end
	local fns = {...}
	return function(...)
		local result = {fns[1](...)}
		for i = 2, fnCount do
			result = {fns[i](unpack(result))}
		end
		return unpack(result)
	end
end

--[[
	Like `_.once`, but caches non-nil results of calls to _fn_ keyed by some serialization of the
	input arguments to _fn_. By default, all the args are serialized simply using `tostring`.

	Optionally memoize takes `function serializeArgs(args, cache)`, a function that should return a string key which a
	result should be cached at for a given signature. Return nil to avoid caching the result.

	@param serializeArgs (default = `_.serialize`)
	@returns the function with method `:clear(...)` that resets the cache for the argument specified, or `:clearAll()` to clear the entire cache.
	@example
		local menu = {"soup", "bread", "butter"}
		local heat = _.memoize(function(index)
			return "hot " ... menu[index]
		end)

		heat(1) --> "hot soup"

		menu = {"caviar"}
		heat(1) --> "hot soup"
		heat(2) --> nil

		menu = {"beef", "potatoes"}
		heat(1) --> "hot soup"
		heat(2) --> "hot potatoes"

		heat:clear(1)
		heat(1) --> "hot beef"
	@see _.serialize
	@see _.serializeDeep if you want to recursively serialize arguments.
]]
--: <...A, B>((...A -> B), ...A -> string?) -> Clearable<...A> & AllClearable & (...A) -> B
function Functions.memoize(fn, serializeArgs)
	assert(type(fn) == "function")
	serializeArgs = serializeArgs or Functions.unary(Tables.serialize)
	assert(type(serializeArgs) == "function")
	local cache = {}
	local clearable = {
		clear = function(_, ...)
			local cacheKey = serializeArgs({...}, cache)
			if cacheKey then
				cache[cacheKey] = nil
			end
		end,
		clearAll = function()
			cache = {}
		end
	}
	setmetatable(
		clearable,
		{
			__call = function(_, ...)
				local cacheKey = serializeArgs({...}, cache)
				if cacheKey == nil then
					return fn(...)
				else
					if cache[cacheKey] == nil then
						cache[cacheKey] = fn(...)
					end
					return cache[cacheKey]
				end
			end
		}
	)
	return clearable
end

--[[
	Like `delay`, this calls _fn_ after _delayInSeconds_ time has passed, with the added benefit of being cancelable.
	@returns an instance which `:clear()` can be called on to prevent _fn_ from firing.
]]
--: (() -> nil), number -> Clearable
function Functions.setTimeout(fn, delayInSeconds)
	local cleared = false
	local timeout
	delay(
		delayInSeconds,
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

--[[
	Like `_.setTimeout` but calls _fn_ after every interval of _intervalInSeconds_ time has passed.
	@param delayInSeconds (default = _intervalInSeconds_) The delay before the initial call.
	@returns an instance which `:clear()` can be called on to prevent _fn_ from firing.
]]
--: (() -> nil), number, number? -> Clearable
function Functions.setInterval(fn, intervalInSeconds, delayInSeconds)
	local timeout
	local callTimeout
	local function handleTimeout()
		callTimeout()
		fn(timeout)
	end
	callTimeout = function()
		timeout = Functions.setTimeout(handleTimeout, intervalInSeconds)
	end
	if delayInSeconds ~= nil then
		timeout = Functions.setTimeout(handleTimeout, delayInSeconds)
	else
		callTimeout()
	end

	return {
		clear = function()
			timeout:clear()
		end
	}
end

--[[
	Creates a debounced function that delays calling _fn_ until after _delayInSeconds_ seconds have
	elapsed since the last time the debounced function was attempted to be called.
	@returns the debounced function with method `:clear()` can be called on to cancel any scheduled call.
	@usage A nice [visualisation of debounce vs. throttle](http://demo.nimius.net/debounce_throttle/), 
		the illustrated point being debounce will only call _fn_ at the end of a spurt of events.
]]
--: <A, B>((...A) -> B), number -> Clearable & (...A) -> B
function Functions.debounce(fn, delayInSeconds)
	assert(Functions.isCallable(fn))
	assert(type(delayInSeconds) == "number")

	local lastResult = nil
	local timeout

	local debounced = {
		clear = function()
			if timeout then
				timeout:clear()
			end
		end
	}
	setmetatable(
		debounced,
		{
			__call = function(_, ...)
				local args = {...}
				if timeout then
					timeout:clear()
				end
				timeout =
					Functions.setTimeout(
					function()
						lastResult = fn(unpack(args))
					end,
					delayInSeconds
				)
				return lastResult
			end
		}
	)
	return debounced
end

--[[
	Creates a throttle function that drops any repeat calls within a cooldown period and instead
	returns the result of the last call.
	@usage A nice [visualisation of debounce vs. throttle](http://demo.nimius.net/debounce_throttle/),
		the illustrated point being throttle will call _fn_ every period during a spurt of events.
]]
--: <A, B>((...A) -> B), number -> ...A -> B
function Functions.throttle(fn, cooldownInSeconds)
	assert(Functions.isCallable(fn))
	assert(type(cooldownInSeconds) == "number")
	assert(cooldownInSeconds > 0)

	local cached = false
	local lastResult = nil
	return function(...)
		if not cached then
			cached = true
			lastResult = fn(...)
			Functions.setTimeout(
				function()
					cached = false
				end,
				cooldownInSeconds
			)
		end
		return lastResult
	end
end

--[[
	Return `true` if the _value_ is a function or a table with a `__call` entry in its metatable.
	@usage This is a more general test than checking purely for a function type.
]]
--: any -> bool
function Functions.isCallable(value)
	return type(value) == "function" or
		(type(value) == "table" and getmetatable(value) and getmetatable(value).__call ~= nil)
end

return Functions
