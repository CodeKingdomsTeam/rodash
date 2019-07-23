local Strings = require "Strings"

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
			"escape",
			function()
				it(
					"characters",
					function()
						assert.are.same("&lt;a&gt;Fish &amp; Chips&lt;/a&gt;", Strings.escape("<a>Fish & Chips</a>"))
					end
				)
			end
		)

		describe(
			"unescape",
			function()
				it(
					"html entities",
					function()
						assert.are.same([["Smashed" 'Avocado']], Strings.unescape("&#34;Smashed&quot; &apos;Avocado&#39;"))
					end
				)
				it(
					"conflated ampersand",
					function()
						assert.are.same("Ampersand is &amp;", Strings.unescape("Ampersand is &#38;amp;"))
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
	end
)
