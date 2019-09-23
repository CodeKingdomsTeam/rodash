--[[
	A collection of functions that operate on Lua tables. These can operate on arrays,
	dictionaries and any collection types implemented with tables.

	These functions can iterate over any [Iterable](/rodash/types#Iterable) values.

	These functions typically act on immutable tables and return new tables in functional style.
	Note that mutable arguments in Rodash are explicitly typed as such with the `mut` keyword.
]]
local t = require(script.Parent.Parent.t)

local Tables = {}

local function assertHandlerIsFn(handler)
	local Functions = require(script.Parent.Functions)
	assert(Functions.isCallable(handler), "BadInput: handler must be a function")
end

--[[
	Determines a suitable [Iterator](/rodash/types#Iterator) to use for _source_, allowing _source_ to
	be either a plain table, a table that has a metatable with an `iterable` key, or a function.

	By default, the iterator is unordered, but passing _asArray_ as `true` uses `ipairs` to iterate
	through natural keys _1..n_ in order.
]]
--: <T: Iterable>(T, bool -> Iterator<T>)
function Tables.iterator(source, asArray)
	local metatable = getmetatable(source)
	local iterable = metatable and metatable.iterable or source
	if type(source) == "function" then
		return source
	else
		assert(type(source) == "table", "BadInput: Can only iterate over a table or an iterator function")
		if asArray then
			return ipairs(iterable)
		else
			return pairs(iterable)
		end
	end
end

--[[
	Get a child or descendant of a table, returning nil if any errors are generated.
	@param key The key of the child.
	@param ... Further keys to address any descendent.
	@example
		local upperTorso = dash.get(game.Players, "LocalPlayer", "Character", "UpperTorso")
		upperTorso --> Part (if player's character and its UpperTorso are defined)
	@example
		-- You can also bind a lookup to get later on:
		local getUpperTorso = dash.bindTail(dash.get, "Character", "UpperTorso")
		getUpperTorso(players.LocalPlayer) --> Part
	@trait Chainable
]]
--: <K, V, T: {[K]: V}>(T, ...K) -> V?
function Tables.get(source, ...)
	local path = {...}
	local ok, value =
		pcall(
		function()
			local result = source
			for _, key in ipairs(path) do
				result = result[key]
			end
			return result
		end
	)
	if ok then
		return value
	end
end

--[[
	Set a child or descendant value in a table. Returns `true` if the operation completed without error.

	The function walks through the object using keys from _path_ in turn. If any values along the
	path are not tables, `dash.set` will do nothing and return `false`.

	@returns `true` if the set worked
	@example
		dash.set(game.Players, {"LocalPlayer", "Character", "UpperTorso", "Color"}, Color3.new(255, 255, 255))
		--> true (if the set worked)
	@trait Chainable
]]
--: <T: Iterable<K, V>>(T, K[], V) -> bool
function Tables.set(source, path, value)
	local ok =
		pcall(
		function()
			local result = source
			for i = 1, #path - 1 do
				result = result[path[i]]
			end
			result[path[#path]] = value
		end
	)
	return ok
end

--[[
	Create a new table from _source_ where each value is replaced with the value returned from
	calling _handler_ with each element in _source_.
	@example
		-- Use map to get the same property of each value:
		local playerNames = dash.map(game.Players:GetPlayers(), function(player)
			return player.Name
		end)
		playerNames --> {"Frodo Baggins", "Bilbo Baggins", "Boromir"}
	@example
		-- Use map to remove elements while preserving keys:
		local ingredients = {veg = "carrot", sauce = "tomato", herb = "basil"}
		local carrotsAndHerbs = dash.map(ingredients, function(value, key)
			if value == "carrot" or key == "herb" then
				return value
			end
		end)
		carrotsAndHerbs --> {veg = "carrot", herb = "basil"}
	@example
		-- Use map with multiple values of a table at once:
		local numbers = {1, 1, 2, 3, 5} 
		local nextNumbers = dash.map(numbers, function(value, key)
			return value + (numbers[key - 1] or 0)
		end)
		nextNumbers --> {1, 2, 3, 5, 8}
	@see `dash.filter` - if you want to remove values using a predicate.
]]
--: <T: Iterable<K,V>, V2>((T, (element: V, key: K) -> V2) -> Iterable<K,V2>)
function Tables.map(source, handler)
	assertHandlerIsFn(handler)
	local result = {}
	for i, v in Tables.iterator(source) do
		result[i] = handler(v, i)
	end
	return result
end

--[[
	Like `dash.map`, but returns an array of the transformed values in the order that they are
	iterated over, dropping the original keys.
	@see `dash.map`
	@example
		local ingredients = {veg = "carrot", sauce = "tomato", herb = "basil"}
		local list = dash.mapValues(function(value)
			return dash.format("{} x2", value)
		end)
		list --> {"carrot x2", "tomato x2", "basil x2"} (in some order)
	@usage This is equivalent to `dash.values(dash.map(...))` but more concise.
]]
--: <T: Iterable<K,V>, V2>((T, (element: V, key: K) -> V2) -> V2[])
function Tables.mapValues(source, handler)
	assertHandlerIsFn(handler)
	local result = {}
	for i, v in Tables.iterator(source) do
		table.insert(result, handler(v, i))
	end
	return result
end

--[[
	This function iterates over _source_, calling _handler_ to obtain a key for each element.
	The element is then assigned by its key to the resulting object, overriding any previous
	element assigned to that key from source.

	If the _handler_ returns nil, the element is dropped from the result.
	@see `dash.groupBy` - if you want to preseve all the elements at each key.
	@example
		local playerSet = {Frodo = true, Bilbo = true, Boromir = true}
		local healthSet = dash.keyBy(playerSet, function(name)
			return dash.get(game.Players, name, "Character", "Humanoid", "Health")
		end)
		healthSet --> {100 = true, 50 = true, 0 = true}
]]
--: <T: Iterable<K,V>, K2>((T, (element: V, key: K) -> K2) -> Iterable<K2,V>)
function Tables.keyBy(source, handler)
	assertHandlerIsFn(handler)
	local result = {}
	for i, v in Tables.iterator(source) do
		local key = handler(v, i)
		if key ~= nil then
			result[key] = v
		end
	end
	return result
end

--[[
	Like `dash.mapValues` this function iterates through _source_ and returns an array of values,
	using _handler_ to transform them. However, _handler_ must return an array of results, these
	elements being insterted into the resulting array.

	You can return an empty array `{}` from handler to avoid inserting anything for a particular
	element.

	@example
		local tools = dash.flatMap(game.Players:GetPlayers(), function(player)
			return player.Backpack:GetChildren()
		end)
		tools --> {Spoon, Ring, Sting, Book}
]]
--: <T: Iterable<K,V>, V2>((T, (element: V, key: K) -> V2[]) -> V2[])
function Tables.flatMap(source, handler)
	assertHandlerIsFn(handler)
	local Arrays = require(script.Parent.Arrays)
	local result = {}
	for i, v in Tables.iterator(source) do
		local list = handler(v, i)
		assert(t.table(list), "BadResult: Handler must return an array")
		Arrays.append(result, list)
	end
	return result
end

--[[
	Returns an array of any values in _source_ that the _handler_ function returned `true` for,
	in order of iteration.

	@example
		local myTools = game.Players.LocalPlayer.Backpack:GetChildren()
		local mySpoons = dash.filter(myTools, function(tool)
			return dash.endsWith(tool.Name, "Spoon")
		end)
		mySpoons --> {SilverSpoon, TableSpoon}
	@see `dash.map` if you would like to remove elements but preserve table keys
]]
--: <T: Iterable<K,V>>(T, (element: V, key: K -> bool) -> V[])
function Tables.filter(source, handler)
	assertHandlerIsFn(handler)
	local result = {}
	for i, v in Tables.iterator(source) do
		if handler(v, i) then
			table.insert(result, v)
		end
	end
	return result
end

--[[
	Returns an array of elements in _source_ with any elements of _value_ removed.
	@example
		local points = {0, 10, 3, 0, 5}
		local nonZero = dash.without(points, 0)
		nonZero --> {10, 3, 5}
	@example
		local ingredients = {veg = "carrot", sauce = "tomato", herb = "basil"}
		local withoutCarrots = dash.without(ingredients, "carrot")
		withoutCarrots --> {"tomato", "basil"} (in some order)
]]
--: <T: Iterable<K,V>>(T, V -> V[])
function Tables.without(source, value)
	return Tables.filter(
		source,
		function(child)
			return child ~= value
		end
	)
end

--[[
	Returns an array of elements from a sparse array _source_ with the returned elements provided
	in original key-order.

	@example
		local names = {
			[3] = "Boromir",
			[1] = "Frodo",
			[8] = "Bilbo"
		}
		local inOrderNames = dash.compact(names)
		inOrderNames --> {"Frodo", "Boromir", "Bilbo"}
]]
--: <T: Iterable<K,V>>(T -> V[])
function Tables.compact(source)
	local Arrays = require(script.Parent.Arrays)
	local sortedKeys = Arrays.sort(Tables.keys(source))
	return Tables.map(
		sortedKeys,
		function(key)
			return source[key]
		end
	)
end

--[[
	Return `true` if _handler_ returns true for every element in _source_ it is called with.

	If no handler is provided, `dash.all` returns true if every element is non-nil.
	@param handler (default = `dash.id`)
	@example
		local names = {
			[3] = "Boromir",
			[1] = "Frodo",
			[8] = "Bilbo"
		}
		local allNamesStartWithB = dash.all(names, function(name)
			return dash.startsWith(name, "B")
		end)
		allNamesStartWithB --> false
]]
--: <T: Iterable<K,V>>(T, (value: V, key: K -> bool)?) -> bool
function Tables.all(source, handler)
	if not handler then
		handler = function(x)
			return x
		end
	end
	assertHandlerIsFn(handler)
	for key, value in Tables.iterator(source) do
		if not handler(value, key) then
			return false
		end
	end
	return true
end

--[[
	Return `true` if _handler_ returns true for at least one element in _source_ it is called with.

	If no handler is provided, `dash.any` returns true if some element is non-nil.
	@param handler (default = `dash.id`)
	@example
		local names = {
			[3] = "Boromir",
			[1] = "Frodo",
			[8] = "Bilbo"
		}
		local anyNameStartsWithB = dash.any(names, function(name)
			return dash.startsWith(name, "B")
		end)
		anyNameStartsWithB --> true
]]
--: <T: Iterable<K,V>>(T -> bool)
function Tables.any(source, handler)
	if not handler then
		handler = function(x)
			return x
		end
	end
	assertHandlerIsFn(handler)
	-- Use double negation to coerce the type to a boolean, as there is
	-- no toboolean() or equivalent in Lua.
	for key, value in Tables.iterator(source) do
		if handler(value, key) then
			return true
		end
	end
	return false
end

--[[
	Returns a copy of _source_, ensuring each key starts with an underscore `_`.
	
	Keys which are already prefixed with an underscore are left unchanged.
	@example
		local privates = dash.privatize({
			[1] = 1,
			public = 2,
			_private = 3
		})
		privates --> {_1 = 1, _public = 2, _private = 3}
	@example
		-- Make a static factory to create Cars with private fields
		local interface = {
			speed = t.number,
			color = t.string
		}
		local Car = dash.classWithInterface(
			dash.privatize(interface)
		)
		local CarFactory = {
			make = function(props)
				return Car.new(dash.privatize(props))
			end
		}
		-- Create a new car using a public interface:
		local car = CarFactory.make({
			speed = 5,
			color = 'red'
		})
		-- By convention, private fields should only by their owner.
		car._speed --> 5
	@usage
		Fields starting with an underscore are considered private in many programming languages
		without inbuild access control. This function allows you to translate a public interface
		into a private one suitable for a class instance with private fields.
	@see `dash.class`
	@see `dash.classWithInterface`
]]
--: <T>(T{} -> T{})
function Tables.privatize(source)
	local Strings = require(script.Parent.Strings)
	return Tables.keyBy(
		source,
		function(_, key)
			local stringKey = tostring(key)
			return Strings.startsWith(stringKey, "_") and stringKey or "_" .. stringKey
		end
	)
end

--[[
	Returns a table with elements from _source_ with their keys and values flipped.
	@example
		local teams = {red = "Frodo", blue = "Bilbo", yellow = "Boromir"}
		local players = dash.invert(teams)
		players --> {Frodo = "red", Bilbo = "blue", Boromir = "yellow"}
]]
--: <K, V>(Iterable<K,V> -> Iterable<V,K>)
function Tables.invert(source)
	local result = {}
	for i, v in Tables.iterator(source) do
		result[v] = i
	end
	return result
end

--[[
	This function iterates over _source_, calling _handler_ to obtain a key for each element.
	Elements from _source_ are then appended to an array of elements based on their key, so
	that this function returns a dictionary of arrays of the elements grouped by their keys.

	If the _handler_ returns nil, the element is dropped from the result.
	@see `dash.keyBy` - if you only want one element to be preserved at each key
	@see `dash.get`
	@example
		local playerSet = {Frodo = "Frodo", Bilbo = "Bilbo", Boromir = "Boromir"}
		local healthSet = dash.keyBy(playerSet, function(name)
			return dash.get(game.Players, name, "Character", "Humanoid", "Health")
		end)
		healthSet --> {100 = {}, 50 = {"Bilbo", "Frodo"}, 0 = {"Boromir"}}
]]
--: <T: Iterable<K,V>, K2>(((value: T, key: K) -> K2) -> Iterable<K2, Iterable<K,V>>)
function Tables.groupBy(source, handler)
	assertHandlerIsFn(handler)
	local result = {}
	for i, v in Tables.iterator(source) do
		local key = handler(v, i)
		if key ~= nil then
			if not result[key] then
				result[key] = {}
			end
			table.insert(result[key], v)
		end
	end
	return result
end

--[=[
	Mutates _target_ by iterating recursively through elements of the subsequent
	arguments in order and inserting or replacing the values in target with each
	element preserving keys.

	If any values are both tables, these are merged recursively using `dash.merge`.
	@example
		local someInfo = {
			Frodo = {
				name = "Frodo Baggins",
				team = "blue"
			},
			Boromir = {
				score = 5
			}
		}
		local someOtherInfo = {
			Frodo = {
				team = "red",
				score = 10
			},
			Bilbo = {
				team = "yellow",

			},
			Boromir = {
				score = {1, 2, 3}
			}
		}
		local mergedInfo = dash.merge(someInfo, someOtherInfo)
		--[[
			--> {
				Frodo = {
					name = "Frodo Baggins",
					team = "red",
					score = 10
				},
				Bilbo = {
					team = "yellow"
				},
				Boromir = {
					score = {1, 2, 3}
				}
			}
		]]
	@see `dash.assign`
	@see `dash.defaults`
]=]
--: <T: Iterable<K,V>>(mut T, ...T) -> T
function Tables.merge(target, ...)
	-- Use select here so that nil arguments can be supported. If instead we
	-- iterated over ipairs({...}), any arguments after the first nil one
	-- would be ignored.
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source ~= nil then
			for key, value in Tables.iterator(source) do
				if type(target[key]) == "table" and type(value) == "table" then
					target[key] = Tables.merge(target[key] or {}, value)
				else
					target[key] = value
				end
			end
		end
	end
	return target
end

--[[
	Returns an array of all the values of the elements in _source_.
	@example
		dash.values({
			Frodo = 1,
			Boromir = 2,
			Bilbo = 3
		}) --> {1, 2, 3} (in some order)
]]
--: <T: Iterable<K,V>>(T -> V[])
function Tables.values(source)
	local result = {}
	for i, v in Tables.iterator(source) do
		table.insert(result, v)
	end
	return result
end

--[[
	Returns an array of all the keys of the elements in _source_.
	@example
		dash.values({
			Frodo = 1,
			Boromir = 2,
			Bilbo = 3
		}) --> {"Frodo", "Boromir", "Bilbo"} (in some order)
]]
--: <T: Iterable<K,V>>(T -> K[])
function Tables.keys(source)
	local result = {}
	for i, v in Tables.iterator(source) do
		table.insert(result, i)
	end
	return result
end

--[[
	Returns an array of all the entries of elements in _source_.

	Each entry is a tuple `(key, value)`.

	@example dash.values({
		Frodo = 1,
		Boromir = 2,
		Bilbo = 3
	}) --> {{"Frodo", 1}, {"Boromir", 2}, {"Bilbo", 3}} (in some order)
]]
--: <T: Iterable<K,V>>(T -> {K, V}[])
function Tables.entries(source)
	local result = {}
	for i, v in Tables.iterator(source) do
		table.insert(result, {i, v})
	end
	return result
end

--[[
	Picks a value from the table that _handler_ returns `true` for.

	If multiple elements might return true, any one of them may be returned as the iteration order
	over a table is stochastic.
	@example
		local names = {
			[3] = "Boromir",
			[1] = "Frodo",
			[8] = "Bilbo"
		}
		local nameWithB = dash.find(names, function(name)
			return dash.startsWith(name, "B")
		end)
		nameWithB --> "Bilbo", 8 (or "Boromir", 3)

		-- Or use a chain:
		local nameWithF = dash.find(names, dash.fn:startsWith(name, "B"))
		nameWithF --> "Frodo", 1

		-- Or find the key of a specific value:
		local _, key = dash.find(names, dash.fn:matches("Bilbo"))
		key --> 8
	@see `dash.first`
	@usage If you need to find the first value of an array that matches, use `dash.first`.
]]
--: <T: Iterable<K,V>>((T, (element: V, key: K) -> bool) -> V?)
function Tables.find(source, handler)
	assertHandlerIsFn(handler)
	for i, v in Tables.iterator(source) do
		if (handler(v, i)) then
			return v, i
		end
	end
end

--[[
	Returns `true` if _item_ exists as a value in the _source_ table.
	@example
		local names = {
			[3] = "Boromir",
			[1] = "Frodo",
			[8] = "Bilbo"
		}
		dash.includes(names, "Boromir") --> true
		dash.includes(names, 1) --> false
]]
--: <T: Iterable<K,V>>(T, V -> bool)
function Tables.includes(source, item)
	return Tables.find(
		source,
		function(value)
			return value == item
		end
	) ~= nil
end

--[[
	Returns the number of elements in _source_.
	@example
		local names = {
			[3] = "Boromir",
			[1] = "Frodo",
			[8] = "Bilbo"
		}
		dash.len(names) --> 3
	@usage Note that a table only has a length if it is an array, so this can be used on non-arrays.
]]
--: <T: Iterable<K,V>>(T -> int)
function Tables.len(source)
	local count = 0
	for _ in Tables.iterator(source) do
		count = count + 1
	end
	return count
end

local function assign(shouldOverwriteTarget, target, ...)
	-- Use select here so that nil arguments can be supported. If instead we
	-- iterated over ipairs({...}), any arguments after the first nil one
	-- would be ignored.
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source ~= nil then
			for key, value in Tables.iterator(source) do
				if shouldOverwriteTarget or target[key] == nil then
					target[key] = value
				end
			end
		end
	end
	return target
end

--[=[
	Adds new elements in _target_ from subsequent table arguments in order, with elements in later
	tables replacing earlier ones if their keys match.
	@param ... any number of other tables
	@example
		local someInfo = {
			Frodo = {
				name = "Frodo Baggins",
				team = "blue"
			},
			Boromir = {
				score = 5
			}
		}
		local someOtherInfo = {
			Frodo = {
				team = "red",
				score = 10
			},
			Bilbo = {
				team = "yellow",

			},
			Boromir = {
				score = {1, 2, 3}
			}
		}
		local assignedInfo = dash.assign(someInfo, someOtherInfo)
		--[[
			--> {
				Frodo = {
					team = "red",
					score = 10
				},
				Bilbo = {
					team = "yellow"
				},
				Boromir = {
					score = {1, 2, 3}
				}
			}
		]]
	@see `dash.defaults`
	@see `dash.merge`
]=]
--: <T: Iterable<K,V>>(mut T, ...T) -> T
function Tables.assign(target, ...)
	return assign(true, target, ...)
end

--[=[
	Adds new elements in _target_ from subsequent table arguments in order, with elements in
	earlier tables overriding later ones if their keys match.
	@param ... any number of other tables
	@example
		local someInfo = {
			Frodo = {
				name = "Frodo Baggins",
				team = "blue"
			},
			Boromir = {
				score = 5
			}
		}
		local someOtherInfo = {
			Frodo = {
				team = "red",
				score = 10
			},
			Bilbo = {
				team = "yellow",

			},
			Boromir = {
				score = {1, 2, 3}
			}
		}
		local assignedInfo = dash.assign(someInfo, someOtherInfo)
		--[[
			--> {
				Frodo = {
					name = "Frodo Baggins",
					team = "blue"
				},
				Boromir = {
					score = 5
				}
				Bilbo = {
					team = "yellow"
				}
			}
		]]
	@see `dash.assign`
	@see `dash.merge`
]=]
--: <T: Iterable<K,V>>(mut T, ...T) -> T
function Tables.defaults(target, ...)
	return assign(false, target, ...)
end

--[[
	Returns a shallow copy of _source_.
	@example
		local Hermione = {
			name = "Hermione Granger",
			time = 12
		}
		local PastHermione = dash.clone(Hermione)
		PastHermione.time = 9
		Hermione.time --> 12
	@see `dash.cloneDeep` - if you also want to clone descendants of the table, though this can be costly.
	@see `dash.map` - if you want to return different values for each key.
	@see `dash.Cloneable` - use this to derive a default `:clone()` method for class instances.
]]
--: <T: Iterable<K,V>>(T -> T)
function Tables.clone(source)
	return Tables.assign({}, source)
end

--[[
	Recursively clones descendants of _source_, returning the cloned object. If references to the
	same table are found, the same clone is used in the result. This means that `dash.cloneDeep` is
	cycle-safe.

	Elements which are not tables are not modified.
	@example
		local Harry = {
			patronus = "stag",
			age = 12
		}
		local Hedwig = {
			animal = "owl",
			owner = Harry
		}
		Harry.pet = Hedwig
		local clonedHarry = dash.cloneDeep(Harry)
		Harry.age = 13
		-- The object clonedHarry is completely independent of any changes to Harry:
		dash.pretty(clonedHarry) --> '<1>{age = 12, patronus = "stag", pet = {animal = "owl", owner = &1}}'
	@see `dash.clone` - if you simply want to perform a shallow clone.
]]
--: <T: Iterable<K,V>>(T -> T)
function Tables.cloneDeep(source)
	local visited = {}
	local function cloneVisit(input)
		if type(input) == "table" then
			if visited[input] == nil then
				visited[input] = {}
				Tables.assign(visited[input], Tables.map(input, cloneVisit))
			end
			return visited[input]
		else
			return input
		end
	end
	return cloneVisit(source)
end

--[[
	Returns `true` if all the values in _left_ match corresponding values in _right_ recursively.

	* For elements which are not tables, they match if they are equal.
	* If they are tables they match if the right table is a subset of the left.

	@example
		local car = {
			speed = 10,
			wheels = 4,
			lightsOn = {
				indicators = true,
				headlights = false
			}
		}
		dash.isSubset(car, {}) --> true
		dash.isSubset(car, car) --> true
		dash.isSubset(car, {speed = 10, lightsOn = {indicators = true}}) --> true
		dash.isSubset(car, {speed = 12}) --> false
		dash.isSubset({}, car) --> false
]]
--: <T>(T{}, T{}) -> bool
function Tables.isSubset(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
	else
		for key, aValue in pairs(left) do
			local bValue = right[key]
			if type(aValue) ~= type(bValue) then
				return false
			elseif aValue ~= bValue then
				if type(aValue) == "table" then
					-- The values are tables, so we need to recurse for a deep comparison.
					if not Tables.isSubset(aValue, bValue) then
						return false
					end
				else
					return false
				end
			end
		end
	end
	return true
end

--[[
	Returns `true` if _source_ has no keys. 
	@example
		dash.isEmpty({}) --> true
		dash.isEmpty({false}) --> false
		dash.isEmpty({a = 1}) --> false
	@usage Note that a table only has a length if it is an array, so this can be used on non-arrays.
]]
--: <T: Iterable<K,V>>(T -> bool)
function Tables.isEmpty(source)
	return Tables.iterator(source)(source) == nil
end

--[[
	Returns an element from _source_, if it has one.

	If there are multiple elements in _source_, any one of them may be returned as the iteration
	order over a table is stochastic.
	@example
		dash.one({}) --> nil
		dash.one({a = 1, b = 2, c = 3}) --> b, 2 (or any another element)
]]
--: <T: Iterable<K,V>>(T -> (V, K)?)
function Tables.one(source)
	local key, value = Tables.iterator(source)(source)
	return value, key
end

--[[
	Returns `true` if every element in _a_ recursively matches every element _b_.

	* For elements which are not tables, they match if they are equal.
	* If they are tables they match if the left is recursively deeply-equal to the right.

	@example
		local car = {
			speed = 10,
			wheels = 4,
			lightsOn = {
				indicators = true,
				headlights = false
			}
		}
		local car2 = {
			speed = 10,
			wheels = 4,
			lightsOn = {
				indicators = false,
				headlights = false
			}
		}
		dash.deepEqual(car, {}) --> false
		dash.deepEqual(car, car) --> true
		dash.deepEqual(car, dash.clone(car)) --> true
		dash.deepEqual(car, dash.cloneDeep(car)) --> true
		dash.deepEqual(car, car2) --> false
	@see `dash.isSubset`
	@see `dash.shallowEqual`
]]
--: any, any -> bool
function Tables.deepEqual(a, b)
	return Tables.isSubset(a, b) and Tables.isSubset(b, a)
end

--[[
	Returns `true` if _left_ and _right_ are equal, or if they are tables and the elements in one
	are present and have equal values to those in the other.
	@example
		local car = {
			speed = 10,
			wheels = 4,
			lightsOn = {
				indicators = true,
				headlights = false
			}
		}
		dash.shallowEqual(car, {}) --> false
		dash.shallowEqual(car, car) --> true
		dash.shallowEqual(car, dash.clone(car)) --> true
		dash.shallowEqual(car, dash.cloneDeep(car)) --> false

	Based on https://developmentarc.gitbooks.io/react-indepth/content/life_cycle/update/using_should_component_update.html
	@see `dash.deepEqual`
]]
--: any, any -> bool
function Tables.shallowEqual(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		return left == right
	end
	local leftKeys = Tables.keys(left)
	local rightKeys = Tables.keys(right)
	if #leftKeys ~= #rightKeys then
		return false
	end
	return Tables.all(
		left,
		function(value, key)
			return value == right[key]
		end
	)
end

--[[
	Returns `true` is _source_ is made up only of natural keys `1..n`.
	@example
		dash.isArray({1, 2, 3}) --> true
		dash.isArray({a = 1, b = 2, c = 3}) --> false
		-- Treating sparse arrays as natural arrays will only complicate things:
		dash.isArray({1, 2, nil, nil, 3}) --> false
		dash.isArray(dash.compact({1, 2, nil, nil, 3})) --> true
]]
--: <T: Iterable<K,V>>(T -> bool)
function Tables.isArray(source)
	return #Tables.keys(source) == #source
end

local function serializeVisit(source, options)
	local Arrays = require(script.Parent.Arrays)
	local isArray = Tables.isArray(source)
	local ref = ""
	local cycles = options.cycles
	if cycles.refs[source] then
		if cycles.visits[source] then
			return "&" .. cycles.visits[source]
		else
			cycles.count = cycles.count + 1
			cycles.visits[source] = cycles.count
			ref = "<" .. cycles.count .. ">"
		end
	end
	local filteredKeys =
		Tables.map(
		Tables.filter(
			-- Sort optimistically so references are more likely to be generated in print order
			options.keys or Arrays.sort(Tables.keys(source)),
			function(key)
				return not Tables.includes(options.omitKeys, key)
			end
		),
		function(key)
			return {key, options.serializeKey(key, options)}
		end
	)

	local contents =
		Tables.map(
		-- Sort keys again in case the serialization doesn't preserve order.
		-- Don't rely on the string value of the object as e.g. a table hash will change its value
		-- between runs.
		Arrays.sort(
			filteredKeys,
			function(left, right)
				return left[2] < right[2]
			end
		),
		function(pair)
			local value = source[pair[1]]
			local stringValue = options.serializeValue(value, options)
			if isArray then
				return stringValue
			else
				return options.serializeElement(pair[2], stringValue, options)
			end
		end
	)
	return options.serializeTable(contents, ref, options)
end

--[[
	A function which provides a simple, shallow string representation of a value.
	@example
		dash.defaultSerializer() --> "nil"
		dash.defaultSerializer(true) --> "true"
		dash.defaultSerializer(5.8) --> "5.8"
		dash.defaultSerializer("Hello " .. \n .. " there") --> '"Hello \n there"'
]]
--: any -> string
function Tables.defaultSerializer(input)
	if input == nil then
		return "nil"
	elseif type(input) == "number" or type(input) == "boolean" then
		return tostring(input)
	elseif type(input) == "string" then
		return '"' .. input:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
	else
		return "<" .. tostring(input) .. ">"
	end
end

local function countOccurences(source, counts)
	for key, value in Tables.iterator(source) do
		if type(value) == "table" then
			if counts[value] then
				counts[value] = counts[value] + 1
			else
				counts[value] = 1
				countOccurences(value, counts)
			end
		end
	end
end

local function getDefaultSerializeOptions()
	return {
		serializeValue = Tables.defaultSerializer,
		serializeKey = Tables.defaultSerializer,
		serializeElement = function(key, value, options)
			return key .. options.keyDelimiter .. value
		end,
		serializeTable = function(contents, ref, options)
			return ref .. "{" .. table.concat(contents, options.valueDelimiter) .. "}"
		end,
		keyDelimiter = ":",
		valueDelimiter = ",",
		cycles = {
			count = 0,
			visits = {}
		},
		omitKeys = {}
	}
end

--[[
	Returns a string representation of _source_ including all elements with sorted keys.
	
	`dash.serialize` preserves the properties of being unique, stable and cycle-safe if the serializer
	functions provided also obey these properties.

	@param serializeValue (default = `dash.defaultSerializer`) return a string representation of a value
	@param serializeKey (default = `dash.defaultSerializer`) return a string representation of a value

	@example dash.serialize({1, 2, 3}) --> "{1,2,3}"
	@example dash.serialize({a = 1, b = true, [3] = "hello"}) --> '{"a":1,"b":true,3:"hello"}'
	@example 
		dash.serialize({a = function() end, b = {a = "table"})
		--> '{"a":<function: 0x...>,"b"=<table: 0x...>}'
	@usage Use `dash.serialize` when you need a representation of a table which doesn't need to be
		human-readable, or you need to customize the way serialization works. `dash.pretty` is more
		appropriate when you need a human-readable string.
	@see `dash.serializeDeep`
	@see `dash.defaultSerializer`
	@see `dash.pretty`
]]
--: <T: Iterable<K,V>>((T, SerializeOptions<T>) -> string)
function Tables.serialize(source, options)
	options = Tables.defaults({}, options, getDefaultSerializeOptions())
	assert(t.string(options.valueDelimiter), "BadInput: options.valueDelimiter must be a string if defined")
	assert(t.string(options.keyDelimiter), "BadInput: options.keyDelimiter must be a string if defined")
	local Functions = require(script.Parent.Functions)
	assert(Functions.isCallable(options.serializeValue), "BadInput: options.serializeValue must be a function if defined")
	assert(Functions.isCallable(options.serializeKey), "BadInput: options.serializeKey must be a function if defined")
	if type(source) ~= "table" then
		return options.serializeValue(source, options)
	end

	-- Find tables which appear more than once, and assign each an index
	if not options.cycles.refs then
		options.cycles.refs =
			Tables.map(
			Tables.occurences(source),
			function(value)
				return value > 1 and value or nil
			end
		)
	end
	return serializeVisit(source, options)
end

--[[
	Like `dash.serialize`, but if a child element is a table it is serialized recursively.

	Returns a string representation of _source_ including all elements with sorted keys.
	
	This function preserves uniqueness, stability and cycle-safety.

	@param serializeValue (default = `dash.defaultSerializer`) return a string representation of a value
	@param serializeKey (default = `dash.defaultSerializer`) return a string representation of a value

	@example 
		dash.serializeDeep({a = {b = "table"}) --> '{"a":{"b":"table"}}'
	@example 
		local kyle = {name = "Kyle"}
		kyle.child = kyle
		dash.serializeDeep(kyle) --> '<0>{"child":<&0>,"name":"Kyle"}'
	@see `dash.serialize`
	@see `dash.defaultSerializer`
]]
--: <T: Iterable<K,V>>((T, SerializeOptions<T>) -> string)
function Tables.serializeDeep(source, options)
	options = Tables.defaults({}, options, getDefaultSerializeOptions())
	local Functions = require(script.Parent.Functions)
	assert(Functions.isCallable(options.serializeValue), "BadInput: options.serializeValue must be a function if defined")
	assert(Functions.isCallable(options.serializeKey), "BadInput: options.serializeKey must be a function if defined")
	local function deepSerializer(fn, value, internalOptions)
		if type(value) == "table" then
			return Tables.serialize(value, internalOptions)
		else
			return fn(value, internalOptions)
		end
	end
	local serializeOptions =
		Tables.defaults(
		{
			serializeKey = Functions.bind(deepSerializer, options.serializeKey),
			serializeValue = Functions.bind(deepSerializer, options.serializeValue)
		},
		options
	)
	return Tables.serialize(source, serializeOptions)
end

--[=[
	Return a set of the tables that appear as descendants of _source_, mapped to the number of
	times each table has been found with a unique parent.

	Repeat occurences are not traversed, so the function is cycle-safe. If any tables in the
	result have a count of two or more, they may form cycles in the _source_.
	@example
		local plate = {veg = "potato", pie = {"stilton", "beef"}}
		dash.occurences(plate) --[[> {
			[{veg = "potato", pie = {"stilton", "beef"}}] = 1
			[{"stilton", "beef"}] = 1
		}]]
	@example
		local kyle = {name = "Kyle"}
		kyle.child = kyle
		dash.occurences(kyle) --[[> {
			[{name = "Kyle", child = kyle}] = 2
		}]]
]=]
--: <T: Iterable<K,V>>(T -> {[T]:int})
function Tables.occurences(source)
	assert(t.table(source), "BadInput: source must be a table")
	local counts = {[source] = 1}
	countOccurences(source, counts)
	return counts
end

--[[
	Returns an array of the values in _source_, without any repetitions.

	Values are considered equal if the have the same key representation.

	@example
		local list = {1, 2, 2, 3, 5, 1}
		dash.unique(list) --> {1, 2, 3, 5} (or another order)
]]
--: <T>(T[] -> T[])
function Tables.unique(source)
	return Tables.keys(Tables.invert(source))
end

return Tables
