--[[
	Tables is a library to handle tables. There are some reasons for this:

	* Great docs
	* Some custom

	## Examples

	For example:

		There are two ways to do this

	Right?
]]
local t = require(script.Parent.t)

local Tables = {}

local function getIterator(source)
	if type(source) == "function" then
		return source
	else
		assert(type(source) == "table", "Can only iterate over a table or an iterator function")
		return pairs(source)
	end
end

--: <T>(T[], int?, int?, int?) -> T[]
function Tables.slice(source, first, last, step)
	local sliced = {}

	for i = first or 1, last or #source, step or 1 do
		sliced[#sliced + 1] = source[i]
	end

	return sliced
end

--: <T: Iterable<K,V>, R: Iterable<K,V2>((T, (element: V, key: K) -> V2) -> R)
function Tables.map(source, handler)
	local result = {}
	for i, v in getIterator(source) do
		result[i] = handler(v, i)
	end
	return result
end

--: <T: Iterable<K,V>, R: Iterable<K,V2>((T, (element: V, key: K) -> V2) -> R)
function Tables.mapKeys(source, handler)
	local result = {}
	for i, v in getIterator(source) do
		result[handler(v, i)] = v
	end
	return result
end

--: <T: Iterable<K,V>, U>((T, (element: V, key: K) -> U[] | U) -> U[])
function Tables.flatMap(source, handler)
	local result = {}
	for i, v in getIterator(source) do
		local list = handler(v, i)
		if type(list) == "table" then
			Tables.insertMany(result, list)
		else
			table.insert(result, list)
		end
	end
	return result
end

--: <T: Iterable>(T -> T)
function Tables.shuffle(source)
	local result = Tables.clone(source)
	for i = #result, 1, -1 do
		local j = math.random(i)
		result[i], result[j] = result[j], result[i]
	end
	return result
end

--: <T: Iterable<K,V>>(T, (element: V, key: K -> bool) -> V[])
function Tables.filter(source, handler)
	local result = {}
	for i, v in getIterator(source) do
		if handler(v, i) then
			table.insert(result, v)
		end
	end
	return result
end

--: <T: Iterable<K,V>>(T, (element: V, key: K -> bool) -> T)
function Tables.filterKeys(source, handler)
	local result = {}
	for i, v in getIterator(source) do
		if handler(v, i) then
			result[i] = v
		end
	end
	return result
end

--: <T: Iterable<K,V>, R: Iterable<K,U>>(T, (element: V, key: K -> U) -> R
function Tables.filterKeysMap(source, handler)
	local result = {}
	for i, v in getIterator(source) do
		local value = handler(v, i)
		if value ~= nil then
			result[i] = value
		end
	end
	return result
end

function Tables.omitBy(source, handler)
	local result = {}

	for i, v in getIterator(source) do
		local value = handler(v, i)
		if not value then
			result[i] = v
		end
	end
	return result
end

--: <T: Iterable<K,V>>(T, V -> T)
function Tables.without(source, element)
	return Tables.filter(
		source,
		function(child)
			return child ~= element
		end
	)
end

--: <T: Iterable<K,V>>(T, T)
function Tables.compact(source)
	return Tables.filter(
		source,
		function(value)
			return value
		end
	)
end

--: <T, R>(T[], (acc: R, current: T, key: int -> R), R) -> R
function Tables.reduce(source, handler, init)
	local result = init
	for i, v in getIterator(source) do
		result = handler(result, v, i)
	end
	return result
end

--[[
	Wow
]]
--: <T: Iterable<K,V>>(T -> bool)
function Tables.all(source, handler)
	if not handler then
		handler = function(x)
			return x
		end
	end
	-- Use double negation to coerce the type to a boolean, as there is
	-- no toboolean() or equivalent in Lua.
	return not (not Tables.reduce(
		source,
		function(acc, value, key)
			return acc and handler(value, key)
		end,
		true
	))
end
--: <T: Iterable<K,V>>(T -> bool)
function Tables.any(source, handler)
	if not handler then
		handler = function(x)
			return x
		end
	end
	-- Use double negation to coerce the type to a boolean, as there is
	-- no toboolean() or equivalent in Lua.
	return not (not Tables.reduce(
		source,
		function(acc, value, key)
			return acc or handler(value, key)
		end,
		false
	))
end

--[[
	Summary ends with a period.
	Some description, can be over
	several lines.
	```
	local test = {}
	```
]]
--: <T>(T[] -> T[])
function Tables.reverse(source)
	local output = Tables.clone(source)
	local i = 1
	local j = #source
	while i < j do
		output[i], output[j] = output[j], output[i]
		i = i + 1
		j = j - 1
	end
	return output
end

--: <K: Key, V>(Iterable<K,V> -> Iterable<V,K>)
function Tables.invert(source)
	local result = {}
	for i, v in getIterator(source) do
		result[v] = i
	end
	return result
end

--: <T, K: Key>(T[], (T -> K) -> Iterable<K,V>)
function Tables.keyBy(source, handler)
	local result = {}
	for i, v in getIterator(source) do
		local key = handler(v, i)
		if key ~= nil then
			result[key] = v
		end
	end
	return result
end

--[[
	Summary ends with a period.
	This extracts the shortest common substring from the strings _s1_ and _s2_
	```function M.common_substring(s1,s2)```
	several lines.
	@string source first parameter
	@tparam string->int handler parameter
	@treturn string a string value
]]
--: <T: Iterable<K,V>, I: Key>((value: T, key: K) -> I) -> Iterable<I, Iterable<K,V>>)
function Tables.groupBy(source, handler)
	local result = {}
	for i, v in getIterator(source) do
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

function Tables.merge(target, ...)
	-- Use select here so that nil arguments can be supported. If instead we
	-- iterated over ipairs({...}), any arguments after the first nil one
	-- would be ignored.
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source ~= nil then
			for key, value in getIterator(source) do
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

--: table -> any[]
function Tables.values(source)
	local result = {}
	for i, v in getIterator(source) do
		table.insert(result, v)
	end
	return result
end

--: table -> any[]
function Tables.keys(source)
	local result = {}
	for i, v in getIterator(source) do
		table.insert(result, i)
	end
	return result
end

--: table -> [string | int, any][]
function Tables.entries(source)
	local result = {}
	for i, v in getIterator(source) do
		table.insert(result, {i, v})
	end
	return result
end

--: <T: Iterable<K,V>>((T, (element: V, key: K) -> bool) -> V)
function Tables.find(source, handler)
	for i, v in getIterator(source) do
		if (handler(v, i)) then
			return v
		end
	end
end

--: <T: Iterable<K,V>>((T, (element: V, key: K) -> bool) -> K)
function Tables.findKey(source, handler)
	for i, v in getIterator(source) do
		if (handler(v, i)) then
			return i
		end
	end
end

--: table, any -> boolean
function Tables.includes(source, item)
	return Tables.find(
		source,
		function(value)
			return value == item
		end
	) ~= nil
end

--: (table, any) -> int?
function Tables.keyOf(source, value)
	for k, v in getIterator(source) do
		if (value == v) then
			return k
		end
	end
end

--: (any[], any[]) -> any[]
function Tables.insertMany(target, items)
	for _, v in getIterator(items) do
		table.insert(target, v)
	end
	return target
end

--: (table) -> int
function Tables.getLength(table)
	local count = 0
	for _ in pairs(table) do
		count = count + 1
	end
	return count
end

local function assign(overwriteTarget, target, ...)
	-- Use select here so that nil arguments can be supported. If instead we
	-- iterated over ipairs({...}), any arguments after the first nil one
	-- would be ignored.
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source ~= nil then
			for key, value in getIterator(source) do
				if overwriteTarget or target[key] == nil then
					target[key] = value
				end
			end
		end
	end
	return target
end

function Tables.assign(target, ...)
	return assign(true, target, ...)
end

function Tables.defaults(target, ...)
	return assign(false, target, ...)
end

--: (table) -> table
function Tables.clone(tbl)
	return Tables.assign({}, tbl)
end

function Tables.isSubset(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	else
		for key, aValue in pairs(a) do
			local bValue = b[key]
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

function Tables.deepEquals(a, b)
	return Tables.isSubset(a, b) and Tables.isSubset(b, a)
end

-- Based on https://developmentarc.gitbooks.io/react-indepth/content/life_cycle/update/using_should_component_update.html
function Tables.shallowEqual(left, right)
	if left == right then
		return true
	end
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
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

function Tables.serialize(input, serializer)
	serializer = serializer or function(value)
			return tostring(value)
		end
	assert(type(input) == "table")
	assert(type(serializer) == "function")
	return "{" ..
		table.concat(
			Tables.map(
				input,
				function(element, i)
					return tostring(i) .. "=" .. serializer(element)
				end
			),
			","
		) ..
			"}"
end

function Tables.append(...)
	local result = {}
	for i = 1, select("#", ...) do
		local x = select(i, ...)
		if type(x) == "table" then
			for _, y in ipairs(x) do
				table.insert(result, y)
			end
		else
			table.insert(result, x)
		end
	end

	return result
end

function Tables.sort(input, comparator)
	assert(t.table(input), input)

	local Functions = require(script.Functions)
	assert(comparator == nil or Functions.isCallable(comparator), "comparator must be callable or nil")

	comparator = comparator or function(a, b)
			return a < b
		end

	table.sort(
		input,
		function(a, b)
			local result = comparator(a, b)

			if type(result) ~= "boolean" and result ~= nil then
				error("sort comparator must return a boolean or nil")
			end

			return result
		end
	)

	return input
end

return Tables
