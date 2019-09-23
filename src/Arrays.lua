--[=[
	A collection of functions that operate specifically on arrays, defined as tables with just keys _1..n_.

	```lua
		-- Examples of valid arrays:
		{}
		{"red", "green", "blue"}
		{"winter", {is = "coming"}, [3] = "again"}
		{1966, nil, nil}
		-- Examples of invalid arrays:
		{1994, nil, 2002}
		{you = {"know", "nothing"}}
		{[5] = "gold rings"}
		42
	```

	These functions can iterate over any [Ordered](/rodash/types#Ordered) values.
]=]
local t = require(script.Parent.Parent.t)
local Tables = require(script.Parent.Tables)

local Arrays = {}

local function assertHandlerIsFn(handler)
	local Functions = require(script.Parent.Functions)
	assert(Functions.isCallable(handler), "BadInput: handler must be a function")
end
local function assertPredicateIsFn(handler)
	local Functions = require(script.Parent.Functions)
	assert(Functions.isCallable(handler), "BadInput: handler must be a function")
end

local typeIndex = {
	boolean = 1,
	number = 2,
	string = 3,
	["function"] = 4,
	["CFunction"] = 5,
	userdata = 6,
	table = 7
}

--[[
	Given two values _a_ and _b_, this function return `true` if _a_ is typically considered lower
	than _b_.

	The default comparator is used by `dash.sort` and can sort elements of different types, in the
	order: boolean, number, string, function, CFunction, userdata, and table.

	Elements which cannot be sorted naturally will be sorted by their string value.

	@see `dash.sort`
]]
--: <T>((T, T) -> bool)
function Arrays.defaultComparator(a, b)
	if type(a) ~= type(b) then
		return typeIndex[type(a)] - typeIndex[type(b)]
	end
	local ok, result =
		pcall(
		function()
			return a < b
		end
	)
	if ok then
		return result
	else
		return tostring(a) < tostring(b)
	end
end

--[[
	Returns a sorted array from the _input_ array, based on a _comparator_ function.

	Unlike `table.sort`, the comparator to `dash.sort` is optional, but if defined it can also
	return a numeric weight or nil as well as a boolean to provide an ordering of the elements.

	@param comparator should return `true` or `n < 0` if the first element should be before the second in the resulting array, or `0` or `nil` if the elements have the same order.

	@example dash.sort({2, 5, 3}) --> {2, 3, 5}
	@example dash.sort({"use", "the", "force", "Luke"}) --> {"Luke", "force", "the", "use"}
	@example
		dash.sort({
			name = "Luke",
			health = 50
		}, {
			name = "Yoda",
			health = 9001
		}, {
			name = "Jar Jar Binks",
			health = 0
		}, function(a, b)
			return a.health < b.health
		end) --> the characters sorted in ascending order by their health
]]
--: <T>(T[], (T -> bool | number | nil)? -> T[])
function Arrays.sort(input, comparator)
	assert(t.table(input), "BadInput: input must be an array")

	local Functions = require(script.Parent.Functions)
	assert(comparator == nil or Functions.isCallable(comparator), "BadInput: comparator must be callable or nil")

	comparator = comparator or Arrays.defaultComparator

	table.sort(
		input,
		function(a, b)
			local result = comparator(a, b)

			if type(result) ~= "number" and type(result) ~= "boolean" and result ~= nil then
				error("BadResult: comparator must return a boolean, a number or nil")
			end

			return result == true or (type(result) == "number" and result < 0)
		end
	)

	return input
end

--[[
	Returns a copied portion of the _source_, between the _first_ and _last_ elements inclusive and
	jumping _step_ each time if provided.
	
	@param first (default = 1) The index of the first element to include.
	@param last (default = `#source`) The index of the last element to include.
	@param step (default = 1) What amount to step the index by during iteration.
	@example dash.slice({10, 20, 30, 40}) --> {10, 20, 30, 40}
	@example dash.slice({10, 20, 30, 40}, 2) --> {20, 30, 40}
	@example dash.slice({10, 20, 30, 40}, 2, 3) --> {20, 30}
	@example dash.slice({10, 20, 30, 40}, 2, 4, 2) --> {20, 40}
]]
--: <T>(T[], int?, int?, int? -> T[])
function Arrays.slice(source, first, last, step)
	assert(t.table(source), "BadInput: source must be an array")
	assert(t.optional(t.number)(first), "BadInput: first must be an int")
	assert(t.optional(t.number)(last), "BadInput: last must be an int")
	assert(t.optional(t.number)(step), "BadInput: step must be an int")
	local sliced = {}

	for i = first or 1, last or #source, step or 1 do
		sliced[#sliced + 1] = source[i]
	end

	return sliced
end

--[[
	Returns a new array with the order of the values from _source_ randomized.
	@example
		local teamColors = {"red", "red", "red", "blue", "blue", "blue"}
		-- (in some order)
		dash.shuffle(teamColors) --> {"blue", "blue", "red", "blue", "red", "red"}
]]
--: <T>(T[] -> T[])
function Arrays.shuffle(source)
	assert(t.table(source), "BadInput: source must be an array")
	local result = Tables.clone(source)
	for i = #result, 1, -1 do
		local j = math.random(i)
		result[i], result[j] = result[j], result[i]
	end
	return result
end

--[[
	Runs the _handler_ on each element of _source_ in turn, passing the result of the previous call
	(or _initial_ for the first element) as the first argument, and the current element as a value
	and key as subsequent arguments.
	@example
		local sum = dash.reduce({1, 2, 3}, function(result, value)
			return result + value
		end, 0)
		sum --> 6
	@example
		local recipe = {first = "cheese", second = "nachos", third = "chillies"}
		local unzipRecipe = dash.reduce(recipe, function(result, value, key)
			table.insert(result[1], key)
			table.insert(result[2], value)
			return result
		end, {{}, {}})
		-- (in some order)
		unzipRecipe --> {{"first", "third", "second"}, {"cheese", "chillies", "nachos"}}
]]
--: <T, R>(Ordered<T>, (result: R, value: T, key: int -> R), R) -> R
function Arrays.reduce(source, handler, initial)
	local result = initial
	for i, v in Tables.iterator(source, true) do
		result = handler(result, v, i)
	end
	return result
end

--[[
	Inserts into the _target_ array the elements from all subsequent arguments in order.
	@param ... any number of other arrays
	@example dash.append({}, {1, 2, 3}, {4, 5, 6}) --> {1, 2, 3, 4, 5, 6}
	@example dash.append({1, 2, 3}) --> {1, 2, 3}
	@example
		local list = {"cheese"}
		dash.append(list, {"nachos"}, {}, {"chillies"})
		list --> {"cheese", "nachos", "chillies"}
]]
--: <T>(mut T[], ...Ordered<T> -> T[])
function Arrays.append(target, ...)
	for i = 1, select("#", ...) do
		local x = select(i, ...)
		for _, y in Tables.iterator(x, true) do
			table.insert(target, y)
		end
	end

	return target
end

--[[
	Sums all the values in the _source_ array.
	@example dash.sum({1, 2, 3}) --> 6
]]
--: Ordered<number> -> number
function Arrays.sum(source)
	return Arrays.reduce(
		source,
		function(current, value)
			return current + value
		end,
		0
	)
end

--[[
	Swaps the order of elements in _source_.
	@example dash.reverse({1, 2, 4, 3, 5}) --> {5, 3, 4, 2, 1}
]]
--: <T>(T[] -> T[])
function Arrays.reverse(source)
	local output = {}
	for i = #source, 1, -1 do
		table.insert(output, source[i])
	end
	return output
end

--[[
	Returns the earliest value from the array that _predicate_ returns `true` for.

	If the _predicate_ is not specified, `dash.first` simply returns the first element of the array.
	@param predicate (default = `dash.returns(true)`)
	@example
		local names = {
			"Boromir",
			"Frodo",
			"Bilbo"
		}

		dash.first(names) --> "Boromir", 1

		-- Find a particular value:
		local firstNameWithF = dash.first(names, function(name)
			return dash.startsWith(name, "F")
		end)
		firstNameWithF --> "Frodo", 2

		-- What about a value which doesn't exist?
		local firstNameWithC = dash.first(names, function(name)
			return dash.startsWith(name, "C")
		end)
		firstNameWithC --> nil

		-- Find the index of a value:
		local _, index = dash.first(names, dash.fn:matches("Bilbo"))
		index --> 2
	@see `dash.find` 
	@usage If you need to find a value in a table which isn't an array, use `dash.find`.
]]
--: <T: Iterable<K,V>>(T, (element: V, key: K -> bool) -> V?)
function Arrays.first(source, predicate)
	predicate = predicate or function()
			return true
		end
	assertPredicateIsFn(predicate)
	for i, v in Tables.iterator(source, true) do
		if (predicate(v, i)) then
			return v, i
		end
	end
end

--[[
	Returns the last value from the array that _predicate_ returns `true` for.

	If the _predicate_ is not specified, `dash.last` simply returns the last element of the array.
	@param predicate (default = `dash.returns(true)`)
	@example
		local names = {
			"Boromir",
			"Frodo",
			"Bilbo"
		}

		dash.last(names) --> "Bilbo", 3

		local lastNameWithB = dash.last(names, dash.fn:startsWith("B"))
		lastNameWithB --> "Bilbo", 3

		local _, key = dash.last(names, dash.fn:matches("Frodo"))
		key --> 2
	@see `dash.find`
	@see `dash.first`
]]
--: <T: Iterable<K,V>>(T, (element: V, key: K -> bool) -> V?)
function Arrays.last(source, predicate)
	predicate = predicate or function()
			return true
		end
	assertHandlerIsFn(predicate)
	for i = #source, 1, -1 do
		local value = source[i]
		if (predicate(value, i)) then
			return value, i
		end
	end
end

return Arrays
