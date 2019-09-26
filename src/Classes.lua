--[[
	These tools provide implementations of and functions for higher-order abstractions such as classes, enumerations and symbols.
]]
local t = require(script.Parent.Parent.t)
local Tables = require(script.Parent.Tables)
local Arrays = require(script.Parent.Arrays)
local Functions = require(script.Parent.Functions)
local Classes = {}

--[[
	Create a class called _name_ with the specified _constructor_. The constructor should return a
	plain table which will be turned into an instance of _Class_ from a call to `Class.new(...)`.

	Optionally, you may provide an array of _decorators_ which compose and reduce the Class, adding
	additional methods and functionality you may need. Specifically you can:
	
	1. Add standard functionality to the class e.g. `dash.Cloneable`, `dash.ShallowEq`
	2. Mixin an implementation of an interface e.g. `dash.mixin( fns )`
	3. Decorate fields or functions e.g. `dash.decorate(dash.freeze)`

	@param constructor (default = `dash.construct({})`)
	@param decorators (default = `{}`)
	@example
		-- Create a simple Vehicle class
		local Vehicle = dash.class("Vehicle", function(wheelCount) return 
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
	@see `dash.classWithInterface` - recommended for providing runtime type-checking.
	@see `dash.mixin` - extend the class with extra methods.
	@see `dash.decorate` - include methods that run when an instance of the class is constructed.
	@see `dash.construct` - provide a default object to use as a new instance.
]]
--: <T>(string, Constructor<T>?, Decorator<T>[]?) -> Class<T>
function Classes.class(name, constructor, decorators)
	assert(t.string(name), "BadInput: name must be a string")
	assert(t.optional(Functions.isCallable)(constructor), "BadInput: constructor must be callable or nil")
	assert(t.optional(t.table)(decorators), "BadInput: decorators must be a table or nil")
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
		@example
			local Car = dash.class("Car", function(speed)
				return {
					speed = speed
				}
			end)
			local car = Car.new(5)
			dash.pretty(car) --> 'Car {speed = 5}'
	]]
	--: <S, A>(...A -> S)
	function Class.new(...)
		local instance = constructor(...)
		setmetatable(
			instance,
			{
				__index = Class,
				__tostring = Class.toString,
				__eq = Class.equals,
				__lt = Class.__lt,
				__le = Class.__le,
				__add = Class.__add,
				__sub = Class.__sub,
				__mul = Class.__mul,
				__div = Class.__div,
				__mod = Class.__mod
			}
		)
		instance.Class = Class
		instance:_init(...)
		return instance
	end
	--[[
		Run after the instance has been properly initialized, allowing methods on the instance to
		be used.
		@example
			local Vehicle = dash.class("Vehicle", function(wheelCount) return 
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
				return dash.format("#{}: {} wheels", Vehicle._getNextId(), self.wheelCount)
			end
			-- Return the id if the instance is represented as a string 
			function Vehicle:toString()
				return self._id
			end

			local car = Vehicle.new(4)
			tostring(car) --> "#1: 4 wheels"
	]]
	--: (mut self) -> ()
	function Class:_init()
	end

	--[[
		Returns `true` if _value_ is an instance of _Class_ or any sub-class.
		@example
			local Vehicle = dash.class("Vehicle", function(wheelCount) return 
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
			local Vehicle = dash.class("Vehicle", function(wheelCount) return 
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
				return dash.format("#{}: {} wheels", Vehicle._getNextId(), self.wheelCount)
			end
			-- Let's make a Car class which has a special way to generate ids
			local Car = Vehicle:extend("Vehicle", function()
				return Vehicle.constructor(4)
			end)
			-- Uses the super method to generate a car-specific id
			function Car:_generateId()
				self.id = dash.format("Car {}", Vehicle._generateId(self))
			end

			local car = Car.new()
			car.id --> "Car #1: 4 wheels"
	]]
	--: <S: T>(string, Constructor<S>?, Decorator<S>[]?) -> Class<S>
	function Class:extend(name, constructor, decorators)
		local SubClass = Classes.class(name, constructor or Class.new, decorators)
		setmetatable(SubClass, {__index = self})
		return SubClass
	end

	--[[
		Create a subclass of _Class_ with a new _name_ that inherits the metatable of _Class_,
		optionally overriding the _constructor_ and providing additional _decorators_.

		@example
			local Vehicle = dash.classWithInterface("Vehicle", {
				color = t.string
			})
			local Car = Vehicle:extendWithInterface("Car", {
				bootContents = t.array(t.string)
			})
			local car = Car.new({
				color = "red",
				bootContents = "tyre", "bannana"
			})
			dash.pretty(car) --> 'Car {bootContents = {"tyre", "bannana"}, color = "red"}'

		@usage Interfaces currently silently override super interfaces, even if their types
		are incompatible. Avoid doing this as more advanced type checking may throw if the types
		do not unify in the future.

		@see `Class.extend`
		@see `dash.classWithInterface`
		@see [The t library](https://github.com/osyrisrblx/t) - used to check types at runtime.
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
		Class name if this is not defined), but the method can be overridden.
		@example
			local Car = dash.class("Car", function(name)
				return {
					name = name
				}
			end)
			
			local car = Car.new()
			car:toString() --> 'Car'
			tostring(car) --> 'Car'
			print("Hello " .. car) -->> Hello Car

			local bob = Car.new("Bob")
			bob:toString() --> 'Bob'
			tostring(bob) --> 'Bob'
			print("Hello " .. bob) -->> Hello Bob

		@example
			local NamedCar = dash.class("NamedCar", function(name)
				return {
					name = name
				}
			end)

			function NamedCar:toString()
				return "Car called " .. self.name
			end

			local bob = NamedCar.new("Bob")
			bob:toString() --> 'Car called Bob'
			tostring(bob) --> 'Car called Bob'
			print("Hello " .. bob) -->> Hello Car called Bob
	]]
	--: () -> string
	function Class:toString()
		return self.name
	end

	--[[
		Returns `true` if `self` is considered equal to _other_. This replaces the `==` operator
		on instances of this class, and can be overridden to provide a custom implementation.
	]]
	--: T -> bool
	function Class:equals(other)
		return rawequal(self, other)
	end

	--[[
		Returns `true` if `self` is considered less than  _other_. This replaces the `<` operator
		on instances of this class, and can be overridden to provide a custom implementation.
	]]
	--: T -> string
	function Class:__lt(other)
		return false
	end

	--[[
		Returns `true` if `self` is considered less than or equal to _other_. This replaces the
		`<=` operator on instances of this class, and can be overridden to provide a custom
		implementation.
	]]
	--: T -> string
	function Class:__le(other)
		return false
	end

	return decorate(Class)
end

--[[
	Create a class called _name_ that implements a specific strict _interface_ which is asserted
	when any instance is created.

	Instead of using a constructor, an instance is initialized with a table containing the required
	fields. If an `_init` method is present on the instance, this is called afterwards, which has
	the added benefit over a constructor that `self` and the instance are well-defined.

	Rodash uses [The t library](https://github.com/osyrisrblx/t) to check types at runtime, meaning
	the interface must be a dictionary of keys mapped to type assertion functions, such as
	`t.number`, `dash.isCallable` etc.

	Optionally, you may provide an array of _decorators_ which are reduced with the Class, adding
	additional functionality in the same way `dash.class` does. See [Decorator](/rodash/types#Decorator)
	for more information.

	@example
		local Vehicle = dash.classWithInterface("Vehicle", {
			speed = t.number,
			wheelCount = t.number,
			color = t.string
		})
		local vehicle = Vehicle.new({
			speed = 5,
			wheelCount = 4,
			color = "red"
		})
		dash.pretty(vehicle) --> 'Vehicle {speed = 4, wheelCount = 4, color = "red"}'

	@usage Rodash uses `t` by Osyris to perform runtime type assertions, which we recommend using
	in your own code development and production to catch errors quickly and fail fast. For more
	information about `t`, please visit
	[https://github.com/osyrisrblx/t](https://github.com/osyrisrblx/t).
	@usage If you want to instantiate private fields, we recommend using a static factory with a
		public interface, See `dash.privatize` for an example.
	@see `dash.class`
	@see `dash.privatize`
	@see [The t library](https://github.com/osyrisrblx/t) - used to check types at runtime.
]]
--: <T>(string, Interface<T>, Decorator<T>[]? -> Class<T>)
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
			return Tables.keyBy(
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
	Returns a function that creates a shallow copy of the _template_ when called.
	@example
		local Car = dash.class("Car", dash.construct({
			speed = 5
		}))

		local car = Car.new()
		car.speed --> 5
	@example
		-- A constructor can be made for a class with an interface using decorate.
		local constructor = dash.construct({
			speed = 5
		})
		local Car = dash.classWithInterface("Car", {
			speed = t.optional(t.number)
		}, {dash.decorate(constructor)})

		local car = Car.new()
		car.speed --> 5
	@usage Useful if you want to return a default object for a class constructor.
	@see `dash.class`
	@see `dash.classWithInterface`
]]
--: <T:{}>(T -> () -> T)
function Classes.construct(template)
	return function()
		return Tables.clone(template)
	end
end

--[[
	A decorator which adds a dictionary of functions to a Class table.
	@example
		local CanBrake = {
			brake = function(self)
				self.speed = 0
			end
		}
		local Car = dash.class("Car", function(speed)
			return {
				speed = speed
			}
		end, {dash.mixin(CanBrake)})
		local car = Car.new(5)
		print(car.speed) --> 5
		car:brake()
		print(car.speed) --> 0
	@usage Include the return value of this function in the decorators argument when creating a class.
]]
--: <T>((T, ... -> ...)[] -> Class<T> -> Class<T>)
function Classes.mixin(fns)
	assert(t.table(fns), "BadInput: fns must be a table")
	return function(Class)
		Tables.assign(Class, fns)
		return Class
	end
end

--[[
	Returns a decorator which runs _fn_ on each instance of the class that is created, returning
	the result of the function as the class instance.
	@example
		-- Create a decorator which freezes all class keys
		local Frozen = dash.decorate(dash.freeze)
		local StaticCar = dash.class("StaticCar", function(speed)
			return {
				speed = speed
			}
		end, {Frozen})
		function StaticCar:brake()
			self.speed = 0
		end
		local car = Car.new(5)
		print(car.speed) --> 5
		-- The car cannot change speed because speed is now readonly.
		car:brake() --!> ReadonlyKey: Attempt to write to a frozen key speed
	@see `dash.freeze`
	@usage Include the return value of this function in the decorators argument when creating a class.
]]
--: <T>((self:T, ... -> ...) -> Class<T> -> Class<T>)
function Classes.decorate(fn)
	assert(Functions.isCallable(fn), "BadInput: fn must be callable")
	return function(Class)
		local underlyingNew = Class.new
		function Class.new(...)
			local instance = underlyingNew(...)
			return fn(instance)
		end
		return Class
	end
end

--[[
	A decorator which derives a `:clone()` method for the _Class_ that returns a shallow clone of
	the instance when called that has the same metatable as the instance it is called on.
	@example
		local Car =
			Classes.class(
			"Car",
			function(speed)
				return {
					speed = speed
				}
			end,
			{dash.Cloneable}
		)
		function Car:brake()
			self.speed = 0
		end
		local car = Car.new(5)
		local carClone = car:clone()
		print(carClone.speed) --> 5
		carClone:brake()
		print(carClone.speed) --> 0
		print(car.speed) --> 5
]]
--: <T>(Class<T> -> Cloneable<T>)
function Classes.Cloneable(Class)
	function Class:clone()
		local newInstance = Tables.clone(self)
		setmetatable(newInstance, getmetatable(self))
		return newInstance
	end
	return Class
end

--[[
	A decorator which derives the equality operator for the _Class_ so that any instances of the
	class which are shallow equal will be considered equal.
	@example
		local Car =
			Classes.class(
			"Car",
			function(speed)
				return {
					speed = speed
				}
			end,
			{dash.ShallowEq}
		)
		function Car:brake()
			self.speed = 0
		end
		local fastCar = Car.new(500)
		local fastCar2 = Car.new(500)
		local slowCar = Car.new(5)
		print(fastCar == fastCar2) --> true
		print(fastCar == slowCar) --> false
	@usage If you want to check for equality that includes deep descendants, we recommend you
		implement a custom `:equals` method on your class rather than use `dash.deepEqual` as this
		may be slow or fail to check the type of instances in the tree.
	@see `dash.deepEqual` - if you want to consider deep equality
	@see `Class:equals`
]]
--: <T>(Class<T> -> Eq<T>)
function Classes.ShallowEq(Class)
	function Class:equals(other)
		return Tables.shallowEqual(self, other)
	end
	return Class
end

--[[
	A decorator which derives an order for the _Class_, meaning instances of the class
	can be compared using `<`, `<=`, `>` and  `>=`. To do this, it compares values of the two
	instances at the same keys, as defined by the order of the _keys_ passed in.
	@param keys (default = a sorted array of all the instance's keys)
	@example
		local Car =
			Classes.class(
			"Car",
			function(speed)
				return {
					speed = speed
				}
			end,
			{dash.Ord()}
		)
		function Car:brake()
			self.speed = 0
		end
		local fastCar = Car.new(500)
		local fastCar2 = Car.new(500)
		local slowCar = Car.new(5)
		print(fastCar == fastCar2) --> true
		print(fastCar == slowCar) --> false
]]
--: <T>(string[]? -> Class<T> -> Ord<T>)
function Classes.Ord(keys)
	if keys then
		assert(Tables.isArray(keys), "BadInput: keys must be an array if defined")
	end
	local function getInstancesKeys(self, instanceKeys)
		return instanceKeys or Arrays.sort(Tables.keys(self))
	end
	local function compareInstances(self, other, allowEquality)
		local instanceKeys = getInstancesKeys(self, keys)
		for _, key in ipairs(instanceKeys) do
			if Arrays.defaultComparator(self[key], other[key]) then
				return true
			elseif Arrays.defaultComparator(other[key], self[key]) then
				return false
			end
			if self[key] ~= other[key] then
				return not allowEquality
			end
		end
		return allowEquality
	end
	return function(Class)
		function Class:equals(other)
			local instanceKeys = getInstancesKeys(self, keys)
			for _, key in ipairs(instanceKeys) do
				if self[key] ~= other[key] then
					return false
				end
			end
			return true
		end
		function Class:__le(other)
			return compareInstances(self, other, true)
		end
		function Class:__lt(other)
			return compareInstances(self, other, false)
		end
		return Class
	end
end

--[[
	A decorator which derives a `:toString()` method for the _Class_ that displays a serialized
	string of the class name and values of any _keys_ provided.

	@param keys (default = _all the keys of the instance except `"Class"`_)

	@example
		local Car =
			Classes.class(
			"Car",
			function(speed)
				return {
					speed = speed,
					color = "red"
				}
			end,
			{dash.Formatable({"speed"})}
		)
		print(Car.new(5)) --> "Car({speed:5})"
]]
--: <T>(string[]? -> Class<T> -> Formatable<T>)
function Classes.Formatable(keys)
	return function(Class)
		function Class:toString()
			local Strings = require(script.Parent.Strings)
			return Strings.format(
				"{}({})",
				Class.name,
				Tables.serialize(
					self,
					{
						keys = keys,
						omitKeys = {"Class"}
					}
				):sub(2, -2)
			)
		end
		return Class
	end
end

--[[
	Create an enumeration from an array string _keys_, provided in upper snake-case.

	An Enum is used when a value should only be one of a limited number of possible states.
	`dash.enum` creates a string enum, which uses a name for each state so it is easy to refer to.
	For ease of use values in the enum are identical to their key.

	Enums are frozen and will throw if access to a missing key is attempted, helping to eliminate
	typos.

	Symbols are not used so that enum values are serializable.

	@param keys provided in upper snake-case.
	@example
		local TOGGLE = dash.enum("ON", "OFF")
		local switch = TOGGLE.ON
		if switch == TOGGLE.ON then
			game.Workspace.RoomLight.Brightness = 1
		else
			game.Workspace.RoomLight.Brightness = 0
		end
	@see `dash.match`
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
	Classes.finalize(enum)
	return Classes.freeze(enum)
end

--[[
	Given an _enum_ and _strategies_, a dictionary of functions keyed by enum values, `dash.match`
	returns a function that will execute the strategy for any value provided.

	A strategy for every enum key must be implemented, and this helps prevent missing values
	from causing problems later on down the line.

	@example
		local TOGGLE = dash.enum("ON", "OFF")
		local setLightTo = dash.match(TOGGLE, {
			ON = function(light)
				light.Brightness = 1
			end,
			OFF = function(light)
				light.Brightness = 0
			end
		})

		-- This can be used to turn any light on or off:
		setLightTo(TOGGLE.ON, game.Workspace.RoomLight) -- Light turns on

		-- But will catch an invalid enum value:
		setLightTo("Dim", game.Workspace.RoomLight)
		--!> BadInput: enumValue must be an instance of enum
]]
--: <T, ...A, V>(Enum<T>, {[enumValue: T]: Strategy<V, A>}) -> (enumValue: T, ...A) -> V
function Classes.match(enum, strategies)
	assert(t.table(enum), "BadInput: enum should be a table")
	assert(
		Tables.deepEqual(Arrays.sort(Tables.values(enum)), Arrays.sort(Tables.keys(strategies))),
		"BadInput: keys for strategies must match values for enum"
	)
	assert(t.values(t.callback)(strategies), "BadInput: strategies values must be functions")

	return function(enumValue, ...)
		assert(Classes.isA(enumValue, enum), "BadInput: enumValue must be an instance of enum")
		local strategy = strategies[enumValue]
		return strategy(...)
	end
end

--[[
	`dash.finalize` takes _object_ and makes updating or accessing missing keys throw `FinalObject`.
	@example
		local drink = {
			mixer = "coke",
			spirit = "rum"
		}
		dash.finalize(drink)
		drink.mixer = "soda"
		drink.mixer --> "soda"
		print(drink.syrup)
		--!> "FinalObject: Attempt to read missing key syrup to final object"
		drink.syrup = "peach"
		--!> "FinalObject: Attempt to add key mixer on final object"
]]
--: <T:{}>(mut T -> T)
function Classes.finalize(object)
	local backend = getmetatable(object)
	local proxy = {
		__index = function(child, key)
			-- If there is an __index property use this to lookup and see if it exists first.
			if backend and backend.__index then
				local value
				if type(backend.__index) == "function" then
					value = backend.__index(child, key)
				else
					value = backend.__index[key]
				end
				if value ~= nil then
					return value
				end
			end
			error(string.format("FinalObject: Attempt to read missing key %s in final object", key))
		end,
		__newindex = function(child, key)
			error(string.format("FinalObject: Attempt to add key %s to final object", key))
		end
	}
	if backend then
		setmetatable(proxy, backend)
	end

	setmetatable(object, proxy)

	return object
end

--[[
	Create a symbol with a specified _name_. We recommend upper snake-case as the symbol is a
	constant, unless you are linking the symbol conceptually to a different string.
	
	Symbols are useful when you want a value that isn't equal to any other type, for example if you
	want to store a unique property on an object that won't be accidentally accessed with a simple
	string lookup.

	@example
		local DOUBLE = dash.symbol("DOUBLE")
		-- This function acts like filter, but doubles any elements in a row for which DOUBLE is
		-- returned rather than true or false.
		local function filterWithDouble(array, fn)
			return dash.flatMap(array, function(element)
				local result = fn(element)
				if result == DOUBLE then
					return {result, result}
				elseif result then
					return {result}
				else
					return {}
				end
			end)
		end

		local array = {1, 2, 3, 4, 5}
		local function isEven(value)
			return value % 2 == 0
		end
		filterWithDouble(array, isEven) --> {1, 2, 2, 3, 4, 4, 5}
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

--[[
	`dash.freeze` takes _object_ and returns a new read-only version which prevents any values from
	being changed.
	
	Unfortunately you cannot iterate using `pairs` or `ipairs` on frozen objects because Lua 5.1
	does not support overwriting these in metatables. However, you can use `dash.iterator` to get
	an iterator for the object and use that.

	Iterating functions in Rodash such as `dash.map`, `dash.filter` etc. can iterate over frozen objects
	without this. If you want to treat the objects as arrays use `dash.iterator(frozenObject, true)`
	explicitly.

	@example
		local drink = dash.freeze({
			flavor = "mint",
			topping = "sprinkles"
		})
		print(drink.flavor) --> "mint"
		drink.flavor = "vanilla"
		--!> "ReadonlyKey: Attempt to write to a frozen key flavor"
		print(drink.syrup) --> nil
		drink.topping = "flake"
		--!> "ReadonlyKey: Attempt to write to a frozen key topping"

		dash.values(drink) --> {"mint", "sprinkles"}
	@see `dash.iterator`
]]
--: <T: table>(T -> T)
function Classes.freeze(object)
	local proxy = {}
	setmetatable(
		proxy,
		{
			__index = function(child, key)
				return object[key]
			end,
			__newindex = function(child, key)
				error(string.format("ReadonlyKey: Attempt to write to a frozen key %s", key))
			end,
			__len = function(child)
				return #object
			end,
			__tostring = function(child)
				return "Freeze(" .. tostring(object) .. ")"
			end,
			__call = function(child, ...)
				return object(...)
			end,
			iterable = object
		}
	)
	return proxy
end

--[[
	Returns `true` if _value_ is an instance of _type_.

	Type can currently be either an _Enum_ or a _Class_ table. For instances of classes,
	`dash.isA` will also return true if the instance is an instance of any sub-class.

	The function will catch any errors thrown during this check, returning false if so.

	@example
		local Vehicle = dash.class("Vehicle", function(wheelCount)
			return {
				speed = 0,
				wheelCount = wheelCount
			}
		end)
		local car = Vehicle.new(4)
		Vehicle.isA(car) --> true
		Vehicle.isA(5) --> false

	@example
		local TOGGLE = dash.enum("ON", "OFF")
		TOGGLE.isA("ON") --> true
		TOGGLE.isA(5) --> false

	@usage This is useful if you know nothing about _value_.
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

return Classes
