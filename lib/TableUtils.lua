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

function TableUtils.Filter(source, handler) --: ((any[], (element: any, key: number) => boolean) => any[]) | ((table, (element: any, key: string) => boolean) => table)
	local result = {}
	for i, v in pairs(source) do
		if (handler(v, i)) then
			result[i] = v
		end
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

function TableUtils.Assign(target, ...) --: table, ...table => table
	local objects = {...}
	for _, source in pairs(objects) do
		for key, value in pairs(source) do
			target[key] = value
		end
	end
	return target
end

function TableUtils.Clone(tbl) --: (table) => table
	return {unpack(tbl)}
end

return TableUtils
