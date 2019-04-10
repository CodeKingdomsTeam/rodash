local tea = require(script.Parent.Parent.tea)
local TableUtils = require(script.Parent.TableUtils)
local ClassUtils = {}

function ClassUtils.makeClass(name, constructor)
	constructor = constructor or function()
			return {}
		end
	local Class = {
		name = name,
		constructor = constructor
	}
	function Class.new(...)
		local instance = constructor(...)
		setmetatable(instance, {__index = Class, __tostring = Class.toString})
		return instance
	end
	function Class:extend(name, constructor)
		local SubClass = ClassUtils.makeClass(name, constructor or self.constructor)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end
	function Class:toString()
		return self.name
	end
	return Class
end

function ClassUtils.makeConstructedClass(name, constructor)
	constructor = constructor or function()
		end
	local Class
	Class =
		ClassUtils.makeClass(
		name,
		function(data)
			local instance = TableUtils.clone(data)
			if constructor then
				setmetatable(instance, {__index = Class, __tostring = Class.toString})
				constructor(instance)
			end
			return instance
		end
	)
	Class.constructor = constructor
	function Class:extend(name, constructor)
		local SubClass = ClassUtils.makeConstructedClass(name, constructor)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end
	return Class
end

function ClassUtils.makeEnum(keys)
	local enum =
		TableUtils.keyBy(
		keys,
		function(key)
			assert(key:match("^[A-Z_]+$"), "Enum keys must be defined as upper snake case")
			return key
		end
	)

	setmetatable(
		enum,
		{
			__index = function(t, key)
				error("Attempt to access key " .. key .. " which is not a valid key of the enum")
			end,
			__newindex = function(t, key)
				error("Attempt to set key " .. key .. " on enum")
			end
		}
	)

	return enum
end

function ClassUtils.applySwitchStrategyForEnum(enum, enumValue, strategies, ...)
	assert(ClassUtils.isA(enumValue, enum), "enumValue must be an instance of enum")
	assert(
		TableUtils.deepEquals(TableUtils.sort(TableUtils.values(enum)), TableUtils.sort(TableUtils.keys(strategies))),
		"keys for strategies must match values for enum"
	)
	assert(tea.values(tea.callback)(strategies), "strategies values must be functions")

	return strategies[enumValue](...)
end

function ClassUtils.makeSymbolEnum(keys)
	return TableUtils.map(
		ClassUtils.makeEnum(keys),
		function(key)
			return ClassUtils.makeSymbol(key)
		end
	)
end

function ClassUtils.isA(instance, classOrEnum)
	local isEnum = type(instance) == "string"
	if isEnum then
		local isEnumKeyDefined = type(classOrEnum[instance]) == "string"
		return isEnumKeyDefined
	elseif type(instance) == "table" then
		if instance.__symbol and classOrEnum[instance.__symbol] == instance then
			return true
		end
		local metatable = getmetatable(instance)
		while metatable do
			if metatable.__index == classOrEnum then
				return true
			end
			metatable = getmetatable(metatable.__index)
		end
	end
	return false
end

function ClassUtils.makeSymbol(name)
	local symbol = {
		__symbol = name
	}
	setmetatable(
		symbol,
		{
			__tostring = function()
				return name
			end
		}
	)
	return symbol
end

return ClassUtils
