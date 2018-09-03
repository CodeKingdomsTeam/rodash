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

return TableUtils
