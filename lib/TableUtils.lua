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

return TableUtils
