--[[
	Useful functions to manipulate strings, based on similar implementations in other standard libraries.
]]
local t = require(script.Parent.t)
local Strings = {}

--[[
	Convert `str` to camel-case.
	@example _.camelCase('Foo Bar') --> 'fooBar'
	@example _.camelCase('--foo-bar--') --> 'fooBar'
	@example _.camelCase('__FOO_BAR__') --> 'fooBar'
	@trait Chainable
]]
--: string -> string
function Strings.camelCase(str)
	assert(t.string(str))
	return str:gsub(
		"(%a)([%w]*)",
		function(head, tail)
			return head:upper() .. tail:lower()
		end
	):gsub("%A", ""):gsub("^%u", string.lower)
end

--[[
	Convert `str` to kebab-case, making all letters lowercase.
	@example _.kebabCase('fooBar') --> 'foo-bar'
	@example _.kebabCase(' Foo Bar ') --> 'foo-bar'
	@example _.kebabCase('__FOO_BAR__') --> 'foo-bar'
	@usage Chain with `:upper()` if you need an upper kebab-case string.
	@trait Chainable
]]
--: string -> string
function Strings.kebabCase(str)
	assert(t.string(str))
	return str:gsub(
		"(%l)(%u)",
		function(a, b)
			return a .. "-" .. b
		end
	):gsub("%A", "-"):gsub("^%-+", ""):gsub("%-+$", ""):lower()
end

--[[
	Convert `str` to kebab-case, making all letters uppercase.
	@example _.snakeCase('fooBar') --> 'FOO_BAR'
	@example _.snakeCase(' Foo Bar ') --> 'FOO_BAR'
	@example _.snakeCase('--foo-bar--') --> 'FOO_BAR'
	@usage Chain with `:lower()` if you need a lower snake-case string.
	@trait Chainable
]]
function Strings.snakeCase(str)
	assert(t.string(str))
	return str:gsub(
		"(%l)(%u)",
		function(a, b)
			return a .. "_" .. b
		end
	):gsub("%A", "_"):gsub("^_+", ""):gsub("_+$", ""):upper()
end

--[[
	Convert `str` to title-case, where the first letter of each word is capitalized.
	@example _.titleCase("hello world") --> "Hello World"
	@example _.titleCase("hello-there world_visitor") --> "Hello-there World_visitor"
	@example _.titleCase("hello world's end don’t panic") --> "Hello World's End Don’t Panic"
	@usage Dashes, underscores and apostraphes don't break words.
	@trait Chainable
]]
function Strings.titleCase(str)
	assert(t.string(str))
	return str:gsub(
		"(%a)([%w_%-'’]*)",
		function(head, tail)
			return head:upper() .. tail
		end
	)
end

--[[
	Capitalize the first letter of `str`.
	@example _.capitalize("hello world") --> "Hello world"
	@trait Chainable
]]
function Strings.capitalize(str)
	assert(t.string(str))
	return str:gsub("^%l", string.upper)
end

--[[
	Converts the characters `&<>"'` in `str` to their corresponding HTML entities.
	@example _.escape("<a>Fish & Chips</a>") --> "&lt;a&gt;Fish &amp; Chips&lt;/a&gt;"
	@trait Chainable
]]
function Strings.escape(str)
	assert(t.string(str))
	local entities = {["<"] = "lt", [">"] = "gt", ["&"] = "amp", ['""'] = "quot", ["'"] = "apos"}
	return str:gsub(
		".",
		function(char)
			return entities[char] and ("&" .. entities[char] .. ";") or char
		end
	)
end

--[==[
	The inverse of `_.escape`.
	Converts any escaped HTML entities in `str` to their corresponding characters.
	@example _.unescape("&#34;Hello&quot; &apos;World&#39;") --> [["Hello" 'World']]
	@trait Chainable
]==]
function Strings.unescape(str)
	assert(t.string(str))
	local entities = {lt = "<", gt = ">", amp = "&", quot = '"', apos = "'"}
	return str:gsub(
		"(&(#?x?)([%d%a]+);)",
		function(original, hashPrefix, code)
			return (hashPrefix == "" and entities[code]) or
				(hashPrefix == "#x" and tonumber(code, 16)) and string.char(tonumber(code, 16)) or
				(hashPrefix == "#" and tonumber(code)) and string.char(code) or
				original
		end
	)
end

--[[
	Splits `str` into parts based on a pattern delimiter and returns a table of the parts.
	@example _.split("nice") --> {"n", "i", "c", "e"}
	@example _.split("one, two,,  four", ",%s*") --> {"one", "two", "", "four"}
	@usage This method is useful only when you need a _pattern_ for delimiter. Use the Roblox native `string.split` if you a splitting on a simple string.
	@param delimiter (default = "")
	@trait Chainable
]]
--: string, pattern -> string[]
function Strings.splitByPattern(str, delimiter)
	assert(t.string(str))
	assert(t.optional(t.string)(delimiter))
	local result = {}
	local from = 1
	if (not delimiter) then
		for i = 1, #str do
			table.insert(result, str:sub(i, i))
		end
		return result
	end
	local delim_from, delim_to = str:find(delimiter, from)
	while delim_from do
		table.insert(result, str:sub(from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = str:find(delimiter, from)
	end
	table.insert(result, str:sub(from))
	return result
end

--[[
	Removes any spaces from the start and end of `str`.
	@example _.trim("  full moon  ") --> "full moon"
	@trait Chainable
]]
--: string -> string
function Strings.trim(str)
	assert(t.string(str))
	return str:match("^%s*(.-)%s*$")
end

--[[
	Checks if `str` starts with the string `start`.
	@example _.startsWith("Roblox Games", "Roblox") --> true
	@example _.startsWith("Minecraft Games", "Roblox") --> false
	@trait Chainable
]]
--: string, string -> bool
function Strings.startsWith(str, start)
	assert(t.string(str))
	return str:sub(1, start:len()) == start
end

--[[
	Checks if `str` ends with the string `ending`.
	@example _.endsWith("Roblox Games", "Games") --> true
	@example _.endsWith("Roblox Conference", "Games") --> false
	@trait Chainable
]]
--: string, string -> bool
function Strings.endsWith(str, ending)
	assert(t.string(str))
	assert(t.string(ending))
	return str:sub(-ending:len()) == ending
end

--[[
	Makes a string of `length` from `str` by repeating characters from `prefix` at the start of the string.
	@example _.leftPad("yes", 4) --> " yes"
	@example _.leftPad("2", 2, "0") --> "02"
	@example _.leftPad("hi", 10, ":-)") --> ":-):-):-hi"
	@param prefix (default = `" "`)
	@trait Chainable
]]
--: string, number, string -> string
function Strings.leftPad(str, length, prefix)
	assert(t.string(str))
	assert(t.number(length))
	assert(t.optional(t.string)(prefix))
	prefix = prefix or " "
	local padLength = length - #str
	local remainder = padLength % #prefix
	local repetitions = (padLength - remainder) / #prefix
	return string.rep(prefix or " ", repetitions) .. prefix:sub(1, remainder) .. str
end

--[[
	Makes a string of `length` from `str` by repeating characters from `suffix` at the end of the string.
	@example _.leftPad("yes", 4) --> "yes "
	@example _.leftPad("2", 2, "!") --> "2!"
	@example _.leftPad("hi", 10, ":-)") --> "hi:-):-):-"
	@param suffix (default = `" "`)
	@trait Chainable
]]
--: string, number, string -> string
function Strings.rightPad(str, length, suffix)
	assert(t.string(str))
	assert(t.number(length))
	assert(t.optional(t.string)(suffix))
	suffix = suffix or " "
	local padLength = length - #str
	local remainder = padLength % #suffix
	local repetitions = (padLength - remainder) / #suffix
	return str .. string.rep(suffix or " ", repetitions) .. suffix:sub(1, remainder)
end

return Strings
