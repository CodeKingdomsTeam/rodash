local Classes = require "Classes"
local Tables = require "Tables"
local t = require "t"

describe(
	"Classes",
	function()
		describe(
			"class",
			function()
				it(
					"makes a class with default constructor",
					function()
						local MyClass = Classes.class("Simple")
						function MyClass:getFive()
							return 5
						end
						local myInstance = MyClass.new()
						assert.equals(5, myInstance:getFive())
					end
				)
				it(
					"allows an init impl which passes self",
					function()
						local MyClass = Classes.class("Simple")
						function MyClass:getFive()
							return 5
						end
						function MyClass:_init(amount)
							self.amount = amount + self:getFive()
						end
						local myInstance = MyClass.new(4)
						assert.equals(9, myInstance.amount)
					end
				)
				it(
					"provides a default toString handler",
					function()
						local MyClass = Classes.class("Simple")
						local myInstance = MyClass.new()
						assert.equals("Simple", tostring(myInstance))
					end
				)
				it(
					"makes a class with a constructor",
					function()
						local MyClass =
							Classes.class(
							"Simple",
							function(amount)
								return {
									amount = amount
								}
							end
						)
						function MyClass:addFive()
							return self.amount + 5
						end
						local myInstance = MyClass.new(10)
						assert.equals(15, myInstance:addFive())
					end
				)
			end
		)
		describe(
			"symbol",
			function()
				it(
					"makes a symbol which doesn't alias",
					function()
						local symbol1 = Classes.symbol("TEST")
						local symbol2 = Classes.symbol("TEST")
						assert.equals(symbol1, symbol1)
						assert.are_not.equal(symbol1, symbol2)
						assert.equals("Symbol(TEST)", tostring(symbol1))
					end
				)
			end
		)
		describe(
			"extend",
			function()
				it(
					"makes a subclass with a constructor",
					function()
						local MyClass =
							Classes.class(
							"Simple",
							function(amount)
								return {
									amount = amount
								}
							end
						)
						function MyClass:addVirtual()
							return self.amount + self:getVirtual()
						end
						local MySubclass =
							MyClass:extend(
							"SubSimple",
							function(amount)
								return MyClass.new(amount + 3)
							end
						)
						function MySubclass:getVirtual()
							return 6
						end
						local myInstance = MySubclass.new(10)
						assert.equals(19, myInstance:addVirtual())
					end
				)
				it(
					"provides recursive table lookup",
					function()
						local MyClass = Classes.class("Simple")
						function MyClass:getFive()
							return 5
						end
						local MySubclass = MyClass:extend("SimpleSub")
						function MySubclass:getEight()
							return 8
						end

						local myInstance = MySubclass.new()
						assert.equals(13, myInstance:getFive() + myInstance:getEight())
					end
				)
				it(
					"override constructor and provide route to super",
					function()
						local MyClass =
							Classes.class(
							"Simple",
							function(amount)
								return {
									amount = amount
								}
							end
						)
						local MySubclass =
							MyClass:extend(
							"SimpleSub",
							function(amount)
								local self = MyClass.new(amount + 5)
								self.amount = self.amount + 23
								return self
							end
						)
						function MySubclass:getAmount()
							return self.amount
						end

						local myInstance = MySubclass.new(2)
						assert.equals(30, myInstance:getAmount())
					end
				)
				it(
					"provides virtual methods",
					function()
						local MyClass = Classes.class("Simple")
						function MyClass:addFiveToMagicNumber()
							return 5 + self.getMagicNumber()
						end
						function MyClass:getMagicNumber()
							return 10
						end
						local MySubclass = MyClass:extend("SimpleSub")
						function MySubclass:getMagicNumber()
							return 12
						end

						local myInstance = MyClass.new()
						local mySubInstance = MySubclass.new()
						assert.equals(15, myInstance:addFiveToMagicNumber())
						assert.equals(17, mySubInstance:addFiveToMagicNumber())
					end
				)
			end
		)
		describe(
			"isInstance",
			function()
				it(
					"returns true or false depending on inheritance tree",
					function()
						local MyClass = Classes.class("Simple")
						local MyOtherClass = Classes.class("Simple2")
						local MySubclass = MyClass:extend("SimpleSub")
						local myInstance = MyClass.new()
						local mySubInstance = MySubclass.new()
						local myOtherInstance = MyOtherClass.new()
						assert.is_true(MyClass.isInstance(myInstance))
						assert.is_true(MyClass.isInstance(mySubInstance))
						assert.is_false(MyClass.isInstance(myOtherInstance))
					end
				)
			end
		)
		describe(
			"classWithInterface",
			function()
				it(
					"makes a class which constructs instances from data",
					function()
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)
						function MyClass:getAmount()
							return self.amount
						end
						local myInstance = MyClass.new({amount = 10})
						assert.equals(10, myInstance:getAmount())
					end
				)
				it(
					"throws if the data doesn't match during construction",
					function()
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							{
								amount = t.string
							}
						)
						function MyClass:getAmount()
							return self.amount
						end
						assert.errors(
							function()
								MyClass.new({amount = 10})
							end,
							[[BadInput: Class Simple cannot be instantiated
[interface] bad value for amount:
	string expected, got number]]
						)
					end
				)
				it(
					"throws if the interface is malformed",
					function()
						assert.errors(
							function()
								Classes.classWithInterface(
									"Simple",
									{
										amount = "lol"
									}
								)
							end,
							[[BadInput: Class Simple does not have a valid interface
bad value for key amount:
	function expected, got string]]
						)
					end
				)
				it(
					"allows an instance to be passed as child",
					function()
						local MyComposite = Classes.class("Composite")
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							{
								child = MyComposite.isInstance
							}
						)
						local myInstance = MyClass.new({child = MyComposite.new()})
						assert.is_true(MyComposite.isInstance(myInstance.child))
					end
				)
				it(
					"allows an instance of the same class to be passed as child using a dynamic interface",
					function()
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							function(Class)
								return {
									parent = t.optional(Class.isInstance)
								}
							end
						)
						local myParent = MyClass.new()
						local myChild = MyClass.new({parent = myParent})
						assert.is_true(MyClass.isInstance(myChild.parent))
					end
				)
				it(
					"throw if an instance passed as child is of incorrect type",
					function()
						local MyComposite = Classes.class("Composite")
						local MyBadComposite = Classes.class("BadComposite")
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							{
								child = MyComposite.isInstance
							}
						)
						assert.errors(
							function()
								MyClass.new({child = MyBadComposite.new()})
							end,
							[[BadInput: Class Simple cannot be instantiated
[interface] bad value for child:
	Not a Composite instance]]
						)
					end
				)
				it(
					"takes a shallow copy of the data",
					function()
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)
						function MyClass:setAmount(amount)
							self.amount = amount
						end
						local data = {amount = 10}
						local myInstance = MyClass.new(data)
						myInstance:setAmount(6)
						assert.equals(6, myInstance.amount)
						assert.equals(10, data.amount)
					end
				)
				it(
					"passes instance to init",
					function()
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)

						function MyClass:_init()
							self.nice = self:getDefaultAmount()
						end
						function MyClass:getDefaultAmount()
							return 5
						end
						function MyClass:setAmount(amount)
							self.amount = amount
						end
						local data = {amount = 10}
						local myInstance = MyClass.new(data)
						assert.equals(10, myInstance.amount)
						assert.equals(5, myInstance.nice)
					end
				)
				it(
					"extends produces correct, separate constructors",
					function()
						local MyClass =
							Classes.classWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)

						function MyClass:_init()
							self.nice = self:getDefaultAmount()
						end

						function MyClass:getDefaultAmount()
							return 5
						end

						local MySubclass =
							MyClass:extend(
							"SubSimple",
							function(...)
								local self = MyClass.new(...)
								self.nicer = self.nice + 5
								return self
							end
						)
						local data = {amount = 10}
						local myInstance = MySubclass.new(data)
						assert.equals(5, myInstance.nice)
						assert.equals(10, myInstance.nicer)
					end
				)
			end
		)
		describe(
			"extendWithInterface",
			function()
				local function class()
					local MyClass =
						Classes.classWithInterface(
						"Simple",
						{
							amount = t.number
						}
					)
					local MySubClass =
						MyClass:extendWithInterface(
						"SubSimple",
						{
							subAmount = t.number
						}
					)
					local MyVerySubClass =
						MySubClass:extendWithInterface(
						"VerySubSimple",
						{
							verySubAmount = t.number
						}
					)
					return MyVerySubClass
				end

				it(
					"makes a sub class which verifies types for all interfaces",
					function()
						local myInstance = class().new({amount = 10, subAmount = 20, verySubAmount = 30})
						assert.equals(10, myInstance.amount)
						assert.equals(20, myInstance.subAmount)
						assert.equals(30, myInstance.verySubAmount)
					end
				)

				it(
					"fails invalid types in any interface",
					function()
						assert.errors(
							function()
								class().new({amount = "nope", subAmount = 20, verySubAmount = 30})
							end,
							[[BadInput: Class VerySubSimple cannot be instantiated
[interface] bad value for amount:
	number expected, got string]]
						)
						assert.errors(
							function()
								class().new({amount = 10, subAmount = "nope", verySubAmount = 30})
							end,
							[[BadInput: Class VerySubSimple cannot be instantiated
[interface] bad value for subAmount:
	number expected, got string]]
						)
						assert.errors(
							function()
								class().new({amount = 10, subAmount = 20, verySubAmount = "nope"})
							end,
							[[BadInput: Class VerySubSimple cannot be instantiated
[interface] bad value for verySubAmount:
	number expected, got string]]
						)
					end
				)
				it(
					"fails extra types",
					function()
						assert.errors(
							function()
								class().new({amount = 10, subAmount = 20, verySubAmount = 30, myBadAmount = 40})
							end,
							[[BadInput: Class VerySubSimple cannot be instantiated
[interface] unexpected field 'myBadAmount']]
						)
					end
				)

				local function getClassWithComposedInterfaces(superInterfaceIsFunction, subInterfaceIsFunction)
					local superInterface = {
						amount = t.number
					}

					local MyClass =
						Classes.classWithInterface(
						"Simple",
						superInterfaceIsFunction and function(Class)
								return superInterface
							end or superInterface
					)

					local subInterface = {
						subAmount = t.number
					}

					local MySubClass =
						MyClass:extendWithInterface(
						"SubSimple",
						subInterfaceIsFunction and function(Class)
								return subInterface
							end or subInterface
					)
					return MySubClass
				end

				it(
					"composes function verifiers",
					function()
						local myInstance = getClassWithComposedInterfaces(true, true).new({amount = 10, subAmount = 20})
						assert.equals(10, myInstance.amount)
						assert.equals(20, myInstance.subAmount)
					end
				)

				it(
					"composes data and function verifiers",
					function()
						local myInstance = getClassWithComposedInterfaces(true, false).new({amount = 10, subAmount = 20})
						assert.equals(10, myInstance.amount)
						assert.equals(20, myInstance.subAmount)
					end
				)

				it(
					"composes function with data verifiers",
					function()
						local myInstance = getClassWithComposedInterfaces(false, true).new({amount = 10, subAmount = 20})
						assert.equals(10, myInstance.amount)
						assert.equals(20, myInstance.subAmount)
					end
				)
			end
		)
		describe(
			"mixin",
			function()
				it(
					"mixes in methods to a class prototypes",
					function()
						local mixin = {
							getSix = function(self)
								return self:getFive() + 1
							end,
							getSeven = function(self)
								return self:getSix() + 1
							end
						}

						local MyClass =
							Classes.class(
							"Simple",
							function(number)
								return {
									number = number
								}
							end,
							{Classes.mixin(mixin)}
						)
						function MyClass:getFive()
							return self.number
						end
						local myInstance = MyClass.new(5)
						assert.equals(7, myInstance:getSeven())
					end
				)
			end
		)
		describe(
			"decorate",
			function()
				it(
					"to make final class instances",
					function()
						local Final = Classes.decorate(Classes.finalize)
						local StaticCar =
							Classes.class(
							"StaticCar",
							function(speed)
								return {
									speed = speed
								}
							end,
							{Final}
						)
						function StaticCar:brake()
							self.speed = 0
							self.stopped = true
						end
						local car = StaticCar.new(5)

						assert.errors(
							function()
								car:brake() --!> ReadonlyKey: Attempt to set key speed on frozen object
							end,
							"FinalObject: Attempt to add key stopped to final object"
						)
					end
				)
				it(
					"to make frozen class instances",
					function()
						local Final = Classes.decorate(Classes.freeze)
						local StaticCar =
							Classes.class(
							"StaticCar",
							function(speed)
								return {
									speed = speed
								}
							end,
							{Final}
						)
						function StaticCar:brake()
							self.speed = 0
							self.stopped = true
						end
						local car = StaticCar.new(5)

						assert.errors(
							function()
								car:brake() --!> ReadonlyKey: Attempt to set key speed on frozen object
							end,
							"ReadonlyKey: Attempt to write to a frozen key speed"
						)
					end
				)
			end
		)
		describe(
			"Clone",
			function()
				it(
					"provides a clone for a class",
					function()
						local Car =
							Classes.class(
							"Car",
							function(speed)
								return {
									speed = speed
								}
							end,
							{Classes.Clone}
						)
						function Car:brake()
							self.speed = 0
						end
						local car = Car.new(5)
						local carClone = car:clone()
						assert.equal(carClone.speed, 5)
						carClone:brake()
						assert.equal(carClone.speed, 0)
						assert.equal(car.speed, 5)
					end
				)
			end
		)
		describe(
			"ShallowEq",
			function()
				it(
					"provides an equal opperator for a class",
					function()
						local Car =
							Classes.class(
							"Car",
							function(speed)
								return {
									speed = speed
								}
							end,
							{Classes.ShallowEq}
						)
						function Car:brake()
							self.speed = 0
						end
						local fastCar = Car.new(500)
						local fastCar2 = Car.new(500)
						local slowCar = Car.new(5)
						assert.equal(fastCar, fastCar2)
						assert.not_equal(fastCar, slowCar)
					end
				)
			end
		)
		describe(
			"enum",
			function()
				it(
					"makes an enum from an array",
					function()
						local ENUM = Classes.enum({"ONE", "TWO", "THREE_YEAH"})
						assert.equals("ONE", ENUM.ONE)
						assert.equals("TWO", ENUM.TWO)
						assert.equals("THREE_YEAH", ENUM.THREE_YEAH)
					end
				)
				it(
					"warns about bad casing",
					function()
						local errorMessage = "BadInput: Enum keys must be defined as upper snake-case"
						assert.has_error(
							function()
								Classes.enum({"One"})
							end,
							errorMessage
						)
						assert.has_error(
							function()
								Classes.enum({"ONOE_!"})
							end,
							errorMessage
						)
						assert.has_error(
							function()
								Classes.enum({""})
							end,
							errorMessage
						)
					end
				)

				describe(
					"throws for a missing key when",
					function()
						local ENUM

						before_each(
							function()
								ENUM = Classes.enum({"ONE", "TWO", "THREE_YEAH"})
							end
						)

						it(
							"getting",
							function()
								assert.has_error(
									function()
										print(ENUM.BLAH)
									end
								)
							end
						)

						it(
							"setting",
							function()
								assert.has_error(
									function()
										ENUM.BLAH = true
									end
								)
							end
						)
					end
				)
			end
		)
		describe(
			"isA",
			function()
				it(
					"checks an element of an Enum",
					function()
						local ENUM = Classes.enum({"ONE", "TWO", "THREE_YEAH"})
						assert.truthy(Classes.isA(ENUM.ONE, ENUM))
					end
				)

				it(
					"checks an instance of a class",
					function()
						local MyClass = Classes.class("Simple")
						local myInstance = MyClass.new()
						assert.truthy(Classes.isA(myInstance, MyClass))
						assert.not_truthy(Classes.isA({}, MyClass))
						assert.not_truthy(Classes.isA(MyClass, MyClass))
					end
				)
				it(
					"checks an instance of a super class",
					function()
						local MyClass = Classes.class("Simple")
						local MySubclass = MyClass:extend("SimpleSub")
						local myInstance = MySubclass.new()
						assert.truthy(Classes.isA(myInstance, MyClass))
						assert.truthy(Classes.isA(myInstance, MySubclass))
						assert.not_truthy(Classes.isA({}, MyClass))
						assert.not_truthy(Classes.isA(MyClass, MyClass))
						assert.truthy(Classes.isA(MySubclass, MyClass))
						assert.not_truthy(Classes.isA(MyClass, MySubclass))
					end
				)
			end
		)

		describe(
			"finalize",
			function()
				it(
					"warns about using a missing key",
					function()
						local myObject =
							Classes.finalize(
							{
								a = 2
							}
						)
						assert.equals(2, myObject.a)
						assert.errors(
							function()
								return myObject.b
							end,
							"FinalObject: Attempt to read missing key b in final object"
						)
					end
				)
				it(
					"warns about assignment to an unused variable",
					function()
						local myObject =
							Classes.finalize(
							{
								a = 2
							}
						)
						assert.errors(
							function()
								myObject.b = 2
							end,
							"FinalObject: Attempt to add key b to final object"
						)
					end
				)
				it(
					"allows iteration over a table",
					function()
						local myObject =
							Classes.finalize(
							{
								a = 2,
								b = 3
							}
						)
						assert.are.same({2, 3}, Tables.values(myObject))
					end
				)
				it(
					"warns about using a missing key on an instance",
					function()
						local MyClass = Classes.class("Simple")
						function MyClass:getFive()
							return 5
						end
						local myInstance = MyClass.new()
						Classes.finalize(myInstance)
						assert.errors(
							function()
								return myInstance.b
							end,
							"FinalObject: Attempt to read missing key b in final object"
						)
						assert.equals(5, myInstance:getFive())
					end
				)
			end
		)

		describe(
			"match",
			function()
				local ENUM = Classes.enum({"ONE", "TWO"})
				local strategies = {
					ONE = function()
						return 1
					end,
					TWO = function()
						return 2
					end
				}

				it(
					"applies a strategy correctly",
					function()
						local result = Classes.match(ENUM, strategies)(ENUM.ONE)
						assert.equal(1, result)
					end
				)

				it(
					"throws if the enum is invalid",
					function()
						assert.has_errors(
							function()
								Classes.match(2, strategies)
							end
						)
					end
				)

				it(
					"throws if the enum value is incorrect",
					function()
						assert.has_errors(
							function()
								Classes.match(ENUM, strategies)("1")
							end
						)
					end
				)

				it(
					"throws if the strategies don't match the enum",
					function()
						assert.has_errors(
							function()
								Classes.match(ENUM, {})
							end
						)

						assert.has_errors(
							function()
								Classes.match(Classes.enum({"FOUR"}), strategies)
							end
						)
					end
				)
			end
		)
	end
)
