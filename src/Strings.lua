--[[
	Useful functions to manipulate strings, based on similar implementations in other standard libraries.
]]
local t = require(script.Parent.t)
local Functions = require(script.Functions)
local Tables = require(script.Tables)
local Strings = {}

--[[
	Convert `str` to camel-case.
	@example _.camelCase('Pepperoni Pizza') --> 'pepperoniPizza'
	@example _.camelCase('--pepperoni-pizza--') --> 'pepperoniPizza'
	@example _.camelCase('__PEPPERONI_PIZZA') --> 'pepperoniPizza'
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
	@example _.kebabCase('strongStilton') --> 'strong-stilton'
	@example _.kebabCase(' Strong Stilton ') --> 'strong-stilton'
	@example _.kebabCase('__STRONG_STILTON__') --> 'strong-stilton'
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
	Convert `str` to snake-case, making all letters uppercase.
	@example _.snakeCase('sweetChickenCurry') --> 'SWEET_CHICKEN_CURRY'
	@example _.snakeCase(' Sweet Chicken  Curry ') --> 'SWEET_CHICKEN__CURRY'
	@example _.snakeCase('--sweet-chicken--curry--') --> 'SWEET_CHICKEN__CURRY'
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
	@example _.titleCase("jello world") --> "Jello World"
	@example _.titleCase("yellow-jello with_sprinkles") --> "Yellow-jello With_sprinkles"
	@example _.titleCase("yellow jello's don’t mellow") --> "Yellow Jello's Dont’t Mellow"
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
	@example _.capitalize("hello mould") --> "Hello mould"
	@trait Chainable
]]
function Strings.capitalize(str)
	assert(t.string(str))
	return str:gsub("^%l", string.upper)
end

--[[
	Converts the characters `&<>"'` in `str` to their corresponding HTML entities.
	@example _.encodeHtml("<a>Fish & Chips</a>") --> "&lt;a&gt;Fish &amp; Chips&lt;/a&gt;"
	@trait Chainable
]]
function Strings.encodeHtml(str)
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
	The inverse of `_.encodeHtml`.
	Converts any encodeHtmld HTML entities in `str` to their corresponding characters.
	@example _.decodeHtml("&#34;Smashed&quot; &apos;Avocado&#39;") --> [["Smashed" 'Avocado']]
	@trait Chainable
]==]
function Strings.decodeHtml(str)
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
	@example _.splitByPattern("rice") --> {"r", "i", "c", "e"}
	@example _.splitByPattern("one.two::flour", "[.:]") --> {"one", "two", "", "flour"}
	@usage This method is useful only when you need a _pattern_ as a delimiter.
	@usage Use the Roblox native `string.split` if you are splitting on a simple string.
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
	@example _.trim("  roast veg  ") --> "roast veg"
	@trait Chainable
]]
--: string -> string
function Strings.trim(str)
	assert(t.string(str))
	return str:match("^%s*(.-)%s*$")
end

--[[
	Checks if `str` starts with the string `prefix`.
	@example _.startsWith("Fun Roblox Games", "Fun") --> true
	@example _.startsWith("Minecraft Games", "Fun") --> false
	@trait Chainable
]]
--: string, string -> bool
function Strings.startsWith(str, prefix)
	assert(t.string(str))
	return str:sub(1, prefix:len()) == prefix
end

--[[
	Checks if `str` ends with the string `suffix`.
	@example _.endsWith("Fun Roblox Games", "Games") --> true
	@example _.endsWith("Bad Roblox Memes", "Games") --> false
	@trait Chainable
]]
--: string, string -> bool
function Strings.endsWith(str, suffix)
	assert(t.string(str))
	assert(t.string(suffix))
	return str:sub(-suffix:len()) == suffix
end

--[[
	Makes a string of `length` from `str` by repeating characters from `prefix` at the start of the string.
	@example _.leftPad("toast", 6) --> " toast"
	@example _.leftPad("2", 2, "0") --> "02"
	@example _.leftPad("toast", 10, ":)") --> ":):):toast"
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
	@example _.leftPad("toast", 6) --> "toast "
	@example _.leftPad("2", 2, "!") --> "2!"
	@example _.leftPad("toast", 10, ":)") --> "toast:):):"
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

--[[
	This function is a simpler & more powerful version of `string.format`, inspired by `format!` in Rust.
	If an instance has a `:format()` method, this is used instead, passing the format arguments.
	
		* `{}` prints the next variable using or `tostring`.
		* `{:?}` prints using `_.serializeDeep`.
		* `{:#?}` prints using `_.pretty`.

	@param subject the format match string
]]
function Strings.format(subject, ...)
	-- TODO
end

local debugTarget

--[[
	This function first calls `_.format` on the arguments provided and then outputs the response
	to the debug target, set using `_.setDebug`. By default, this function does nothing, allowing
	developers to leave the calls in the source code if that is beneficial.
	@param subject the format match string
	@usage A common pattern would be to `_.setDebug()` to alias to `print` during local development,
		and call e.g. `_.setDebug(_.bind(HttpService.PostAsync, "https://example.com/log"))`
		on a production build to allow remote debugging.
]]
function Strings.debug(subject, ...)
	if debugTarget == nil then
		return
	end
	debugTarget(Strings.format(...))
end

--[[
	Hooks up any debug methods to invoke _fn_, which by default does nothing.
	@param fn (default = `print`)
]]
function Strings.setDebug(fn)
	debugTarget = fn
end

--[[
	Converts _char_ into its hex representation
	@example _.charToHex("_") --> %5F
]]
--: char -> str
function Strings.charToHex(char)
	assert(t.string(char))
	return string.format("%%%02X", char:byte(1, 1))
end

--[[
	Converts _char_ into its hex representation
	@example
		_.charToHex("%5F") --> "_"
		_.charToHex("5F") --> "_"
]]
--: str -> char
function Strings.hexToChar(char)
	assert(t.string(char))
	return string.char(tonumber(char:sub(-2), 16))
end

--[[
	Encodes _str_ for use as a url, for example as an entire url.
	@trait chainable
	@example
		_.encodeUrl("https://Egg+Fried Rice!?")
		--> "https://Egg+Fried%20Rice!?"
]]
function Strings.encodeUrl(str)
	assert(t.string(str))
	return str:gsub("[^%;%,%/%?%:%@%&%=%+%$%w%-%_%.%!%~%*%'%(%)%#]", Strings.charToHex)
end

--[[
	Encodes _str_ for use in a url, for example as a query parameter of a url.
	@trait chainable
	@example
		_.encodeUrlComponent("https://Egg+Fried Rice!?")
		--> "https%3A%2F%2FEgg%2BFried%20Rice!%3F"
]]
function Strings.encodeUrlComponent(str)
	assert(t.string(str))
	return str:gsub("[^%w%-_%.%!%~%*%'%(%)]", Strings.charToHex)
end

local calculateDecodeUrlExceptions =
	Functions.once(
	function()
		local exceptions = {}
		for char in ("#$&+,/:;=?@"):gmatch(".") do
			exceptions[string.byte(char)] = true
		end
		return exceptions
	end
)

--[[
	The inverse of `_.encodeUrl`
	@trait chainable
	@example
		_.decodeUrl("https://Egg+Fried%20Rice!?")
		--> "https://Egg+Fried Rice!?"
]]
function Strings.decodeUrl(str)
	assert(t.string(str))
	local exceptions = calculateDecodeUrlExceptions()
	return str:gsub(
		"%%(%x%x)",
		function(term)
			local charId = tonumber(term, 16)
			if not exceptions[charId] then
				return string.char(charId)
			end
		end
	)
end

--[[
	The inverse of `_.encodeUrlComponent`
	@trait chainable
	@example
		_.decodeUrlComponent("https%3A%2F%2FEgg%2BFried%20Rice!%3F")
		--> "https://Egg+Fried Rice!?"
]]
function Strings.decodeUrlComponent(str)
	assert(t.string(str))
	return str:gsub("%%(%x%x)", Strings.hexToChar)
end

--[[
	Takes a _query_ dictionary of key-value pairs and build a query string that can be concatenated
	to the end of a url.
	@example
		Strings.encodeQueryString({
			time = 11,
			biscuits = "hob nobs",
			chocolatey = true
		})) --> "?biscuits=hob+nobs&time=11&chocolatey=true"
]]
function Strings.encodeQueryString(query)
	assert(t.table(query))
	local fields =
		Tables.mapValues(
		query,
		function(value, key)
			return key .. "=" .. Strings.encodeUrlComponent(tostring(value))
		end
	)
	return ("?" .. table.concat(fields, "&"))
end

return Strings
