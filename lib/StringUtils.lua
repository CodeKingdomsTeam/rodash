local StringUtils = {}

function StringUtils.Split(str, delimiter) --: ({string, number}) => string
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(str, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from)
	end
	table.insert(result, string.sub(str, from))
	return result
end

function StringUtils.Trim(s) --: (string) => string
	return s:match "^%s*(.-)%s*$"
end

return StringUtils
