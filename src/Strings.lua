local Strings = {}

--[[
	Splits a string into parts based on a delimiter and returns a table of the
	parts. The delimiter is a Lua string pattern, so special characters need
	escaping. See https://www.lua.org/manual/5.1/manual.html#5.4.1 for details
	on patterns.
]]
function Strings.split(str, delimiter) --: (string, string) => string
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

function Strings.trim(s) --: (string) => string
	return s:match "^%s*(.-)%s*$"
end

function Strings.startsWith(str, start) --: (string, string) => boolean
	return string.sub(str, 1, string.len(start)) == start
end

function Strings.endsWith(str, ending) --: (string, string) => boolean
	return string.sub(str, -string.len(ending)) == ending
end

function Strings.leftPad(string, length, character) --: (string, number, string) => string
	return string.rep(character or " ", length - #string) .. string
end

function Strings.rightPad(string, length, character) --: (string, number, string) => string
	return string .. string.rep(character or " ", length - #string)
end

return Strings
