local Strings = require "Strings"
local Classes = require "Classes"

describe(
	"Strings",
	function()
		describe(
			"camelCase",
			function()
				it(
					"from snake-case",
					function()
						assert.are.same("pepperoniPizza", Strings.camelCase("__PEPPERONI_PIZZA__"))
					end
				)
				it(
					"from kebab-case",
					function()
						assert.are.same("pepperoniPizza", Strings.camelCase("--pepperoni-pizza--"))
					end
				)
				it(
					"from normal-case",
					function()
						assert.are.same("pepperoniPizza", Strings.camelCase("Pepperoni Pizza"))
					end
				)
			end
		)

		describe(
			"kebabCase",
			function()
				it(
					"from snake-case",
					function()
						assert.are.same("strong-stilton", Strings.kebabCase("__STRONG_STILTON__"))
					end
				)
				it(
					"from kebab-case",
					function()
						assert.are.same("strong-stilton", Strings.kebabCase("strongStilton"))
					end
				)
				it(
					"from normal-case",
					function()
						assert.are.same("strong-stilton", Strings.kebabCase(" Strong Stilton "))
					end
				)
			end
		)

		describe(
			"snakeCase",
			function()
				it(
					"from camel-case",
					function()
						assert.are.same("SWEET_CHICKEN_CURRY", Strings.snakeCase("sweetChickenCurry"))
					end
				)
				it(
					"from kebab-case",
					function()
						assert.are.same("SWEET_CHICKEN__CURRY", Strings.snakeCase("--sweet-chicken--curry--"))
					end
				)
				it(
					"from normal-case",
					function()
						assert.are.same("SWEET_CHICKEN__CURRY", Strings.snakeCase(" Sweet Chicken  Curry "))
					end
				)
			end
		)

		describe(
			"titleCase",
			function()
				it(
					"words",
					function()
						assert.are.same("Jello World", Strings.titleCase("jello world"))
					end
				)
				it(
					"kebabs",
					function()
						assert.are.same("Yellow-jello With_sprinkles", Strings.titleCase("yellow-jello with_sprinkles"))
					end
				)
				it(
					"apostrophes",
					function()
						assert.are.same("Yellow Jello's Don’t Mellow", Strings.titleCase("yellow jello's don’t mellow"))
					end
				)
			end
		)

		describe(
			"splitByPattern",
			function()
				it(
					"with char delimiter",
					function()
						local x = "one.two::flour"

						assert.are.same({"one", "two", "", "flour"}, Strings.splitByPattern(x, "[.:]"))
					end
				)
				it(
					"with empty delimiter",
					function()
						local x = "rice"

						assert.are.same({"r", "i", "c", "e"}, Strings.splitByPattern(x))
					end
				)
				it(
					"with pattern delimiter",
					function()
						local x = "one:*two:@pea"

						assert.are.same({"one", "two", "pea"}, Strings.splitByPattern(x, ":."))
					end
				)
			end
		)

		describe(
			"trim",
			function()
				it(
					"trims from start and end",
					function()
						local x = "  greetings friend "

						assert.are.same("greetings friend", Strings.trim(x))
					end
				)
			end
		)

		describe(
			"startsWith",
			function()
				it(
					"returns correctly",
					function()
						local x = "roblox"

						assert.True(Strings.startsWith(x, "rob"))
						assert.False(Strings.startsWith(x, "x"))
					end
				)
			end
		)

		describe(
			"endsWith",
			function()
				it(
					"returns correctly",
					function()
						local x = "roblox"

						assert.False(Strings.endsWith(x, "rob"))
						assert.True(Strings.endsWith(x, "x"))
					end
				)
			end
		)

		describe(
			"leftPad",
			function()
				it(
					"repeats correctly",
					function()
						assert.are.same("    nice", Strings.leftPad("nice", 8))
					end
				)
				it(
					"doesn't add extra if string is too long",
					function()
						assert.are.same("nice", Strings.leftPad("nice", 2))
					end
				)
				it(
					"pads with different character",
					function()
						assert.are.same("00000nice", Strings.leftPad("nice", 9, "0"))
					end
				)
				it(
					"pads with a string",
					function()
						assert.are.same(":):):toast", Strings.leftPad("toast", 10, ":)"))
					end
				)
			end
		)

		describe(
			"rightPad",
			function()
				it(
					"repeats correctly",
					function()
						assert.are.same("nice    ", Strings.rightPad("nice", 8))
					end
				)
				it(
					"doesn't add extra if string is too long",
					function()
						assert.are.same("nice", Strings.rightPad("nice", 2))
					end
				)
				it(
					"pads with different character",
					function()
						assert.are.same("nice00000", Strings.rightPad("nice", 9, "0"))
					end
				)
				it(
					"pads with a string",
					function()
						assert.are.same("toast:):):", Strings.rightPad("toast", 10, ":)"))
					end
				)
			end
		)

		describe(
			"pretty",
			function()
				it(
					"works for a table",
					function()
						assert.equal("{a = 1, b = {d = 4, e = 5}, c = 3}", Strings.pretty({a = 1, c = 3, b = {d = 4, e = 5}}))
					end
				)
				it(
					"works for an array",
					function()
						assert.equal("{{1, 2}, {d = 2, e = 4}, 3}", Strings.pretty({{1, 2}, {d = 2, e = 4}, 3}))
					end
				)
				it(
					"works for other natural types",
					function()
						local result = {
							child = {
								child = {
									a = true,
									c = 'hello\\" world',
									b = function()
									end,
									child = {1, 2, 3}
								}
							}
						}
						assert(
							Strings.pretty(result):gmatch(
								'{child = {child = {a = true, b = <function: 0x[0-9a-f]+>, c = "hello\\\\\\" world", child = {1, 2, 3}}}}'
							)()
						)
					end
				)
				it(
					"works for cycles",
					function()
						local result = {a = {f = 4}, b = {id = 1}, c = 3}
						result.b.d = result
						result.d = result.b
						result.c = result.a
						assert.equal("<1>{a = <2>{f = 4}, b = <3>{d = &1, id = 1}, c = &2, d = &3}", Strings.pretty(result))
					end
				)
				it(
					"multiline works for a small table",
					function()
						assert.equal("{a = 1, b = {d = 4, e = 5}, c = 3}", Strings.pretty({a = 1, c = 3, b = {d = 4, e = 5}}, true))
					end
				)
				it(
					"multiline works for a small array",
					function()
						assert.equal("{{1, 2}, {d = 2, e = 4}, 3}", Strings.pretty({{1, 2}, {d = 2, e = 4}, 3}, true))
					end
				)
				it(
					"multiline works for other natural types",
					function()
						local result = {
							child = {
								child = {
									a = true,
									c = 'hello\\" world',
									b = function()
									end,
									child = {1, 2, 3}
								}
							}
						}
						assert.equal(
							[[{
	child = {
		child = {
			a = true,
			b = <function: 0x0000000>,
			c = "hello\\\" world",
			child = {1, 2, 3}
		}
	}
}]],
							Strings.pretty(result, true):gsub("0x[0-9a-f]+", "0x0000000")
						)
					end
				)
				it(
					"multiline works for longer cycles",
					function()
						local result = {apple = {fire = "fox"}, badger = {id = 1}, cactus = "crumpet"}
						result.badger.donkey = result
						result.donkey = result.badger
						result.cactus = result.apple
						assert.equal(
							[[<1>{
	apple = <2>{fire = "fox"},
	badger = <3>{donkey = &1, id = 1},
	cactus = &2,
	donkey = &3
}]],
							Strings.pretty(result, true)
						)
					end
				)
				it(
					"multiline works for classes and class instances",
					function()
						local Animal =
							Classes.class(
							"Animal",
							function(name)
								return {name = name}
							end
						)
						local fox = Animal.new("fox")
						local badger = Animal.new("badger")
						local donkey = Animal.new("donkey kong: revisited")
						local result = {apple = {fire = fox}, [badger] = {id = 1}, cactus = "crumpet"}
						result[badger][donkey] = result
						result[donkey] = result[badger]
						result.cactus = result.apple
						assert.equal(
							[[<1>{
	apple = <2>{fire = Animal {name = "fox"}},
	cactus = &2,
	[Animal {name = "badger"}] =
		<3>{id = 1, [Animal {name = "donkey kong: revisited"}] = &1},
	[Animal {name = "donkey kong: revisited"}] = &3
}]],
							Strings.pretty(result, true)
						)
					end
				)
			end
		)
	end
)
