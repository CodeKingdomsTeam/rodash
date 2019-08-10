--[[
	Useful functions to manipulate strings, based on similar implementations in other standard libraries.
]]
local t = require(script.Parent.t)
local Functions = require(script.Functions)
local Tables = require(script.Tables)
local Strings = {}
local insert = table.insert
local concat = table.concat

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

--[==[
	Converts the characters `&<>"'` in `str` to their corresponding HTML entities.
	@example _.encodeHtml([[Pease < Bacon > "Fish" & 'Chips']]) --> "Peas &lt; Bacon &gt; &quot;Fish&quot; &amp; &apos;Chips&apos;"
	@trait Chainable
]==]
function Strings.encodeHtml(str)
	assert(t.string(str))
	local entities = {["<"] = "lt", [">"] = "gt", ["&"] = "amp", ['"'] = "quot", ["'"] = "apos"}
	return str:gsub(
		".",
		function(char)
			return entities[char] and ("&" .. entities[char] .. ";") or char
		end
	)
end

--[==[
	The inverse of `_.encodeHtml`.
	Converts any HTML entities in `str` to their corresponding characters.
	@example _.decodeHtml("&lt;b&gt;&#34;Smashed&quot;&lt;/b&gt; &apos;Avocado&#39; &#x1F60F;") --> [[<b>"Smashed"</b> 'Avocado' 😏]]
	@trait Chainable
]==]
function Strings.decodeHtml(str)
	assert(t.string(str))
	local entities = {lt = "<", gt = ">", amp = "&", quot = '"', apos = "'"}
	return str:gsub(
		"(&(#?x?)([%d%a]+);)",
		function(original, hashPrefix, code)
			return (hashPrefix == "" and entities[code]) or
				(hashPrefix == "#x" and tonumber(code, 16)) and utf8.char(tonumber(code, 16)) or
				(hashPrefix == "#" and tonumber(code)) and utf8.char(code) or
				original
		end
	)
end

--[[
	Splits `str` into parts based on a pattern delimiter and returns a table of the parts, followed
	by a table of the matched delimiters.
	@example _.splitOn("rice") --> {"r", "i", "c", "e"}, {"", "", "", ""}
	@example _.splitOn("one.two::flour", "[.:]") --> {"one", "two", "", "flour"}, {".", ":", ":"}
	@usage This method is useful only when you need a _pattern_ as a delimiter.
	@usage Use the Roblox native `string.split` if you are splitting on a simple string.
	@param delimiter (default = "")
	@trait Chainable
]]
--: string, pattern -> string[], string[]
function Strings.splitOn(str, pattern)
	assert(t.string(str))
	assert(t.optional(t.string)(pattern))
	local result = {}
	local delimiters = {}
	local from = 1
	if not pattern then
		for i = 1, #str do
			insert(result, str:sub(i, i))
		end
		return result
	end
	local delimiterStart, delimiterEnd = str:find(pattern, from)
	while delimiterStart do
		insert(delimiters, str:sub(delimiterStart, delimiterEnd))
		insert(result, str:sub(from, delimiterStart - 1))
		from = delimiterEnd + 1
		delimiterStart, delimiterEnd = str:find(pattern, from)
	end
	insert(result, str:sub(from))
	return result, delimiters
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
	Checks if `str` starts with the string `start`.
	@example _.startsWith("Fun Roblox Games", "Fun") --> true
	@example _.startsWith("Chess", "Fun") --> false
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
	This function first calls `_.format` on the arguments provided and then outputs the response
	to the debug target, set using `_.setDebug`. By default, this function does nothing, allowing
	developers to leave the calls in the source code if that is beneficial.
	@param subject the format match string
	@usage A common pattern would be to `_.setDebug()` to alias to `print` during local development,
		and call e.g. `_.setDebug(_.bind(HttpService.PostAsync, "https://example.com/log"))`
		on a production build to allow remote debugging.
]]
function Strings.debug(subject, ...)
	if Strings.debugTarget == nil then
		return
	end
	Strings.debugTarget(Strings.format(...))
end

--[[
	Hooks up any debug methods to invoke _fn_. By default, `_.debug` does nothing.
	@param fn (default = `print`)
	@usage Calling `_.setDebug()` will simply print all calls to `_.debug` with formatted arguments.
]]
function Strings.setDebug(fn)
	Strings.debugTarget = fn
end

--[[
	Converts _char_ into a hex representation
	@param format (optional) a string passed to `_.format` which formats the hex value of each of the character's code points.
	@param useBytes (default = false) whether to use the character's bytes, rather than UTF-8 code points.
	@example _.charToHex("<") --> "3C"
	@example _.charToHex("<", "&#{};") --> "&#3C;"
	@example _.charToHex("😏") --> "1F60F"
	@example _.charToHex("😏", "0x{}") --> "0x1F60F"
	@example _.charToHex("🤷🏼‍♀️", "&#x{};") --> "&#x1F937;&#x1F3FC;&#x200D;&#x2640;&#xFE0F;"
	@example _.charToHex("🤷🏼‍♀️", "%{}", true) --> "%F0%9F%A4%B7%F0%9F%8F%BC%E2%80%8D%E2%99%80%EF%B8%8F"
]]
--: char -> str, str?, boolean?
function Strings.charToHex(char, format, useBytes)
	assert(t.string(char))
	assert(utf8.len(char) == 1)
	local values = {}
	if useBytes then
		for position, codePoint in utf8.codes(char) do
			insert(values, codePoint)
		end
	else
		for i = 1, char:len() do
			insert(values, char:byte(i))
		end
	end
	return concat(
		Tables.map(
			values,
			function(value)
				return format and Strings.format(format, string.format("%X", value))
			end,
			""
		)
	)
end

--[[
	Converts a _hex_ represntation of a character in the character.
	@example _.hexToChar("1F60F") --> "😏"
	@example _.hexToChar("%1F60F") --> "😏"
	@example _.hexToChar("#1F60F") --> "😏"
	@example _.hexToChar("0x1F60F") --> "😏"
	@throws _MalformedInput_ if _char_ is not a valid encoding.
]]
--: str -> char
function Strings.hexToChar(hex)
	assert(t.string(hex))
	if hex:sub(0, 1) == "%" or hex:sub(0, 1) == "#" then
		hex = hex:sub(1)
	elseif hex:sub(0, 2) == "0x" then
		hex = hex:sub(2)
	end
	return utf8.char(tonumber(hex, 16)) or error("MalformedInput")
end

--[[
	Encodes _str_ for use as a URL, for example as an entire URL.
	@trait Chainable
	@example
		_.encodeUrl("https://example.com/Egg+Fried Rice!?🤷🏼‍♀️")
		--> "https://example.com/Egg+Fried%20Rice!?%1F937%1F3FC%200D%2640%FE0F"
	@usage
		This method is designed to act like `encodeURI` in JavaScript.
]]
--: string -> string
function Strings.encodeUrl(str)
	assert(t.string(str))
	return str:gsub("[^%;%,%/%?%:%@%&%=%+%$%w%-%_%.%!%~%*%'%(%)%#]", Functions.bindTail(Strings.charToHex, "%{}", true))
end

--[[
	Encodes _str_ for use in a URL, for example as a query parameter of a URL.
	@trait Chainable
	@example
		_.encodeUrlComponent("https://example.com/Egg+Fried Rice!?🤷🏼‍♀️")
		--> "https%3A%2F%2Fexample.com%2FEgg%2BFried%20Rice!%3F%1F937%1F3FC%200D%2640%FE0F"
	@usage
		This method is designed to act like `encodeURIComponent` in JavaScript.
	@usage
		This is very similar to `HttpService.EncodeUrl`, but is included for parity and conforms closer to the standard (e.g. EncodeUrl unnecessarily encodes `!`).
]]
--: string -> string
function Strings.encodeUrlComponent(str)
	assert(t.string(str))
	return str:gsub("[^%w%-_%.%!%~%*%'%(%)]", Functions.bindTail(Strings.charToHex, "%{}", true))
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
	The inverse of `_.encodeUrl`.
	@trait Chainable
	@example
		_.decodeUrl("https://Egg+Fried%20Rice!?")
		--> "https://Egg+Fried Rice!?"
	@usage
		This method is designed to act like `decodeURI` in JavaScript.
]]
--: string -> string
function Strings.decodeUrl(str)
	assert(t.string(str))
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
	The inverse of `_.encodeUrlComponent`.
	@trait Chainable
	@example
		_.decodeUrlComponent("https%3A%2F%2FEgg%2BFried%20Rice!%3F")
		--> "https://Egg+Fried Rice!?"
	@usage This method is designed to act like `decodeURIComponent` in JavaScript.
	@throws _MalformedInput_ if _str_ contains characters encoded incorrectly.
]]
--: string -> string
function Strings.decodeUrlComponent(str)
	assert(t.string(str))
	return str:gsub("%%(%x%x)", Strings.hexToChar)
end

--[[
	Takes a _query_ dictionary of key-value pairs and builds a query string that can be concatenated
	to the end of a url.
	
	@example
		_.encodeQueryString({
			time = 11,
			biscuits = "hob nobs",
			chocolatey = true
		})) --> "?biscuits=hob+nobs&time=11&chocolatey=true"

	@usage A query string which contains duplicate keys with different values is technically valid, but this function doesn't provide a way to produce them.
]]
--: <K,V>(Iterable<K,V> -> string)
function Strings.encodeQueryString(query)
	assert(t.table(query))
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

	This function is a simpler & more powerful version of `string.format`, inspired by `format!` in Rust.
	
	* `{}` formats and prints the next argument using `:format()` if available, or `tostring`.
	* `{2}` formats and prints the 2nd value argument

	Display parameters can be combined after a `:` in the curly braces:

	#### Serialization

	* `{:?}` formats using `_.serializeDeep`.
	* `{:#?}` formats using multiline `_.pretty`.

	#### Alignment

	* `{:8}` left-pads the result with spaces so that it takes up at least 8 characters.
	* `{:08}` left-pads the result with `0` so that it takes up at least 8 characters.
	* `{:>8}` right-pads the result with spaces so that it takes up at least 8 characters.
	* `{:>08}` right-pads the result with `0` so that it takes up at least 8 characters.

	#### Numbers

	* `{:.3}` displays a number with 3 digits of precision after the decimal point.
	* `{:e}` or `{:E}` prints a number with scientific notation.
	* `{:x}` or `{:X}` prints a number as a lower or upper-case hex value. Use `#x` or `#X` to prefix with `0x`.
	* `{:b}` prints a number in binary format. Use `#b` to prefix with `0b`.
	* `{:o}` prints a number in octal format. Use `#o` to prefix with `0o`.
]]
--: string, ...any -> string
function Strings.format(format, ...)
	local args = {...}
	local argIndex = 1
	local texts, subs = Strings.splitOn(format, "%{[:0-9#?beox>]*%}")
	local result = {}
	for i, text in pairs(texts) do
		local unescaped = text:gsub("{{", "{"):gsub("}}", "}")
		insert(result, unescaped)
		local placeholder = subs[i] and subs[i]:sub(2, -2)
		if placeholder then
			local escapeMatch = text:gmatch("%{+$")()
			local isEscaped = escapeMatch and #escapeMatch % 2 == 1
			if not isEscaped then
				local placeholderSplit = Strings.splitOn(placeholder, ":")
				local nextIndex = tonumber(placeholderSplit[1])
				local displayString = placeholderSplit[2]
				local arg
				if nextIndex then
					arg = args[nextIndex]
				else
					arg = args[argIndex]
					argIndex = argIndex + 1
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

--[[
	Format a specific _value_ using the specified _displayString_.
]]
--: any, DisplayString -> string
function Strings.formatValue(value, displayString)
	if displayString:find("#%?") ~= nil then
		return Strings.pretty(value)
	elseif displayString:find("%?") ~= nil then
		return Tables.serializeDeep(value)
	else
		return tostring(value)
	end
end

--[[
	Returns a human-readable string for the given _value_. If _multiline_ is `true`, the string
	will be formatted across multiple lines if a descendant element gets longer than `80`
	characters.

	@usage This format may be improved in the future, so use `_.serializeDeep` if need a format
		which won't change.
	@see _.serializeDeep
]]
--: any, bool -> string
function Strings.pretty(value, multiline)
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

	return Tables.serialize(
		value,
		{
			serializeValue = serializeValue,
			serializeKey = function(key, options)
				if type(key) == "string" then
					return key
				else
					return "[" .. serializeValue(key, options) .. "]"
				end
			end,
			serializeElement = multiline and function(key, value)
					local shortString = key .. " = " .. value
					if #shortString < 80 or shortString:match("\n") then
						return shortString
					end
					return key .. " =\n\t" .. value
				end or nil,
			serializeTable = multiline and
				function(contents, ref, options)
					local shortString = ref .. "{" .. table.concat(contents, ", ") .. "}"
					if #shortString < 80 then
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
				end or
				nil,
			keyDelimiter = " = ",
			valueDelimiter = ", ",
			omitKeys = {"Class"}
		}
	)
end

return Strings
