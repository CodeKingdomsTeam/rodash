local Async = require(script.Async)
local Classes = require(script.Classes)
local Functions = require(script.Functions)
local Strings = require(script.Strings)
local Tables = require(script.Tables)

local _ = Tables.assign(Async, Classes, Functions, Strings, Tables)
setmetatable(
	_,
	{
		__call = function(self, ...)
			return _.chain(...)
		end
	}
)
return _
