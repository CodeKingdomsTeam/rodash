local StringUtils = {}

function StringUtils.Split(str, delimiter) --: (string, string) => string
	local result = {}
	local from = 1
	if (not delimiter) then
		for i = 1, #str do
			table.insert(result, string.sub(str, i, i))
		end
		return result
	end
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

function StringUtils.LeftPad(string, length, character) --: (string, number, string) => string
	return string.rep(character or " ", length - #string) .. string
end

function StringUtils.RightPad(string, length, character) --: (string, number, string) => string
	return string .. string.rep(character or " ", length - #string)
end

return StringUtils
