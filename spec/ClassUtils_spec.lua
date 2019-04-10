local ClassUtils = require("ClassUtils")

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
						assert.are.equal(myInstance:getFive(), 5)
					end
				)
				it(
					"provides a default toString handler",
					function()
						local MyClass = ClassUtils.makeClass("Simple")
						local myInstance = MyClass.new()
						assert.are.equal(tostring(myInstance), "Simple")
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
						assert.are.equal(myInstance:addFive(), 15)
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
						assert.are.equal(symbol1, symbol1)
						assert.are_not.equal(symbol1, symbol2)
						assert.are.equal("TEST", tostring(symbol1))
					end
				)
			end
		)
		describe(
			"extend",
			function()
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
						assert.are.equal(myInstance:getFive() + myInstance:getEight(), 13)
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
								local instance = MyClass.constructor(amount + 5)
								instance.amount = instance.amount + 23
								return instance
							end
						)
						function MySubclass:getAmount()
							return self.amount
						end

						local myInstance = MySubclass.new(2)
						assert.are.equal(myInstance:getAmount(), 30)
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
						assert.are.equal(myInstance:addFiveToMagicNumber(), 15)
						assert.are.equal(mySubInstance:addFiveToMagicNumber(), 17)
					end
				)
			end
		)
		describe(
			"makeConstructedClass",
			function()
				it(
					"makes a class which constructs instances from data",
					function()
						local MyClass = ClassUtils.makeConstructedClass("Simple")
						function MyClass:getAmount()
							return self.amount
						end
						local myInstance = MyClass.new({amount = 10})
						assert.are.equal(myInstance:getAmount(), 10)
					end
				)
				it(
					"takes a shallow copy of the data",
					function()
						local MyClass = ClassUtils.makeConstructedClass("Simple")
						function MyClass:setAmount(amount)
							self.amount = amount
						end
						local data = {amount = 10}
						local myInstance = MyClass.new(data)
						myInstance:setAmount(6)
						assert.are.equal(myInstance.amount, 6)
						assert.are.equal(data.amount, 10)
					end
				)
				it(
					"passes instance to the constructor",
					function()
						local MyClass =
							ClassUtils.makeConstructedClass(
							"Simple",
							function(self)
								self.nice = self:getDefaultAmount()
							end
						)
						function MyClass:getDefaultAmount()
							return 5
						end
						function MyClass:setAmount(amount)
							self.amount = amount
						end
						local data = {amount = 10}
						local myInstance = MyClass.new(data)
						assert.are.equal(myInstance.amount, 10)
						assert.are.equal(myInstance.nice, 5)
					end
				)
				it(
					"extends produces correct, separate constructors",
					function()
						local MyClass =
							ClassUtils.makeConstructedClass(
							"Simple",
							function(self)
								self.nice = self:getDefaultAmount()
							end
						)
						function MyClass:getDefaultAmount()
							return 5
						end
						local MySubClass =
							MyClass:extend(
							"SubSimple",
							function(self)
								MyClass.constructor(self)
								self.nicer = self.nice + 5
							end
						)
						local data = {amount = 10}
						local myInstance = MySubClass.new(data)
						assert.are.equal(5, myInstance.nice)
						assert.are.equal(10, myInstance.nicer)
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
						assert.are.equal(ENUM.ONE, "ONE")
						assert.are.equal(ENUM.TWO, "TWO")
						assert.are.equal(ENUM.THREE_YEAH, "THREE_YEAH")
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
