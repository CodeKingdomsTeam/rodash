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
			"encodeHtml",
			function()
				it(
					"characters",
					function()
						assert.are.same(
							"Peas &lt; Bacon &gt; &quot;Fish&quot; &amp; &apos;Chips&apos;",
							Strings.encodeHtml([[Peas < Bacon > "Fish" & 'Chips']])
						)
					end
				)
			end
		)

		describe(
			"decodeHtml",
			function()
				it(
					"html entities",
					function()
						assert.are.same(
							[[<b>"Smashed"</b> 'Avocado' 😏]],
							Strings.decodeHtml("&lt;b&gt;&#34;Smashed&quot;&lt;/b&gt; &apos;Avocado&#39; &#x1F60F;")
						)
					end
				)
				it(
					"conflated ampersand",
					function()
						assert.are.same("Ampersand is &amp;", Strings.decodeHtml("Ampersand is &#38;amp;"))
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
			"charToHex",
			function()
				it(
					"encodes correctly",
					function()
						assert.equal("3C", Strings.charToHex("<"))
					end
				)
				it(
					"encodes utf8 correctly",
					function()
						assert.equal("1F60F", Strings.charToHex("😏"))
					end
				)
				it(
					"encodes utf8 correctly with formatting",
					function()
						assert.equal("0x1F60F", Strings.charToHex("😏", "0x{}"))
					end
				)
				it(
					"encodes utf8 bytes correctly",
					function()
						assert.equal("%F0%9F%A4%B7%F0%9F%8F%BC%E2%80%8D%E2%99%80%EF%B8%8F", Strings.charToHex("🤷🏼‍♀️", "%{}", true))
					end
				)
			end
		)

		describe(
			"hexToChar",
			function()
				it(
					"decodes correctly",
					function()
						assert.equal("_", Strings.hexToChar("%5F"))
					end
				)
				it(
					"throws for an invalid encoding",
					function()
						assert.throw("_", Strings.hexToChar("nope"))
					end
				)
			end
		)

		describe(
			"encodeUrlComponent",
			function()
				it(
					"encodes correctly",
					function()
						assert.equal(
							"https%3A%2F%2Fexample.com%2FEgg%2BFried%20Rice!%3F",
							Strings.encodeUrlComponent("https://example.com/Egg+Fried Rice!?")
						)
					end
				)
			end
		)
		describe(
			"encodeUrl",
			function()
				it(
					"encodes correctly",
					function()
						assert.equal("https://example.com/Egg+Fried%20Rice!?", Strings.encodeUrl("https://example.com/Egg+Fried Rice!?"))
					end
				)
			end
		)
		describe(
			"decodeUrlComponent",
			function()
				it(
					"decodes correctly",
					function()
						assert.equal(
							"https://example.com/Egg+Fried Rice!?",
							Strings.decodeUrlComponent("https%3A%2F%2Fexample.com%2FEgg%2BFried%20Rice!%3F")
						)
					end
				)
			end
		)
		describe(
			"decodeUrl",
			function()
				it(
					"decodes correctly",
					function()
						assert.equal("https://example.com/Egg+Fried Rice!?", Strings.decodeUrl("https://example.com/Egg+Fried%20Rice!?"))
					end
				)
			end
		)
		describe(
			"makeQueryString",
			function()
				it(
					"makes query",
					function()
						assert.equal(
							"?biscuits=hobnobs&time=11&chocolatey=true",
							Strings.encodeQueryString(
								{
									time = 11,
									biscuits = "hobnobs",
									chocolatey = true
								}
							)
						)
					end
				)
			end
		)
	end
)
