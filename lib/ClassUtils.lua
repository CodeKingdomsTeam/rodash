local tea = require(script.Parent.Parent.tea)
local TableUtils = require(script.Parent.TableUtils)
local ClassUtils = {}

function ClassUtils.makeClass(name, constructor)
	assert(tea.string(name), "Class name must be a string")
	assert(tea.optional(tea.callback)(constructor), "Class constructor must be a function or nil")
	constructor = constructor or function()
			return {}
		end
	local Class = {
		name = name
	}
	function Class.new(...)
		local instance = constructor(...)
		setmetatable(instance, {__index = Class, __tostring = Class.toString})
		if instance._init then
			instance:_init(...)
		end
		instance.Class = Class
		return instance
	end
	function Class.isInstance(value)
		local ok = ClassUtils.isA(value, Class)
		return ok, not ok and string.format("Not a %s instance", name) or nil
	end
	function Class:extend(name, subConstructor)
		local SubClass = ClassUtils.makeClass(name, subConstructor or Class.new)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end
	function Class:extendWithInterface(name, interface)
		local function getComposableInterface(input)
			if input == nil then
				return function()
					return {}
				end
			elseif type(input) == "function" then
				return input
			else
				return function()
					return input
				end
			end
		end
		local inheritedInterface = self.interface
		-- NOTE: Sub interfaces can at present override super interfaces, so this should be avoided
		-- to provide better validation detection / true field type inheritence.
		local compositeInterface = function(Class)
			return TableUtils.assign(
				{},
				getComposableInterface(interface)(Class),
				getComposableInterface(inheritedInterface)(Class)
			)
		end
		local SubClass = ClassUtils.makeClassWithInterface(name, compositeInterface)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end
	function Class:toString()
		return self.name
	end
	return Class
end

function ClassUtils.makeClassWithInterface(name, interface)
	local function getImplementsInterface(currentInterface)
		local ok, problem = tea.values(tea.callback)(currentInterface)
		assert(ok, string.format([[Class %s does not have a valid interface
%s]], name, tostring(problem)))
		return tea.strictInterface(currentInterface)
	end
	local implementsInterface
	local Class =
		ClassUtils.makeClass(
		name,
		function(data)
			data = data or {}
			local ok, problem = implementsInterface(data)
			assert(ok, string.format([[Class %s cannot be instantiated
%s]], name, tostring(problem)))
			return TableUtils.mapKeys(
				data,
				function(_, key)
					return "_" .. key
				end
			)
		end
	)
	implementsInterface =
		type(interface) == "function" and getImplementsInterface(interface(Class)) or getImplementsInterface(interface)
	Class.interface = interface
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
				error(string.format("Attempt to access key %s which is not a valid key of the enum", key))
			end,
			__newindex = function(t, key)
				error(string.format("Attempt to set key %s on enum", key))
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
