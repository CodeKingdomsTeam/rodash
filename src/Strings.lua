--[[
	Useful functions to manipulate strings, based on similar implementations in other standard libraries.
]]
local t = require(script.Parent.Parent.t)
local Functions = require(script.Parent.Functions)
local Tables = require(script.Parent.Tables)
local Strings = {}
local insert = table.insert
local concat = table.concat

local function assertStrIsString(str)
	assert(t.string(str), "BadInput: str must be a string")
end

--[[
	Convert `str` to camel-case.
	@example dash.camelCase('Pepperoni Pizza') --> 'pepperoniPizza'
	@example dash.camelCase('--pepperoni-pizza--') --> 'pepperoniPizza'
	@example dash.camelCase('__PEPPERONI_PIZZA') --> 'pepperoniPizza'
	@trait Chainable
]]
--: string -> string
function Strings.camelCase(str)
	assertStrIsString(str)
	return str:gsub(
		"(%a)([%w]*)",
		function(head, tail)
			return head:upper() .. tail:lower()
		end
	):gsub("%A", ""):gsub("^%u", string.lower)
end

--[[
	Convert `str` to kebab-case, making all letters lowercase.
	@example dash.kebabCase('strongStilton') --> 'strong-stilton'
	@example dash.kebabCase(' Strong Stilton ') --> 'strong-stilton'
	@example dash.kebabCase('__STRONG_STILTON__') --> 'strong-stilton'
	@usage Chain with `:upper()` if you need an upper kebab-case string.
	@trait Chainable
]]
--: string -> string
function Strings.kebabCase(str)
	assertStrIsString(str)
	return str:gsub(
		"(%l)(%u)",
		function(a, b)
			return a .. "-" .. b
		end
	):gsub("%A", "-"):gsub("^%-+", ""):gsub("%-+$", ""):lower()
end

--[[
	Convert `str` to snake-case, making all letters uppercase.
	@example dash.snakeCase('sweetChickenCurry') --> 'SWEET_CHICKEN_CURRY'
	@example dash.snakeCase(' Sweet Chicken  Curry ') --> 'SWEET_CHICKEN__CURRY'
	@example dash.snakeCase('--sweet-chicken--curry--') --> 'SWEET_CHICKEN__CURRY'
	@usage Chain with `:lower()` if you need a lower snake-case string.
	@trait Chainable
]]
--: string -> string
function Strings.snakeCase(str)
	assertStrIsString(str)
	return str:gsub(
		"(%l)(%u)",
		function(a, b)
			return a .. "_" .. b
		end
	):gsub("%A", "_"):gsub("^_+", ""):gsub("_+$", ""):upper()
end

--[[
	Convert `str` to title-case, where the first letter of each word is capitalized.
	@example dash.titleCase("jello world") --> "Jello World"
	@example dash.titleCase("yellow-jello with_sprinkles") --> "Yellow-jello With_sprinkles"
	@example dash.titleCase("yellow jello's don’t mellow") --> "Yellow Jello's Dont’t Mellow"
	@usage Dashes, underscores and apostraphes don't break words.
	@trait Chainable
]]
--: string -> string
function Strings.titleCase(str)
	assertStrIsString(str)
	return str:gsub(
		"(%a)([%w_%-'’]*)",
		function(head, tail)
			return head:upper() .. tail
		end
	)
end

--[[
	Capitalize the first letter of `str`.
	@example dash.capitalize("hello mould") --> "Hello mould"
	@trait Chainable
]]
--: string -> string
function Strings.capitalize(str)
	assertStrIsString(str)
	return str:gsub("^%l", string.upper)
end

--[==[
	Converts the characters `&<>"'` in `str` to their corresponding HTML entities.
	@example dash.encodeHtml([[Pease < Bacon > "Fish" & 'Chips']]) --> "Peas &lt; Bacon &gt; &quot;Fish&quot; &amp; &apos;Chips&apos;"
	@trait Chainable
]==]
--: string -> string
function Strings.encodeHtml(str)
	assertStrIsString(str)
	local entities = {["<"] = "lt", [">"] = "gt", ["&"] = "amp", ['"'] = "quot", ["'"] = "apos"}
	local result =
		str:gsub(
		".",
		function(char)
			return entities[char] and ("&" .. entities[char] .. ";") or char
		end
	)
	return result
end

--[==[
	The inverse of `dash.encodeHtml`.
	Converts any HTML entities in `str` to their corresponding characters.
	@example dash.decodeHtml("&lt;b&gt;&#34;Smashed&quot;&lt;/b&gt; &apos;Avocado&#39; &#x1F60F;") --> [[<b>"Smashed"</b> 'Avocado' 😏]]
	@trait Chainable
]==]
--: string -> string
function Strings.decodeHtml(str)
	assertStrIsString(str)
	local entities = {lt = "<", gt = ">", amp = "&", quot = '"', apos = "'"}
	local result =
		str:gsub(
		"(&(#?x?)([%d%a]+);)",
		function(original, hashPrefix, code)
			return (hashPrefix == "" and entities[code]) or
				(hashPrefix == "#x" and tonumber(code, 16)) and utf8.char(tonumber(code, 16)) or
				(hashPrefix == "#" and tonumber(code)) and utf8.char(code) or
				original
		end
	)
	return result
end

--[[
	Splits `str` into parts based on a pattern delimiter and returns a table of the parts, followed
	by a table of the matched delimiters.
	@example dash.splitOn("rice") --> {"r", "i", "c", "e"}, {"", "", "", ""}
	@example dash.splitOn("one.two::flour", "[.:]") --> {"one", "two", "", "flour"}, {".", ":", ":"}
	@usage This method is useful only when you need a _pattern_ as a delimiter.
	@usage Use the Roblox native `string.split` if you are splitting on a simple string.
	@param delimiter (default = "")
	@trait Chainable
]]
--: string, pattern -> string[], string[]
function Strings.splitOn(str, pattern)
	assertStrIsString(str)
	assert(t.optional(t.string)(pattern), "BadInput: pattern must be a string or nil")
	local parts = {}
	local delimiters = {}
	local from = 1
	if not pattern then
		for i = 1, #str do
			insert(parts, str:sub(i, i))
		end
		return parts
	end
	local delimiterStart, delimiterEnd = str:find(pattern, from)
	while delimiterStart do
		insert(delimiters, str:sub(delimiterStart, delimiterEnd))
		insert(parts, str:sub(from, delimiterStart - 1))
		from = delimiterEnd + 1
		delimiterStart, delimiterEnd = str:find(pattern, from)
	end
	insert(parts, str:sub(from))
	return parts, delimiters
end

--[[
	Removes any spaces from the start and end of `str`.
	@example dash.trim("  roast veg  ") --> "roast veg"
	@trait Chainable
]]
--: string -> string
function Strings.trim(str)
	assertStrIsString(str)
	return str:match("^%s*(.-)%s*$")
end

--[[
	Checks if `str` starts with the string `start`.
	@example dash.startsWith("Fun Roblox Games", "Fun") --> true
	@example dash.startsWith("Chess", "Fun") --> false
	@trait Chainable
]]
--: string, string -> bool
function Strings.startsWith(str, prefix)
	assertStrIsString(str)
	assert(t.string(prefix), "BadInput: prefix must be a string")
	return str:sub(1, prefix:len()) == prefix
end

--[[
	Checks if `str` ends with the string `suffix`.
	@example dash.endsWith("Fun Roblox Games", "Games") --> true
	@example dash.endsWith("Bad Roblox Memes", "Games") --> false
	@trait Chainable
]]
--: string, string -> bool
function Strings.endsWith(str, suffix)
	assertStrIsString(str)
	assert(t.string(suffix), "BadInput: suffix must be a string")
	return str:sub(-suffix:len()) == suffix
end

--[[
	Makes a string of `length` from `str` by repeating characters from `prefix` at the start of the string.
	@example dash.leftPad("toast", 6) --> " toast"
	@example dash.leftPad("2", 2, "0") --> "02"
	@example dash.leftPad("toast", 10, ":)") --> ":):):toast"
	@param prefix (default = `" "`)
	@trait Chainable
]]
--: string, number, string -> string
function Strings.leftPad(str, length, prefix)
	assertStrIsString(str)
	assert(t.number(length), "BadInput: length must be a number")
	assert(t.optional(t.string)(prefix), "BadInput: prefix must be a string or nil")
	prefix = prefix or " "
	local padLength = length - #str
	local remainder = padLength % #prefix
	local repetitions = (padLength - remainder) / #prefix
	return string.rep(prefix or " ", repetitions) .. prefix:sub(1, remainder) .. str
end

--[[
	Makes a string of `length` from `str` by repeating characters from `suffix` at the end of the string.
	@example dash.rightPad("toast", 6) --> "toast "
	@example dash.rightPad("2", 2, "!") --> "2!"
	@example dash.rightPad("toast", 10, ":)") --> "toast:):):"
	@param suffix (default = `" "`)
	@trait Chainable
]]
--: string, number, string -> string
function Strings.rightPad(str, length, suffix)
	assertStrIsString(str)
	assert(t.number(length), "BadInput: length must be a number")
	assert(t.optional(t.string)(suffix), "BadInput: suffix must be a string or nil")
	suffix = suffix or " "
	local padLength = length - #str
	local remainder = padLength % #suffix
	local repetitions = (padLength - remainder) / #suffix
	return str .. string.rep(suffix or " ", repetitions) .. suffix:sub(1, remainder)
end

--[[
	This function first calls `dash.format` on the arguments provided and then outputs the response
	to the debug target, set using `dash.setDebug`. By default, this function does nothing, allowing
	developers to leave the calls in the source code if that is beneficial.
	@param format the format match string
	@example
		-- During development:
		dash.setDebug()
		-- At any point in the code:
		dash.debug("Hello {}", game.Players.LocalPlayer)
		-->> Hello builderman (for example)
	@usage A common pattern would be to `dash.setDebug()` to alias to `print` during local development,
		and send debug messages to an HTTP server on a production build to allow remote debugging.
	@see `dash.setDebug`
]]
--: string, ... -> string
function Strings.debug(format, ...)
	if Strings.debugTarget == nil then
		return
	end
	Strings.debugTarget(Strings.format(format, ...))
end

--[[
	Hooks up any debug methods to invoke _fn_. By default, `dash.debug` does nothing.
	@param fn (default = `print`)
	@usage Calling `dash.setDebug()` will simply print all calls to `dash.debug` with formatted arguments.
	@example
		local postMessage = dash.async(function(message)
			HttpService.PostAsync("https://example.com/log", message)
		end
		-- During production:
		dash.setDebug(postMessage)
		-- At any point in the code:
		dash.debug("Hello is printed")
		-- "Hello is printed" is posted to the server
	@see `dash.debug`
	@see `dash.async`
]]
--: <A>(...A -> ())
function Strings.setDebug(fn)
	Strings.debugTarget = fn
end

--[[
	Converts _char_ into a hex representation
	@param format (optional) a string passed to `dash.format` which formats the hex value of each of the character's code points.
	@param useBytes (default = false) whether to use the character's bytes, rather than UTF-8 code points.
	@example dash.charToHex("<") --> "3C"
	@example dash.charToHex("<", "&#{};") --> "&#3C;"
	@example dash.charToHex("😏") --> "1F60F"
	@example dash.charToHex("😏", "0x{}") --> "0x1F60F"
	@example dash.charToHex("🤷🏼‍♀️", "&#x{};") --> "&#x1F937;&#x1F3FC;&#x200D;&#x2640;&#xFE0F;"
	@example dash.charToHex("🤷🏼‍♀️", "%{}", true) --> "%F0%9F%A4%B7%F0%9F%8F%BC%E2%80%8D%E2%99%80%EF%B8%8F"
]]
--: char, string?, boolean? -> string
function Strings.charToHex(char, format, useBytes)
	assert(t.string(char), "BadInput: char must be a single utf8 character string")
	local values = {}
	if useBytes then
		for i = 1, char:len() do
			insert(values, char:byte(i))
		end
	else
		for position, codePoint in utf8.codes(char) do
			insert(values, codePoint)
		end
	end
	return concat(
		Tables.map(
			values,
			function(value)
				local hexValue = string.format("%X", value)
				return format and Strings.format(format, hexValue) or hexValue
			end,
			""
		)
	)
end

--[[
	Generates a character from its _hex_ representation.
	@example dash.hexToChar("1F60F") --> "😏"
	@example dash.hexToChar("%1F60F") --> "😏"
	@example dash.hexToChar("#1F60F") --> "😏"
	@example dash.hexToChar("0x1F60F") --> "😏"
	@throws _MalformedInput_ if _char_ is not a valid encoding.
]]
--: str -> char
function Strings.hexToChar(hex)
	assert(t.string(hex), "BadInput: hex must be a string")
	if hex:sub(0, 1) == "%" or hex:sub(0, 1) == "#" then
		hex = hex:sub(2)
	elseif hex:sub(0, 2) == "0x" then
		hex = hex:sub(3)
	end
	return utf8.char(tonumber(hex, 16)) or error("MalformedInput")
end

--[[
	Encodes _str_ for use as a URL, for example when calling an HTTP endpoint.

	Note that, unlike this function, `HttpService.EncodeUrl` actually attempts to encode a string
	for purposes as a URL component rather than an entire URL, and as such will not produce a valid
	URL.

	@trait Chainable
	@example
		dash.encodeUrl("https://example.com/Egg+Fried Rice!?🤷🏼‍♀️")
		--> "https://example.com/Egg+Fried%20Rice!?%F0%9F%A4%B7%F0%9F%8F%BC%E2%80%8D%E2%99%80%EF%B8%8F"
	@usage
		This method is designed to act like `encodeURI` in JavaScript.
	@see `dash.encodeUrlComponent`
]]
--: string -> string
function Strings.encodeUrl(str)
	assertStrIsString(str)
	local result = {}
	for _, codePoint in utf8.codes(str) do
		local char = utf8.char(codePoint)
		if char:match("^[%;%,%/%?%:%@%&%=%+%$%w%-%_%.%!%~%*%'%(%)%#]$") then
			table.insert(result, char)
		else
			table.insert(result, Strings.charToHex(char, "%{}", true))
		end
	end
	return table.concat(result, "")
end

--[[
	Encodes _str_ for use in a URL, for example as a query parameter of a call to an HTTP endpoint.
	@trait Chainable
	@example
		dash.encodeUrlComponent("https://example.com/Egg+Fried Rice!?🤷🏼‍♀️")
		--> "https%3A%2F%2Fexample.com%2FEgg%2BFried%20Rice!%3F%F0%9F%A4%B7%F0%9F%8F%BC%E2%80%8D%E2%99%80%EF%B8%8F"
	@usage
		This method is designed to act like `encodeURIComponent` in JavaScript.
	@usage
		This is very similar to `HttpService.EncodeUrl`, but is included for parity and conforms closer to the standard (e.g. EncodeUrl unnecessarily encodes `!`).
]]
--: string -> string
function Strings.encodeUrlComponent(str)
	assertStrIsString(str)
	local result = {}
	for _, codePoint in utf8.codes(str) do
		local char = utf8.char(codePoint)
		if char:match("^[%;%,%/%?%:%@%&%=%+%$%w%-%_%.%!%~%*%'%(%)%#]$") then
			table.insert(result, char)
		else
			table.insert(result, Strings.charToHex(char, "%{}", true))
		end
	end
	return table.concat(result, "")
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
	The inverse of `dash.encodeUrl`. Use this to turn a URL which has been encoded for use in a
	HTTP request back into its original form.
	@trait Chainable
	@example
		dash.decodeUrl("https://Egg+Fried%20Rice!?")
		--> "https://Egg+Fried Rice!?"
	@usage
		This method is designed to act like `decodeURI` in JavaScript.
]]
--: string -> string
function Strings.decodeUrl(str)
	assertStrIsString(str)
	local exceptions = calculateDecodeUrlExceptions()
	return str:gsub(
		"%%(%x%x)",
		function(term)
			local charId = tonumber(term, 16)
			if not exceptions[charId] then
				return utf8.char(charId)
			end
		end
	)
end

--[[
	The inverse of `dash.encodeUrlComponent`. Use this to turn a string which has been encoded for
	use as a component of a url back into its original form.
	@trait Chainable
	@example
		dash.decodeUrlComponent("https%3A%2F%2FEgg%2BFried%20Rice!%3F")
		--> "https://Egg+Fried Rice!?"
	@usage This method is designed to act like `decodeURIComponent` in JavaScript.
	@throws _MalformedInput_ if _str_ contains characters encoded incorrectly.
]]
--: string -> string
function Strings.decodeUrlComponent(str)
	assertStrIsString(str)
	return str:gsub("%%(%x%x)", Strings.hexToChar)
end

--[[
	Takes a _query_ dictionary of key-value pairs and builds a query string that can be concatenated
	to the end of a url.
	
	@example
		dash.encodeQueryString({
			time = 11,
			biscuits = "hob nobs",
			chocolatey = true
		})) --> "?biscuits=hob+nobs&time=11&chocolatey=true"

	@usage A query string which contains duplicate keys with different values is technically valid, but this function doesn't provide a way to produce them.
]]
--: <K,V>(Iterable<K,V> -> string)
function Strings.encodeQueryString(query)
	assert(t.table(query), "BadInput: query must be a table")
	local fields =
		Tables.mapValues(
		query,
		function(value, key)
			return Strings.encodeUrlComponent(tostring(key)) .. "=" .. Strings.encodeUrlComponent(tostring(value))
		end
	)
	return ("?" .. concat(fields, "&"))
end

--[[
	Returns the _format_ string with placeholders `{...}` substituted with readable representations
	of the subsequent arguments.

	This function is a simpler & more powerful version of `string.format`, inspired by `format!`
	in Rust.
	
	* `{}` formats and prints the next argument using `:format()` if available, or a suitable
		default representation depending on its type.
	* `{2}` formats and prints the 2nd argument.
	* `{#2}` prints the length of the 2nd argument.

	Display parameters can be combined after a `:` in the curly braces. Any format parameters used
	in `string.format` can be used here, along with these extras:

	* `{:?}` formats any value using `dash.serializeDeep`.
	* `{:#?}` formats any value using `dash.pretty`.
	* `{:b}` formats a number in its binary representation.
	@example
		local props = {"teeth", "claws", "whiskers", "tail"}
		dash.format("{:?} is in {:#?}", "whiskers", props)
		-> '"whiskers" is in {"teeth", "claws", "whiskers", "tail"}'
	@example
		dash.format("{} in binary is {1:b}", 125) -> "125 in binary is 110100"
	@example
		dash.format("The time is {:02}:{:02}", 2, 4) -> "The time is 02:04"
	@example
		dash.format("The color blue is #{:06X}", 255) -> "The color blue is #0000FF"
	@usage Escape `{` with `{{` and `}` similarly with `}}`.
	@usage See [https://developer.roblox.com/articles/Format-String](https://developer.roblox.com/articles/Format-String)
		for complete list of formating options and further use cases.
	@see `dash.serializeDeep`
	@see `dash.pretty`
]]
--: string, ... -> string
function Strings.format(format, ...)
	local args = {...}
	local argIndex = 1
	local texts, subs = Strings.splitOn(format, "{[^{}]*}")
	local result = {}
	for i, text in pairs(texts) do
		local unescaped = text:gsub("{{", "{"):gsub("}}", "}")
		insert(result, unescaped)
		local placeholder = subs[i] and subs[i]:sub(2, -2)
		if placeholder then
			local escapeMatch = text:gmatch("{+$")()
			local isEscaped = escapeMatch and #escapeMatch % 2 == 1
			if not isEscaped then
				local placeholderSplit = Strings.splitOn(placeholder, ":")
				local isLength = Strings.startsWith(placeholderSplit[1], "#")
				local argString = isLength and placeholderSplit[1]:sub(2) or placeholderSplit[1]
				local nextIndex = tonumber(argString)
				local displayString = placeholderSplit[2]
				local arg
				if nextIndex then
					arg = args[nextIndex]
				else
					arg = args[argIndex]
					argIndex = argIndex + 1
				end
				if isLength then
					arg = #arg
				end
				insert(result, Strings.formatValue(arg, displayString or ""))
			else
				local unescapedSub = placeholder
				insert(result, unescapedSub)
			end
		end
	end
	return table.concat(result, "")
end

local function decimalToBinary(number)
	local binaryEight = {
		["1"] = "000",
		["2"] = "001",
		["3"] = "010",
		["4"] = "011",
		["5"] = "100",
		["6"] = "101",
		["7"] = "110",
		["8"] = "111"
	}
	return string.format("%o", number):gsub(
		".",
		function(char)
			return binaryEight[char]
		end
	):gsub("^0+", "")
end

--[[
	Format a specific _value_ using the specified _displayString_.
	@example
		dash.formatValue(255, ":06X") --> 0000FF
	@see `dash.format` - for a full description of valid display strings.
]]
--: any, DisplayString -> string
function Strings.formatValue(value, displayString)
	local displayTypeStart, displayTypeEnd = displayString:find("[A-Za-z#?]+")
	if displayTypeStart then
		local displayType = displayString:sub(displayTypeStart, displayTypeEnd)
		local formatAsString =
			"%" .. displayString:sub(1, displayTypeStart - 1) .. displayString:sub(displayTypeEnd + 1) .. "s"
		if displayType == "#?" then
			return string.format(formatAsString, Strings.pretty(value))
		elseif displayType == "?" then
			return string.format(formatAsString, Tables.serializeDeep(value))
		elseif displayType == "#b" then
			local result = decimalToBinary(value)
			return string.format(formatAsString, "0b" .. result)
		elseif displayType == "b" then
			local result = decimalToBinary(value)
			return string.format(formatAsString, result)
		end
		return string.format("%" .. displayString, value)
	else
		local displayType = "s"
		if type(value) == "number" then
			local _, fraction = math.modf(value)
			displayType = fraction == 0 and "d" or "f"
		end
		return string.format("%" .. displayString .. displayType, tostring(value))
	end
end

--[[
	Returns a human-readable string for the given _value_. The string will be formatted across
	multiple lines if a descendant element gets longer than `80` characters.

	Optionally a table of [SerializeOptions](/rodash/types#SerializeOptions) can be passed which will pass
	to the underlying `dash.serialize` function so you can customise what is displayed.

	@example
		local fox = {
			name = "Mr. Fox",
			color = "red"
		}
		print(dash.pretty(fox))
		-->> {color = "red", name = "Mr. Fox"}
	@example
		local fox = {
			name = "Mr. Fox",
			color = "red"
		}
		print(dash.pretty(fox, {omitKeys = {"name"}}))
		-->> {color = "red"}

	@see `dash.serializeDeep` for a compact alternative.
]]
--: <T>(T, SerializeOptions<T>? -> string)
function Strings.pretty(value, serializeOptions)
	local function serializeValue(value, options)
		if type(value) == "table" then
			local className = ""
			if value.Class then
				className = value.Class.name .. " "
			end
			return className .. Tables.serialize(value, options)
		else
			return Tables.defaultSerializer(value, options)
		end
	end

	local MAX_LINE = 80

	return Tables.serialize(
		value,
		Tables.assign(
			{
				serializeValue = serializeValue,
				serializeKey = function(key, options)
					if type(key) == "string" then
						return key
					else
						return "[" .. serializeValue(key, options) .. "]"
					end
				end,
				serializeElement = function(key, value)
					local shortString = key .. " = " .. value
					if #shortString < MAX_LINE or shortString:match("\n") then
						return shortString
					end
					return key .. " =\n\t" .. value
				end or nil,
				serializeTable = function(contents, ref, options)
					local shortString = ref .. "{" .. table.concat(contents, ", ") .. "}"
					if #shortString < MAX_LINE then
						return shortString
					end
					return ref ..
						"{\n" ..
							table.concat(
								Tables.map(
									contents,
									function(element)
										return "\t" .. element:gsub("\n", "\n\t")
									end
								),
								",\n"
							) ..
								"\n}"
				end or nil,
				keyDelimiter = " = ",
				valueDelimiter = ", ",
				omitKeys = {"Class"}
			},
			serializeOptions or {}
		)
	)
end

return Strings
