local tea = require(script.Parent.Parent.tea)

local TableUtils = {}

setmetatable(
	TableUtils,
	{
		__index = function(table, key)
			local lowerFirst = key:sub(1, 1):lower() .. key:sub(2)
			if lowerFirst ~= key then
				print(
					"DEPRECATED: " ..
						key .. " and other capitalized functions in TableUtils are deprecated. Please use the lower-case version instead.",
					debug.traceback()
				)
				return TableUtils[lowerFirst]
			end
		end
	}
)

local function getIterator(source)
	if type(source) == "function" then
		return source
	else
		assert(type(source) == "table", "Can only iterate over a table or an iterator function")
		return pairs(source)
	end
end

function TableUtils.slice(tbl, first, last, step) --: <T>(T[], number?, number?, number?) => T[]
	local sliced = {}

	for i = first or 1, last or #tbl, step or 1 do
		sliced[#sliced + 1] = tbl[i]
	end

	return sliced
end

function TableUtils.map(source, handler) --: <T extends Iterable<K,V>, R extends Iterable<K,V2>((T, (element: V, key: K) => V2) => R)
	local result = {}
	for i, v in getIterator(source) do
		result[i] = handler(v, i)
	end
	return result
end

function TableUtils.flatMap(source, handler) --: <T extends Iterable<K,V>, U>((T, (element: V, key: K) => U[] | U) => U[])
	local result = {}
	for i, v in getIterator(source) do
		local list = handler(v, i)
		if type(list) == "table" then
			TableUtils.insertMany(result, list)
		else
			table.insert(result, list)
		end
	end
	return result
end

function TableUtils.shuffle(source) --: <T extends Iterable>(T => T)
	local result = TableUtils.clone(source)
	for i = #result, 1, -1 do
		local j = math.random(i)
		result[i], result[j] = result[j], result[i]
	end
	return result
end

function TableUtils.filter(source, handler) --: <T extends Iterable<K,V>>(T, (element: V, key: K => boolean) => V[])
	local result = {}
	for i, v in getIterator(source) do
		if handler(v, i) then
			table.insert(result, v)
		end
	end
	return result
end

function TableUtils.filterKeys(source, handler) --: <T extends Iterable<K,V>>(T, (element: V, key: K => boolean) => T)
	local result = {}
	for i, v in getIterator(source) do
		if handler(v, i) then
			result[i] = v
		end
	end
	return result
end

function TableUtils.filterKeysMap(source, handler) --: <T extends Iterable<K,V>, R extends Iterable<K,U>>(T, (element: V, key: K => U) => R
	local result = {}
	for i, v in getIterator(source) do
		local value = handler(v, i)
		if value ~= nil then
			result[i] = value
		end
	end
	return result
end

function TableUtils.without(source, element) --: <T extends Iterable<K,V>>(T, V => T)
	return TableUtils.filter(
		source,
		function(child)
			return child ~= element
		end
	)
end

function TableUtils.compact(source) --: <T extends Iterable<K,V>>(T, T)
	return TableUtils.filter(
		source,
		function(value)
			return value
		end
	)
end

function TableUtils.reduce(source, handler, init) --: <T, R>(T[], (acc: R, current: T, key: number => R), R) => R
	local result = init
	for i, v in getIterator(source) do
		result = handler(result, v, i)
	end
	return result
end

function TableUtils.all(source, handler) --: <T extends Iterable<K,V>>(T => boolean)
	if not handler then
		handler = function(x)
			return x
		end
	end
	-- Use double negation to coerce the type to a boolean, as there is
	-- no toboolean() or equivalent in Lua.
	return not (not TableUtils.reduce(
		source,
		function(acc, value, key)
			return acc and handler(value, key)
		end,
		true
	))
end
function TableUtils.any(source, handler) --: <T extends Iterable<K,V>>(T => boolean)
	if not handler then
		handler = function(x)
			return x
		end
	end
	-- Use double negation to coerce the type to a boolean, as there is
	-- no toboolean() or equivalent in Lua.
	return not (not TableUtils.reduce(
		source,
		function(acc, value, key)
			return acc or handler(value, key)
		end,
		false
	))
end

function TableUtils.reverse(source)
	local output = TableUtils.clone(source)
	local i = 1
	local j = #source
	while i < j do
		output[i], output[j] = output[j], output[i]
		i = i + 1
		j = j - 1
	end
	return output
end

function TableUtils.invert(source) --: <K extends Key, V>(Iterable<K,V> => Iterable<V,K>)
	local result = {}
	for i, v in getIterator(source) do
		result[v] = i
	end
	return result
end

function TableUtils.keyBy(source, handler) --: <T, K extends Key>(T[], (T => K) => Iterable<K,V>)
	local result = {}
	for i, v in getIterator(source) do
		local key = handler(v, i)
		if key ~= nil then
			result[key] = v
		end
	end
	return result
end

function TableUtils.groupBy(source, handler) --: <T extends Iterable<K,V>, I extends Key>((value: T, key: K) => I) => Iterable<I, Iterable<K,V>>)
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

function TableUtils.merge(target, ...)
	-- Use select here so that nil arguments can be supported. If instead we
	-- iterated over ipairs({...}), any arguments after the first nil one
	-- would be ignored.
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source ~= nil then
			for key, value in getIterator(source) do
				if type(target[key]) == "table" and type(value) == "table" then
					target[key] = TableUtils.merge(target[key] or {}, value)
				else
					target[key] = value
				end
			end
		end
	end
	return target
end

function TableUtils.values(source) --: table => any[]
	local result = {}
	for i, v in getIterator(source) do
		table.insert(result, v)
	end
	return result
end

function TableUtils.keys(source) --: table => any[]
	local result = {}
	for i, v in getIterator(source) do
		table.insert(result, i)
	end
	return result
end

function TableUtils.entries(source) --: table => [string | number, any][]
	local result = {}
	for i, v in getIterator(source) do
		table.insert(result, {i, v})
	end
	return result
end

function TableUtils.find(source, handler) --: <T extends Iterable<K,V>>((T, (element: V, key: K) => boolean) => V)
	for i, v in getIterator(source) do
		if (handler(v, i)) then
			return v
		end
	end
end

function TableUtils.findKey(source, handler) --: <T extends Iterable<K,V>>((T, (element: V, key: K) => boolean) => K)
	for i, v in getIterator(source) do
		if (handler(v, i)) then
			return i
		end
	end
end

function TableUtils.includes(source, item) --: table, any => boolean
	return TableUtils.find(
		source,
		function(value)
			return value == item
		end
	) ~= nil
end

function TableUtils.keyOf(source, value) --: (table, any) => number?
	for k, v in getIterator(source) do
		if (value == v) then
			return k
		end
	end
end

function TableUtils.insertMany(target, items) --: (any[], any[]) => any[]
	for _, v in getIterator(items) do
		table.insert(target, v)
	end
	return target
end

function TableUtils.getLength(table) --: (table) => number
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

function TableUtils.assign(target, ...)
	return assign(true, target, ...)
end

function TableUtils.defaults(target, ...)
	return assign(false, target, ...)
end

function TableUtils.clone(tbl) --: (table) => table
	return TableUtils.assign({}, tbl)
end

function TableUtils.isSubset(a, b)
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
					if not TableUtils.isSubset(aValue, bValue) then
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

function TableUtils.deepEquals(a, b)
	return TableUtils.isSubset(a, b) and TableUtils.isSubset(b, a)
end

-- Based on https://developmentarc.gitbooks.io/react-indepth/content/life_cycle/update/using_should_component_update.html
function TableUtils.shallowEqual(left, right)
	if left == right then
		return true
	end
	if type(left) ~= "table" or type(right) ~= "table" then
		return false
	end
	local leftKeys = TableUtils.keys(left)
	local rightKeys = TableUtils.keys(right)
	if #leftKeys ~= #rightKeys then
		return false
	end
	return TableUtils.all(
		left,
		function(value, key)
			return value == right[key]
		end
	)
end

function TableUtils.serialize(input, serializer)
	serializer = serializer or function(value)
			return tostring(value)
		end
	assert(type(input) == "table")
	assert(type(serializer) == "function")
	return "{" ..
		table.concat(
			TableUtils.map(
				input,
				function(element, i)
					return tostring(i) .. "=" .. serializer(element)
				end
			),
			","
		) ..
			"}"
end

function TableUtils.append(...)
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

function TableUtils.sort(input, comparator)
	assert(tea.table(input), input)

	local FunctionUtils = require(script.Parent.FunctionUtils)
	assert(comparator == nil or FunctionUtils.isCallable(comparator), "comparator must be callable or nil")

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

return TableUtils
