local StringUtils = {}

function StringUtils.Split(str, delimiter) --: (string, number) => string
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

function StringUtils.StartsWith(str, start) --: (string, string) => boolean
	return string.sub(str, 1, string.len(start)) == start
end

function StringUtils.EndsWith(str, ending) --: (string, string) => boolean
	return string.sub(str, -string.len(ending)) == ending
end

return StringUtils
