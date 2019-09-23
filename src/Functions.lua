--[[
	Utility functions and building blocks for functional programming styles.
]]
local Tables = require(script.Parent.Tables)
local t = require(script.Parent.Parent.t)

local Functions = {}

--[[
	A simple function that does nothing, and returns nil.
	@usage Shorthand for `function() end`. Useful for when a function is expecting a callback but
		you don't want to do anything.
]]
--: () -> ()
function Functions.noop()
end

--[[
	A simple function that does nothing, but returns its input parameters.
	@trait Chainable
	@usage This is typically referred to as the "identity" function. Useful for when a function is
		expecting a callback to transform a value but you don't want to make any change to it.
]]
--: <A>(...A -> ...A)
function Functions.id(...)
	return ...
end

--[[
	Returns a function that when called, returns the original input parameters.
	@trait Chainable
	@example
		findPlayer("builderman"):andThen(dash.returns("Found Dave!"))
		--> "Found Dave!" (soon after)
	@usage Useful for when you want a callback to discard the arguments passed in and instead use static ones.
]]
--: <A>(...A -> () -> ...A)
function Functions.returns(...)
	local args = {...}
	return function()
		return unpack(args)
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

--[[
	Returns a function that wraps the input _fn_ but only passes the first argument to it.
	@example
		local printOneArgument = dash.unary(function(...)
			print(...)
		end)
		printOneArgument("Hello", "World", "!")
		-->> Hello
]]
--: <A, R>((A -> R) -> A -> R)
function Functions.unary(fn)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	return function(first)
		return fn(first)
	end
end

--[[
	Returns a function that when called, throws the original message.
	@example
		findPlayer("builderman"):andThen(dash.throws("DaveNotFound"))
		--!> "DaveNotFound" (soon after)
	@usage Useful for when you want a callback to discard any result and throw a message instead.
]]
--: string -> () -> fail
function Functions.throws(errorMessage)
	assert(t.string(errorMessage), "BadInput: errorMessage must be a string")
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
		local damageLocalPlayer = dash.bind(damagePlayer, game.Players.LocalPlayer)
		damageLocalPlayer(5)
]]
--: <A, A2, R>(((...A, ...A2 -> R), ...A) -> ...A2 -> R)
function Functions.bind(fn, ...)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	local args = {...}
	return function(...)
		return fn(unpack(args), ...)
	end
end

--[[
	Takes a chainable function _fn_ and binds _arguments_ to the tail of the _fn_ argument list.
	Returns a function which executes _fn_, passing a subject ahead of the bound arguments supplied.
	@example
		local function setHealthTo(player, health)
			player.Health = health
		end
		local restoreHealth = dash.bindTail(setHealthTo, 100)
		local Jimbo = {
			Health = 5
		}
		restoreHealth(Jimbo)
		Jimbo.Health --> 100
	@example
		local filterHurtPlayers = dash.bindTail(dash.filter, function(player)
			return player.Health < player.MaxHealth
		end)
		local getName = dash.bindTail(dash.map, function(player)
			return player.Name
		end)
		local filterHurtNames = dash.compose(filterHurtPlayers, getName)
		filterHurtNames(game.Players) --> {"Frodo", "Boromir"}	
	@see `dash.filter`
	@see `dash.compose`
	@usage Chainable rodash function feeds are mapped to `dash.fn`, such as `dash.fn.map(handler)`.
]]
--: <S>(Chainable<S>, ...) -> S -> S
function Functions.bindTail(fn, ...)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
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
		local fry = dash.once(function(item)
			return "fried " .. item
		end)
		fry("sardine") --> "fried sardine"
		fry("squid") --> "fried sardine"
		fry:clear()
		fry("squid") --> "fried squid"
		fry("owl") --> "fried squid"
	@throws _passthrough_ - any error thrown when called will cause `nil` to cache and pass through the error.
	@usage Useful for when you want to lazily compute something expensive that doesn't change.
]]
--: <A, R>((...A -> R), R?) -> Clearable & (...A -> R)
function Functions.once(fn)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
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
	Calls the supplied _fn_ on the subject and any additional arguments, returning the result.
	@example
		local function get(object, key)
			return object[key]
		end
		local Jimbo = {
			Name = "Jimbo"
		}
		dash.call(Jimbo, get, "Name") --> "Jimbo"
	@example
		local function get(object, key)
			return object[key]
		end
		local isABaggins = dash.fn:call(get, "Name"):endsWith("Baggins")
		local Jimbo = {
			Name = "Jimbo"
		}
		isABaggins(Jimbo) --> false
	@trait Chainable
	@usage This is useful when used in the `dash.fn:call` form to call arbitrary function
		inside a chain.
	@see `dash.chain`
]]
--: <S, A, R>(S, (S, ...A -> R), ...A -> R)
function Functions.call(subject, fn, ...)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	return fn(subject, ...)
end

--[[
	Chain takes a dictionary of chainable functions and returns a Chain instance with
	methods mapped to the input functions.

	Chaining is useful when you want to simplify operating on data in a common form and perform
	sequences of operations on some data with a very concise syntax. An _actor_ function can
	check the value of the data at each step and change how the chain proceeds.
	
	Calling a _Chain_ with a subject reduces the chained operations in order on the subject. 
	@param actor called for each result in the chain to determine how the next operation should process it. (default = `dash.invoke`)
	@example
		-- Define a simple chain that can operate a list of numbers.
		-- A chain function is called with the subject being processed as first argument,
		-- and any arguments passed in the chain as subsequent arguments.
		local numberChain = dash.chain({
			addN = function(list, n)
				return dash.map(list, function(element)
					return element + n
				end)
			end,
			sum = function(list)
				return dash.sum(list)
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
		local filterHurtNames = dash.fn:filter(function(player)
			return player.Health < player.MaxHealth
		end):map(getName)

		-- Run the chain on the current game players
		filterHurtNames(game.Players) --> {"Frodo Baggins", "Boromir"}

		-- For fun, let's encapsulate the functionality above by
		-- defining a chain of operations on players...
		local players = dash.chain({
			filterHurtPlayers = dash.fn:filter(function(player)
				return player.Health < player.MaxHealth
			end),
			-- Filter players by getting their name and checking it ends with 'Baggins'
			filterBaggins = dash.fn:filter(dash.fn:call(getName):endsWith("Baggins"))
		})

		local hurtHobbits = players:filterHurtPlayers():filterBaggins()
		hurtHobbits(game.Players) --> {{Name = "Frodo Baggins", ...}}

		local names = dash.fn:map(getName)

		-- Chains are themselves chainable, so you can compose two chains together
		local filterHurtHobbitNames = dash.compose(hurtHobbits, names)

		filterHurtHobbitNames(game.Players) --> {"Frodo Baggins"}
	@trait Chainable
	@usage The "Rodash" chain: `dash.chain(_)` is aliased to `dash.fn`, so instead of writing
	`dash.chain(_):filter` you can simply write `dash.fn:filter`, or any other chainable method.
	@usage A chained function can be made using `dash.chain` or built inductively using other chained
		methods of `dash.fn`.
	@usage A chainable method is one that has the subject which is passed through a chain as the
		first argument, and subsequent arguments
	@see `dash.chainFn` - Makes a function chainable if it returns a chain.
	@see `dash.invoke` - the identity actor
	@see `dash.continue` - an actor for chains of asynchronous functions
	@see `dash.maybe` - an actor for chains of partial functions
]]
--: <S,T:Chainable<S>{}>(T, Actor<S>) -> Chain<S,T>
function Functions.chain(fns, actor)
	if actor == nil then
		actor = Functions.invoke
	end
	assert(Functions.isCallable(actor), "BadInput: actor must be callable")
	local chain = {}
	setmetatable(
		chain,
		{
			__index = function(self, name)
				local fn = fns[name]
				assert(Functions.isCallable(fn), "BadFn: Chain key " .. tostring(name) .. " is not callable")
				local feeder = function(parent, ...)
					assert(type(parent) == "table", "BadCall: Chain functions must be called with ':'")
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
				error("ReadonlyKey: Cannot assign to a chain, create one with dash.chain instead.")
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
			return dash.map(list, function(element)
				return element + n
			end)
		end
		numberChain = dash.chain({
			addN = addN
		})
		local op = numberChain:addN(2):sum()
		op({1, 2, 3}) --> 12

		-- It is more natural to define addN as a function taking one argument,
		-- to match the way it is called in the chain:
		local function addN(n)
			-- Methods on dash.fn are themselves chained, so "list" can be dropped.
			return dash.fn:map(function(element)
				return element + n
			end)
		end
		-- The dash.chainFn is used to wrap any functions which return chains.
		numberChain = dash.chain({
			addN = dash.chainFn(addN)
		})
		local op = numberChain:addN(2):sum()
		op({1, 2, 3}) --> 12

	@see `dash.chain`
]]
--: <T, A, R>((...A -> T -> R) -> T, ...A -> R)
function Functions.chainFn(fn)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	return function(source, ...)
		return fn(...)(source)
	end
end

--[[
	An [Actor](/rodash/types#Actor) which calls the supplied _fn_ with the argument tail.
	@example
		local getName = function(player)
			return player.Name
		end
		local Jimbo = {
			Name = "Jimbo"
		}
		dash.invoke(getName, Jimbo) --> "Jimbo"
	@usage This is the default _actor_ for `dash.chain` and acts as an identity, meaning it has no effect on the result.
]]
--: <S, A>((A -> S), ...A -> S)
function Functions.invoke(fn, ...)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	return fn(...)
end

--[[
	An [Actor](/rodash/types#Actor) which cancels execution of a chain if a method returns nil, evaluating the chain as nil.

	Can wrap any other actor which handles values that are non-nil.
	@example 
		-- We can define a chain of Rodash functions that will skip after a nil is returned.
		local maybeFn = dash.chain(_, dash.maybe())
		local getName = function(player)
			return player.Name
		end
		local players
		players =
			dash.chain(
			{
				-- Any chainable functions can be used
				call = dash.call,
				endsWith = dash.endsWith,
				filterHurt = dash.fn:filter(
					function(player)
						return player.Health < 100
					end
				),
				filterBaggins = dash.chainFn(
					function()
						-- If getName returns nil here, endsWith will be skipped
						return dash.fn:filter(maybeFn:call(getName):endsWith("Baggins"))
					end
				)
			}
		)
		local hurtHobbits = players:filterHurt():filterBaggins()
		local mapNames = dash.fn:map(getName)
		local filterHurtBagginsNames = dash.compose(hurtHobbits, mapNames)
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
--: <S>(Actor<S>? -> Actor<S>)
function Functions.maybe(actor)
	actor = actor or Functions.invoke
	assert(Functions.isCallable(actor), "BadInput: actor must be callable")
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
	An [Actor](/rodash/types#Actor) getter which awaits on any promises returned by chain methods, and continues execution
	when the promise completes.

	This allows any asynchronous methods to be used in chains without modifying any of the chain's
	synchronous methods, removing any boilerplate needed to handle promises in the main code body.
	
	Can wrap any other actor which handles values after any promise resolution.
	@param actor (default = `dash.invoke`) The actor to wrap.
	@example
		-- Let's define a function which returns an answer after a delay
		local getName = function(player)
			return dash.delay(1):andThen(dash.returns(player.Name))
		end
		local players
		players =
			dash.chain(
			{
				-- Any chainable function can be used
				filter = dash.filter,
				-- A chain which evaluates a promise of the player names
				mapNames = dash.fn:map(getName):parallel(),
				filterHurt = dash.fn:filter(
					function(player)
						return player.Health < 100
					end
				),
				mapNameIf = dash.chainFn(
					function(expectedName)
						-- Methods on self work as expected
						return players:mapNames():filter(dash.fn:endsWith(expectedName))
					end
				)
			},
			dash.continue()
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
	@see `dash.chain`
]]
--: <S>(Actor<S>? -> Actor<S>)
function Functions.continue(actor)
	actor = actor or Functions.invoke
	assert(Functions.isCallable(actor), "BadInput: actor must be callable")
	return function(fn, value, ...)
		local Async = require(script.Parent.Async)
		return Async.resolve(value):andThen(
			function(...)
				return actor(fn, ...)
			end
		)
	end
end

local getRodashChain =
	Functions.once(
	function(rd)
		return Functions.chain(rd)
	end
)

--[[
	A [Chain](/rodash/types/#chain) built from Rodash itself. Any
	[Chainable](/rodash/types/#chainable) Rodash function can be used as a method on this object,
	omitting the subject until the whole chain is evaluated by calling it with the subject.
	@example
		local getNames = dash.fn:map(function( player )
			return player.Name
		end)
		getNames(game.Players) --> {"Bilbo Baggins", "Frodo Baggins", "Peregrin Took"}
	@example
		local getNames = dash.fn:map(function( player )
			return player.Name
		end):filter(function( name )
			return dash.endsWith(name, "Baggins")
		end)
		getNames(game.Players) --> {"Bilbo Baggins", "Frodo Baggins"}
	@example
		local getNames = dash.fn:map(function( player )
			return player.Name
		end):filter(dash.fn:endsWith("Baggins"))
		getNames(game.Players) --> {"Bilbo Baggins", "Frodo Baggins"}
	@see `dash.chain` - to make your own chains.
]]
--: Chain<any,dash>
Functions.fn = {}
setmetatable(
	Functions.fn,
	{
		__index = function(self, key)
			local rd = require(script.Parent)
			return getRodashChain(rd)[key]
		end,
		__call = function(self, subject)
			return subject
		end,
		__tostring = function()
			return "fn"
		end
	}
)

--[[
	Returns a function that calls the argument functions in left-right order on an input, passing
	the return of the previous function as argument(s) to the next.
	@example
		local function fry(item)
			return "fried " .. item
		end
		local function cheesify(item)
			return "cheesy " .. item
		end
		local prepare = dash.compose(fry, cheesify)
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
	Like `dash.once`, but caches non-nil results of calls to _fn_ keyed by some serialization of the
	input arguments to _fn_. By default, all the args are serialized simply using `tostring`.

	Optionally memoize takes `function serializeArgs(args, cache)`, a function that should return a string key which a
	result should be cached at for a given signature. Return nil to avoid caching the result.

	@param serializeArgs (default = `dash.serialize`)
	@returns the function with method `:clear(...)` that resets the cache for the argument specified, or `:clearAll()` to clear the entire cache.
	@example
		local menu = {"soup", "bread", "butter"}
		local heat = dash.memoize(function(index)
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
	@see `dash.once`
	@see `dash.serialize`
	@see `dash.serializeDeep` if you want to recursively serialize arguments.
]]
--: <A, R>((...A -> R), ...A -> string?) -> Clearable<A> & AllClearable & (...A -> R)
function Functions.memoize(fn, serializeArgs)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	serializeArgs = serializeArgs or Functions.unary(Tables.serialize)
	assert(Functions.isCallable(serializeArgs), "BadInput: serializeArgs must be callable or nil")
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

	The _fn_ is called in a separate thread, meaning that it will not block the thread it is called
	in, and if the calling threads, the _fn_ will still be called at the expected time.
	
	@returns an instance which `:clear()` can be called on to prevent _fn_ from firing.
	@example
		local waitTimeout = dash.setTimeout(function()
			print("Sorry, no players came online!")
		end, 5)
		game.Players.PlayerAdded:Connect(function(player)
			waitTimeout:clear()
		end)
	@see `dash.delay`
]]
--: (Clearable -> ()), number -> Clearable
function Functions.setTimeout(fn, delayInSeconds)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	assert(t.number(delayInSeconds), "BadInput: delayInSeconds must be a number")
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
	Like `dash.setTimeout` but calls _fn_ after every interval of _intervalInSeconds_ time has
	passed.

	The _fn_ is called in a separate thread, meaning that it will not block the thread it is called
	in, and if the calling threads, the _fn_ will still be called at the expected times.

	@param delayInSeconds (default = _intervalInSeconds_) The delay before the initial call.
	@returns an instance which `:clear()` can be called on to prevent _fn_ from firing.
	@example
		local waitInterval = dash.setInterval(function()
			print("Waiting for more players...")
		end, 5)
		game.Players.PlayerAdded:Connect(function(player)
			waitInterval:clear()
		end)
	@see `dash.setTimeout`
]]
--: (Clearable -> ()), number, number? -> Clearable
function Functions.setInterval(fn, intervalInSeconds, delayInSeconds)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	assert(t.number(intervalInSeconds), "BadInput: intervalInSeconds must be a number")
	assert(t.optional(t.number)(delayInSeconds), "BadInput: delayInSeconds must be a number")
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
--: <A, R>(...A -> R), number -> Clearable & (...A -> R)
function Functions.debounce(fn, delayInSeconds)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	assert(type(delayInSeconds) == "number", "BadInput: delayInSeconds must be a number")

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
	@example
		local post = dash.async(HttpService.Post)
		local saveMap = dash.throttle(function(data)
			post("https://example.com/save", data)
		end, 10)
		saveMap(map) -- This saves the map
		saveMap(map) -- This function call is throttled and won't result in post being called
		saveMap(map) -- Same again
		wait(10)
		saveMap(map) -- Enough time has passed, so this saves the map again
	@usage A nice [visualisation of debounce vs. throttle](http://demo.nimius.net/debounce_throttle/),
		the illustrated point being throttle will call _fn_ every period during a spurt of events.
	@see `dash.async`
]]
--: <A, R>((...A) -> R), number -> ...A -> R
function Functions.throttle(fn, cooldownInSeconds)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	assert(type(cooldownInSeconds) == "number", "BadInput: cooldownInSeconds must be a number > 0")
	assert(cooldownInSeconds > 0, "BadInput: cooldownInSeconds must be a number > 0")

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

return Functions
