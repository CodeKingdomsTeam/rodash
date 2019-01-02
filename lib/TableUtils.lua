local TableUtils = {}

function TableUtils.Slice(tbl, first, last, step) --: (any[], number?, number?, number?) => any[]
	local sliced = {}

	for i = first or 1, last or #tbl, step or 1 do
		sliced[#sliced + 1] = tbl[i]
	end

	return sliced
end

function TableUtils.Map(source, handler) --: ((any[], (element: any, key: number) => any) => any[]) | ((table, (element: any, key: string) => any) => table)
	local result = {}
	for i, v in pairs(source) do
		result[i] = handler(v, i)
	end
	return result
end

function TableUtils.Filter(source, handler) --: table, (element: any, key: number | string => boolean) => any[]
	local result = {}
	for i, v in pairs(source) do
		if (handler(v, i)) then
			table.insert(result, v)
		end
	end
	return result
end

function TableUtils.Reduce(source, handler, init) --: <T>(any[], (previous: T, current: any,  key: number | string => T), T?) => T
	local result = init
	for i, v in pairs(source) do
		result = handler(result, v, i)
	end
	return result
end

function TableUtils.All(source, handler) --: table => boolean
	if not handler then
		handler = function(x)
			return x
		end
	end
	-- Use double negation to coerce the type to a boolean, as there is
	-- no toboolean() or equivalent in Lua.
	return not (not TableUtils.Reduce(
		source,
		function(acc, value, key)
			return acc and handler(value, key)
		end,
		true
	))
end
function TableUtils.Any(source, handler) --: table => boolean
	if not handler then
		handler = function(x)
			return x
		end
	end
	-- Use double negation to coerce the type to a boolean, as there is
	-- no toboolean() or equivalent in Lua.
	return not (not TableUtils.Reduce(
		source,
		function(acc, value, key)
			return acc or handler(value, key)
		end,
		false
	))
end

function TableUtils.Invert(source) --: table => table
	local result = {}
	for i, v in pairs(source) do
		result[v] = i
	end
	return result
end

function TableUtils.Values(source) --: table => any[]
	local result = {}
	for i, v in pairs(source) do
		table.insert(result, v)
	end
	return result
end

function TableUtils.Keys(source) --: table => any[]
	local result = {}
	for i, v in pairs(source) do
		table.insert(result, i)
	end
	return result
end

function TableUtils.Entries(source) --: table => [string | number, any][]
	local result = {}
	for i, v in pairs(source) do
		table.insert(result, {i, v})
	end
	return result
end

function TableUtils.Find(source, handler) --: ((any[], (element: any, key: number) => boolean) => any) | ((table, (element: any, key: string) => boolean) => any)
	for i, v in pairs(source) do
		if (handler(v, i)) then
			return v
		end
	end
end

function TableUtils.Includes(source, item) --: table, any => boolean
	return TableUtils.Find(
		source,
		function(value)
			return value == item
		end
	) ~= nil
end

function TableUtils.KeyOf(source, value) --: (table, any) => number?
	for k, v in pairs(source) do
		if (value == v) then
			return k
		end
	end
end

function TableUtils.InsertMany(target, items) --: (any[], any[]) => any[]
	for _, v in ipairs(items) do
		table.insert(target, v)
	end
	return
end

function TableUtils.GetLength(table) --: (table) => number
	local count = 0
	for _ in pairs(table) do
		count = count + 1
	end
	return count
end

function TableUtils.Assign(target, ...)
	-- Use select here so that nil arguments can be supported. If instead we
	-- iterated over ipairs({...}), any arguments after the first nil one
	-- would be ignored.
	for i = 1, select("#", ...) do
		local source = select(i, ...)
		if source ~= nil then
			for key, value in pairs(source) do
				target[key] = value
			end
		end
	end
	return target
end

function TableUtils.Clone(tbl) --: (table) => table
	return TableUtils.Assign({}, tbl)
end

function TableUtils.IsSubset(a, b)
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
					if not TableUtils.IsSubset(aValue, bValue) then
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

function TableUtils.DeepEquals(a, b)
	return TableUtils.IsSubset(a, b) and TableUtils.IsSubset(b, a)
end

return TableUtils
