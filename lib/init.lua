local Async = require(script.Async)
local Classes = require(script.Classes)
local Functions = require(script.Functions)
local Strings = require(script.Strings)
local Tables = require(script.Tables)

local _ = Tables.assign(Async, Classes, Functions, Strings, Tables)

local getChain =
	Functions.once(
	function(subject)
		return Functions.chain(subject)
	end
)

_.fn = {}
setmetatable(
	_.fn,
	{
		__index = function(self, key)
			return getChain(_)[key]
		end,
		__call = function(self, subject)
			return subject
		end,
		__tostring = function()
			return "_.fn"
		end
	}
)
return _
