local TableUtils = {}

function TableUtils.Slice(tbl, first, last, step) --: (table, number, number, number?) => table
	local sliced = {}

	for i = first or 1, last or #tbl, step or 1 do
		sliced[#sliced + 1] = tbl[i]
	end

	return sliced
end

function TableUtils.GetLength(T) --: (table) => number
	local count = 0
	for _ in pairs(T) do
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
	return {unpack(tbl)}
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
