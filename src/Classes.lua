--[[
	These tools provide implementations of and functions for higher-order abstractions such as classes, enumerations and symbols.
]]
local t = require(script.Parent.t)
local Tables = require(script.Tables)
local Functions = require(script.Functions)
local Classes = {}

--[[
	Create a class called _name_ with the specified _constructor_. The constructor should return a
	plain table which will be turned into an instance of _Class_ from a call to `Class.new(...)`.

	Optionally, you may provide an array of _decorators_ which compose and reduce the Class, adding
	additional methods and functionality you may need. Specifically you can:
	
	1. Add standard functionality to the class e.g. `_.Clone`, `_.ShallowEq`, `_.PrettyFormat`
	2. Mixin an implementation of an interface e.g. `_.mixin( fns )`
	3. Decorate fields or functions e.g. `_.decorate(_.freeze)`, `_.decorate(_.bindAll)`

	@param constructor (default = `_.returns({})`)
	@param decorators (default = `{}`)
	@example
		-- Create a simple Vehicle class
		local Vehicle = _.class("Vehicle", function( wheelCount ) return 
			{
				speed = 0,
				wheelCount = wheelCount
			}
		end)
		function Vehicle:drive(speed)
			self.speed = speed
		end
		-- Create a car instance
		local car = Vehicle.new(4)
		car.wheelCount --> 4
		car.speed --> 0
		-- Drive the car
		car:drive(10)
		car.speed --> 10
	@usage When using Rodash classes, private fields should be prefixed with `_` to avoid accidental access.
	@usage A private field should only be accessed by a method of the class itself, though Rodash
		does not restrict this in code.
	@usage Public fields are recommended when there is no complex access logic e.g. `position.x`
	@see _.classWithInterface - recommended for providing runtime type-checking.
	@see _.mixin - extend the class with extra methods.
	@see _.decorate - include methods that run when an instance of the class is constructed.
]]
--: <T>(string, Constructor<T>?, Decorator<T>[]?) -> Class<T>
function Classes.class(name, constructor, decorators)
	assert(t.string(name), "Class name must be a string")
	assert(t.optional(t.callback)(constructor), "Class constructor must be a function or nil")
	assert(t.optional(t.table)(decorators), "Class decorators must be a table")
	local decorate = Functions.compose(unpack(decorators or {}))
	constructor = constructor or function()
			return {}
		end
	-- @type Class<T>
	local Class = {
		name = name
	}
	--[[
		Return a new instance of the class, passing any arguments to the specified constructor.
	]]
	--: Constructor<T>
	function Class.new(...)
		local instance = constructor(...)
		setmetatable(instance, {__index = Class, __tostring = Class.toString})
		instance:_init(...)
		instance.Class = Class
		return instance
	end
	--[[
		Run after the instance has been properly initialized, allowing methods on the instance to
		be used.
		@example
			local Vehicle = _.class("Vehicle", function( wheelCount ) return 
				{
					speed = 0,
					wheelCount = wheelCount
				}
			end)
			-- Let's define a static private function to generate a unique id for each vehicle.
			function Vehicle._getNextId()
				Vehicle._nextId = Vehicle._nextId + 1
				return Vehicle._nextId
			end
			Vehicle._nextId = 0
			-- A general purpose init function may call other helper methods
			function Vehicle:_init()
				self._id = self:_generateId()
			end
			-- Assign an id to the new instance
			function Vehicle:_generateId()
				return _.format("#{}: {} wheels", Vehicle._getNextId(), self.wheelCount)
			end
			-- Return the id if the instance is represented as a string 
			function Vehicle:toString()
				return self._id
			end

			local car = Vehicle.new(4)
			tostring(car) --> "#1: 4 wheels"
	]]
	--: (mut T:) -> nil
	function Class:_init()
	end
	--[[
		Returns `true` if _value_ is an instance of _Class_ or any sub-class.
		@example
			local Vehicle = _.class("Vehicle", function( wheelCount ) return 
				{
					speed = 0,
					wheelCount = wheelCount
				}
			end)
			local Car = Vehicle:extend("Vehicle", function()
				return Vehicle.constructor(4)
			end)
			local car = Car.new()
			car.isInstance(Car) --> true
			car.isInstance(Vehicle) --> true
			car.isInstance(Bike) --> false
	]]
	--: any -> bool
	function Class.isInstance(value)
		local ok = Classes.isA(value, Class)
		return ok, not ok and string.format("Not a %s instance", name) or nil
	end
	--[[
		Create a subclass of _Class_ with a new _name_ that inherits the metatable of _Class_,
		optionally overriding the _constructor_ and providing additional _decorators_.

		The super-constructor can be accessed with `Class.constructor`.

		Super methods can be accessed using `Class.methodName` and should be called with self.

		@example
			local Vehicle = _.class("Vehicle", function( wheelCount ) return 
				{
					speed = 0,
					wheelCount = wheelCount
				}
			end)
			-- Let's define a static private function to generate a unique id for each vehicle.
			function Vehicle._getNextId()
				Vehicle._nextId = Vehicle._nextId + 1
				return Vehicle._nextId
			end
			Vehicle._nextId = 0
			-- A general purpose init function may call other helper methods
			function Vehicle:_init()
				self.id = self:_generateId()
			end
			-- Assign an id to the new instance
			function Vehicle:_generateId()
				return _.format("#{}: {} wheels", Vehicle._getNextId(), self.wheelCount)
			end
			-- Let's make a Car class which has a special way to generate ids
			local Car = Vehicle:extend("Vehicle", function()
				return Vehicle.constructor(4)
			end)
			-- Uses the super method to generate a car-specific id
			function Car:_generateId()
				self.id = _.format("Car {}", Vehicle._generateId(self))
			end

			local car = Car.new()
			car.id --> "Car #1: 4 wheels"
	]]
	--: <S: T>(T: string, Constructor<T>? Decorator[]?) -> Class<S>
	function Class:extend(name, constructor, decorators)
		local SubClass = Classes.class(name, constructor or Class.new, decorators)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end
	--[[
		Create a subclass of _Class_ with a new _name_ that inherits the metatable of _Class_,
		optionally overriding the _constructor_ and providing additional _decorators_.

		@usage Interfaces currently silently override super interfaces, even if their types
		are incompatible. Avoid doing this as more advanced type checking may throw if the types
		do not unify in the future.

		@example
			local Vehicle = _.classWithInterface("Vehicle", {
				speed = t.number,
				wheelCount = t.number,
				color: t.string
			})
			local vehicle = Vehicle.new({
				speed = 5,
				wheelCount = 4,
				color = "red"
			})
			_.pretty(vehicle) --> 'Vehicle {speed = 4, wheelCount = 4, color = "red"}'
	]]
	--: <S: T>(T: string, S, Decorator[]?) -> Class<S>
	function Class:extendWithInterface(name, interface, decorators)
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
		local compositeInterface = function(Class)
			return Tables.assign({}, getComposableInterface(interface)(Class), getComposableInterface(inheritedInterface)(Class))
		end
		local SubClass = Classes.classWithInterface(name, compositeInterface, decorators)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end

	--[[
		Return a string representation of the instance. By default this is the _name_ field (or the
		Class name if this is not defined), but the method can be overwritten.
	]]
	--: (T:) -> string
	function Class:toString()
		return self.name
	end
	return decorate(Class)
end

--[[
	Create a class called _name_ that implements a specific strict interface which is asserted when
	any instance is created.

	Instead of using a constructor, an instance is initialized with a table containing the required
	fields. If an `_init` method is present on the instance, this is called afterwards, which has
	the added benefit over a constructor that `self` and the instance are well-defined.

	Optionally, you may provide an array of _decorators_ which compose and reduce the Class, adding
	additional functionality in the same way `_.class` does.

	@usage Rodash uses `t` by Osyris to perform runtime type assertions, which we recommend using during
	development and production code to catch errors quickly and fail fast. For more information
	about `t`, please visit [https://github.com/osyrisrblx/t](https://github.com/osyrisrblx/t).
	@usage If you want to instantiate private fields, we recommend using a static factory with a
		public interface, using `_.privatize` if appropriate.
	@see _.class
	@see _.privatize
]]
--: <T>(string, T, Decorator<T>[]? -> Class<T>)
function Classes.classWithInterface(name, interface, decorators)
	local function getImplementsInterface(currentInterface)
		local ok, problem = t.values(t.callback)(currentInterface)
		assert(ok, string.format([[BadInput: Class %s does not have a valid interface
%s]], name, tostring(problem)))
		return t.strictInterface(currentInterface)
	end
	local implementsInterface
	local Class =
		Classes.class(
		name,
		function(data)
			data = data or {}
			local ok, problem = implementsInterface(data)
			assert(ok, string.format([[BadInput: Class %s cannot be instantiated
%s]], name, tostring(problem)))
			return Tables.mapKeys(
				data,
				function(_, key)
					return key
				end
			)
		end,
		decorators
	)
	implementsInterface =
		type(interface) == "function" and getImplementsInterface(interface(Class)) or getImplementsInterface(interface)
	Class.interface = interface
	return Class
end

--[[
	Create an enumeration from an array string _keys_, provided in upper snake-case.

	An Enum is used when a value should only be one of a limited number of possible states.
	`_.makeEnum` creates a string enum, which uses a name for each state so it is easy to refer to.
	For ease of use values in the enum are identical to their key.

	Enums are frozen and will throw if access to a missing key is attempted, helping to eliminate
	typos.

	Symbols are not used so that enum values are serializable.

	@param keys provided in upper snake-case.
]]
--: <T>(string -> Enum<T>)
function Classes.enum(keys)
	local enum =
		Tables.keyBy(
		keys,
		function(key)
			assert(key:match("^[A-Z_]+$"), "BadInput: Enum keys must be defined as upper snake-case")
			return key
		end
	)

	setmetatable(
		enum,
		{
			__index = function(t, key)
				error(string.format("MissingKey: Attempt to access key %s which is not a valid key of the enum", key))
			end,
			__newindex = function(t, key)
				error(string.format("ReadonlyKey: Attempt to set key %s on enum", key))
			end
		}
	)
	return enum
end

--[[
	Given an _enum_ and _strategies_, a dictionary of functions keyed by enum values, `_.match`
	returns a function that will execute the strategy for any value provided.

	A strategy for every enum key must be implemented, and this helps prevent missing values
	from causing problems later on down the line.

	If the _enum_ is a symbol enum, the value tuple will be unpacked as arguments to the strategy.
]]
--: <T: Iterable<K>, V>(Enum<T>, {[K]: () -> V}) -> K -> V
function Classes.match(enum, strategies)
	assert(t.table(enum), "BadInput: enum should be a table")
	assert(
		Tables.deepEquals(Tables.sort(Tables.values(enum)), Tables.sort(Tables.keys(strategies))),
		"BadInput: keys for strategies must match values for enum"
	)
	assert(t.values(t.callback)(strategies), "BadInput: strategies values must be functions")

	return function(enumValue)
		assert(Classes.isA(enumValue, enum), "BadInput: enumValue must be an instance of enum")
		local strategy = strategies[enumValue]
		if type(enumValue) == "table" then
			return strategy(unpack(enumValue))
		else
			return strategy()
		end
	end
end

--[[
	Mutates _object_, making attempts to update or accessing missing keys throw `ReadonlyKey`
	and `MissingKey` respectively.
]]
--: <T: table>(mut T -> T)
function Classes.freeze(object)
	local backend = getmetatable(object)
	local proxy = {
		__index = function(t, key)
			error(string.format("MissingKey: Attempt to access key %s which is missing in final object", key))
		end,
		__newindex = function(t, key)
			error(string.format("ReadonlyKey: Attempt to set key %s on final object", key))
		end
	}
	if backend then
		setmetatable(proxy, backend)
	end

	setmetatable(object, proxy)

	return object
end

--[[
	Returns `true` if _value_ is an instance of _type_.

	Type can currently be either an _Enum_ or a _Class_ table. For instances of classes,
	`_.isA` will also return true if the instance is an instance of any sub-class.

	The function will catch any errors thrown during this check, returning false if so.

	@example
		local Vehicle = _.class("Vehicle", function( wheelCount ) return 
			{
				speed = 0,
				wheelCount = wheelCount
			}
		end)
		local car = Vehicle.new(4)
		Vehicle.isA(car) --> true
		Vehicle.isA(5) --> false

	@example
		local toggle = _.enum("ON", "OFF")
		toggle.isA("ON") --> true
		toggle.isA(5) --> false

	@usage This is useful if you no nothing about _value_.
]]
--: <T>(any, Type<T> -> bool)
function Classes.isA(value, Type)
	local ok, isAType =
		pcall(
		function()
			local isEnum = type(value) == "string"
			if isEnum then
				local isEnumKeyDefined = type(Type[value]) == "string"
				return isEnumKeyDefined
			elseif type(value) == "table" then
				if value.__symbol and Type[value.__symbol] == value then
					return true
				end
				local metatable = getmetatable(value)
				while metatable do
					if metatable.__index == Type then
						return true
					end
					metatable = getmetatable(metatable.__index)
				end
			end
			return false
		end
	)
	return ok and isAType
end

--[[
	Create a symbol with a specified _name_.
	
	Symbols are useful when you want a value that isn't equal to any other type, for example if you
	want to store a unique property on an object that won't be accidentally accessed with a simple
	string lookup.
]]
--: <T>(string -> Symbol<T>)
function Classes.symbol(name)
	local symbol = {
		__symbol = name
	}
	setmetatable(
		symbol,
		{
			__tostring = function()
				return "Symbol(" .. name .. ")"
			end
		}
	)
	return symbol
end

return Classes
