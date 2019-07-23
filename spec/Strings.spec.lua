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
						assert.are.same("fooBar", Strings.camelCase("__FOO_BAR__"))
					end
				)
				it(
					"from kebab-case",
					function()
						assert.are.same("fooBar", Strings.camelCase("--foo-bar--"))
					end
				)
				it(
					"from normal-case",
					function()
						assert.are.same("fooBar", Strings.camelCase("Foo Bar"))
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
						assert.are.same("foo-bar", Strings.kebabCase("__FOO_BAR__"))
					end
				)
				it(
					"from kebab-case",
					function()
						assert.are.same("foo-bar", Strings.kebabCase("fooBar"))
					end
				)
				it(
					"from normal-case",
					function()
						assert.are.same("foo-bar", Strings.kebabCase(" Foo Bar "))
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
						assert.are.same("FOO_BAR", Strings.snakeCase("fooBar"))
					end
				)
				it(
					"from kebab-case",
					function()
						assert.are.same("FOO_BAR", Strings.snakeCase("--foo-bar--"))
					end
				)
				it(
					"from normal-case",
					function()
						assert.are.same("FOO_BAR", Strings.snakeCase(" Foo Bar "))
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
						assert.are.same("Hello World", Strings.titleCase("hello world"))
					end
				)
				it(
					"kebabs",
					function()
						assert.are.same("Hello-there World_visitor", Strings.titleCase("hello-there world_visitor"))
					end
				)
				it(
					"apostrophes",
					function()
						assert.are.same("Hello World's End Don’t Panic", Strings.titleCase("hello world's end don’t panic"))
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
						assert.are.same([["Hello" 'World']], Strings.unescape("&#34;Hello&quot; &apos;World&#39;"))
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
			"Split",
			function()
				it(
					"with char delimiter",
					function()
						local x = "greetings friend  of mine"

						assert.are.same({"greetings", "friend", "", "of", "mine"}, Strings.split(x, " "))
					end
				)
				it(
					"with empty delimiter",
					function()
						local x = "howdy"

						assert.are.same({"h", "o", "w", "d", "y"}, Strings.split(x))
					end
				)
				it(
					"with string delimiter",
					function()
						local x = "one::two::three"

						assert.are.same({"one", "two", "three"}, Strings.split(x, "::"))
					end
				)
			end
		)

		describe(
			"Trim",
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
			"StartsWith",
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
			"EndsWith",
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
			"LeftPad",
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
						assert.are.same(":-):-):-hi", Strings.leftPad("hi", 10, ":-)"))
					end
				)
			end
		)

		describe(
			"RightPad",
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
						assert.are.same("hi:-):-):-", Strings.rightPad("hi", 10, ":-)"))
					end
				)
			end
		)
	end
)
