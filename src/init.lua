local Async = require(script.Async)
local Classes = require(script.Classes)
local Functions = require(script.Functions)
local Strings = require(script.Strings)
local Arrays = require(script.Arrays)
local Tables = require(script.Tables)

local dash = Tables.assign({}, Async, Classes, Functions, Strings, Arrays, Tables)
return dash
