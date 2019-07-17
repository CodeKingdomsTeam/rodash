local ClassUtils = require "ClassUtils"
local TableUtils = require "TableUtils"
local t = require "t"

describe(
	"ClassUtils",
	function()
		describe(
			"makeClass",
			function()
				it(
					"makes a class with default constructor",
					function()
						local MyClass = ClassUtils.makeClass("Simple")
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
						local MyClass = ClassUtils.makeClass("Simple")
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
						local MyClass = ClassUtils.makeClass("Simple")
						local myInstance = MyClass.new()
						assert.equals("Simple", tostring(myInstance))
					end
				)
				it(
					"makes a class with a constructor",
					function()
						local MyClass =
							ClassUtils.makeClass(
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
			"makeSymbol",
			function()
				it(
					"makes a symbol which doesn't alias",
					function()
						local symbol1 = ClassUtils.makeSymbol("TEST")
						local symbol2 = ClassUtils.makeSymbol("TEST")
						assert.equals(symbol1, symbol1)
						assert.are_not.equal(symbol1, symbol2)
						assert.equals("TEST", tostring(symbol1))
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
							ClassUtils.makeClass(
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
						local MyClass = ClassUtils.makeClass("Simple")
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
							ClassUtils.makeClass(
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
						local MyClass = ClassUtils.makeClass("Simple")
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
						local MyClass = ClassUtils.makeClass("Simple")
						local MyOtherClass = ClassUtils.makeClass("Simple2")
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
			"makeClassWithInterface",
			function()
				it(
					"makes a class which constructs instances from data",
					function()
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)
						function MyClass:getAmount()
							return self._amount
						end
						local myInstance = MyClass.new({amount = 10})
						assert.equals(10, myInstance:getAmount())
					end
				)
				it(
					"throws if the data doesn't match during construction",
					function()
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							{
								amount = t.string
							}
						)
						function MyClass:getAmount()
							return self._amount
						end
						assert.errors(
							function()
								MyClass.new({amount = 10})
							end,
							[[Class Simple cannot be instantiated
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
								ClassUtils.makeClassWithInterface(
									"Simple",
									{
										amount = "lol"
									}
								)
							end,
							[[Class Simple does not have a valid interface
bad value for key amount:
	function expected, got string]]
						)
					end
				)
				it(
					"allows an instance to be passed as child",
					function()
						local MyComposite = ClassUtils.makeClass("Composite")
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							{
								child = MyComposite.isInstance
							}
						)
						local myInstance = MyClass.new({child = MyComposite.new()})
						assert.is_true(MyComposite.isInstance(myInstance._child))
					end
				)
				it(
					"allows an instance of the same class to be passed as child using a dynamic interface",
					function()
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							function(Class)
								return {
									parent = t.optional(Class.isInstance)
								}
							end
						)
						local myParent = MyClass.new()
						local myChild = MyClass.new({parent = myParent})
						assert.is_true(MyClass.isInstance(myChild._parent))
					end
				)
				it(
					"throw if an instance passed as child is of incorrect type",
					function()
						local MyComposite = ClassUtils.makeClass("Composite")
						local MyBadComposite = ClassUtils.makeClass("BadComposite")
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							{
								child = MyComposite.isInstance
							}
						)
						assert.errors(
							function()
								MyClass.new({child = MyBadComposite.new()})
							end,
							[[Class Simple cannot be instantiated
[interface] bad value for child:
	Not a Composite instance]]
						)
					end
				)
				it(
					"takes a shallow copy of the data",
					function()
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)
						function MyClass:setAmount(amount)
							self._amount = amount
						end
						local data = {amount = 10}
						local myInstance = MyClass.new(data)
						myInstance:setAmount(6)
						assert.equals(6, myInstance._amount)
						assert.equals(10, data.amount)
					end
				)
				it(
					"passes instance to init",
					function()
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)

						function MyClass:_init()
							self._nice = self:getDefaultAmount()
						end
						function MyClass:getDefaultAmount()
							return 5
						end
						function MyClass:setAmount(amount)
							self._amount = amount
						end
						local data = {amount = 10}
						local myInstance = MyClass.new(data)
						assert.equals(10, myInstance._amount)
						assert.equals(5, myInstance._nice)
					end
				)
				it(
					"extends produces correct, separate constructors",
					function()
						local MyClass =
							ClassUtils.makeClassWithInterface(
							"Simple",
							{
								amount = t.number
							}
						)

						function MyClass:_init()
							self._nice = self:getDefaultAmount()
						end

						function MyClass:getDefaultAmount()
							return 5
						end

						local MySubclass =
							MyClass:extend(
							"SubSimple",
							function(...)
								local self = MyClass.new(...)
								self._nicer = self._nice + 5
								return self
							end
						)
						local data = {amount = 10}
						local myInstance = MySubclass.new(data)
						assert.equals(5, myInstance._nice)
						assert.equals(10, myInstance._nicer)
					end
				)
			end
		)
		describe(
			"extendWithInterface",
			function()
				local function makeClass()
					local MyClass =
						ClassUtils.makeClassWithInterface(
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
						local myInstance = makeClass().new({amount = 10, subAmount = 20, verySubAmount = 30})
						assert.equals(10, myInstance._amount)
						assert.equals(20, myInstance._subAmount)
						assert.equals(30, myInstance._verySubAmount)
					end
				)

				it(
					"fails invalid types in any interface",
					function()
						assert.errors(
							function()
								makeClass().new({amount = "nope", subAmount = 20, verySubAmount = 30})
							end,
							[[Class VerySubSimple cannot be instantiated
[interface] bad value for amount:
	number expected, got string]]
						)
						assert.errors(
							function()
								makeClass().new({amount = 10, subAmount = "nope", verySubAmount = 30})
							end,
							[[Class VerySubSimple cannot be instantiated
[interface] bad value for subAmount:
	number expected, got string]]
						)
						assert.errors(
							function()
								makeClass().new({amount = 10, subAmount = 20, verySubAmount = "nope"})
							end,
							[[Class VerySubSimple cannot be instantiated
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
								makeClass().new({amount = 10, subAmount = 20, verySubAmount = 30, myBadAmount = 40})
							end,
							[[Class VerySubSimple cannot be instantiated
[interface] unexpected field 'myBadAmount']]
						)
					end
				)

				local function getClassWithComposedInterfaces(superInterfaceIsFunction, subInterfaceIsFunction)
					local superInterface = {
						amount = t.number
					}

					local MyClass =
						ClassUtils.makeClassWithInterface(
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
						assert.equals(10, myInstance._amount)
						assert.equals(20, myInstance._subAmount)
					end
				)

				it(
					"composes data and function verifiers",
					function()
						local myInstance = getClassWithComposedInterfaces(true, false).new({amount = 10, subAmount = 20})
						assert.equals(10, myInstance._amount)
						assert.equals(20, myInstance._subAmount)
					end
				)

				it(
					"composes function with data verifiers",
					function()
						local myInstance = getClassWithComposedInterfaces(false, true).new({amount = 10, subAmount = 20})
						assert.equals(10, myInstance._amount)
						assert.equals(20, myInstance._subAmount)
					end
				)
			end
		)
		describe(
			"makeEnum",
			function()
				it(
					"makes an enum from an array",
					function()
						local ENUM = ClassUtils.makeEnum({"ONE", "TWO", "THREE_YEAH"})
						assert.equals("ONE", ENUM.ONE)
						assert.equals("TWO", ENUM.TWO)
						assert.equals("THREE_YEAH", ENUM.THREE_YEAH)
					end
				)
				it(
					"warns about bad casing",
					function()
						local errorMessage = "Enum keys must be defined as upper snake case"
						assert.has_error(
							function()
								ClassUtils.makeEnum({"One"})
							end,
							errorMessage
						)
						assert.has_error(
							function()
								ClassUtils.makeEnum({"ONOE_!"})
							end,
							errorMessage
						)
						assert.has_error(
							function()
								ClassUtils.makeEnum({""})
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
								ENUM = ClassUtils.makeEnum({"ONE", "TWO", "THREE_YEAH"})
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
						local ENUM = ClassUtils.makeEnum({"ONE", "TWO", "THREE_YEAH"})
						assert.truthy(ClassUtils.isA(ENUM.ONE, ENUM))
					end
				)

				it(
					"checks an instance of a class",
					function()
						local MyClass = ClassUtils.makeClass("Simple")
						local myInstance = MyClass.new()
						assert.truthy(ClassUtils.isA(myInstance, MyClass))
						assert.not_truthy(ClassUtils.isA({}, MyClass))
						assert.not_truthy(ClassUtils.isA(MyClass, MyClass))
					end
				)
				it(
					"checks an instance of a super class",
					function()
						local MyClass = ClassUtils.makeClass("Simple")
						local MySubclass = MyClass:extend("SimpleSub")
						local myInstance = MySubclass.new()
						assert.truthy(ClassUtils.isA(myInstance, MyClass))
						assert.truthy(ClassUtils.isA(myInstance, MySubclass))
						assert.not_truthy(ClassUtils.isA({}, MyClass))
						assert.not_truthy(ClassUtils.isA(MyClass, MyClass))
						assert.truthy(ClassUtils.isA(MySubclass, MyClass))
						assert.not_truthy(ClassUtils.isA(MyClass, MySubclass))
					end
				)
			end
		)

		describe(
			"makeFinal",
			function()
				it(
					"warns about using a missing key",
					function()
						local myObject =
							ClassUtils.makeFinal(
							{
								a = 2
							}
						)
						assert.equals(2, myObject.a)
						assert.errors(
							function()
								return myObject.b
							end,
							"Attempt to access key b which is missing in final object"
						)
					end
				)
				it(
					"warns about assignment to an unused variable",
					function()
						local myObject =
							ClassUtils.makeFinal(
							{
								a = 2
							}
						)
						assert.errors(
							function()
								myObject.b = 2
							end,
							"Attempt to set key b on final object"
						)
					end
				)
				it(
					"allows iteration over a table",
					function()
						local myObject =
							ClassUtils.makeFinal(
							{
								a = 2,
								b = 3
							}
						)
						assert.are.same({2, 3}, TableUtils.values(myObject))
					end
				)
			end
		)

		describe(
			"applySwitchStrategyForEnum",
			function()
				local ENUM = ClassUtils.makeEnum({"ONE", "TWO"})
				local strategies = {
					ONE = function(x)
						return x + 1
					end,
					TWO = function(x)
						return x + 2
					end
				}

				it(
					"applies",
					function()
						local result = ClassUtils.applySwitchStrategyForEnum(ENUM, ENUM.ONE, strategies, 3)

						assert(result == 4)
					end
				)

				it(
					"throws if the enum is invalid",
					function()
						assert.has_errors(
							function()
								ClassUtils.applySwitchStrategyForEnum(2, ENUM.ONE, strategies)
							end
						)
					end
				)

				it(
					"throws if the value is missing",
					function()
						assert.has_errors(
							function()
								ClassUtils.applySwitchStrategyForEnum(ENUM, "1", strategies)
							end
						)
					end
				)

				it(
					"throws if the strategies don't match the enum",
					function()
						assert.has_errors(
							function()
								ClassUtils.applySwitchStrategyForEnum(ENUM, ENUM.ONE, {})
							end
						)

						assert.has_errors(
							function()
								ClassUtils.applySwitchStrategyForEnum(ClassUtils.makeEnum({"FOUR"}), ENUM.ONE, strategies)
							end
						)
					end
				)
			end
		)
	end
)
