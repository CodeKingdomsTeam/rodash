local Strings = require "Strings"

describe(
	"Strings",
	function()
		describe(
			"Split",
			function()
				it(
					"splits",
					function()
						local x = "hi guys"

						assert.are.same({"hi", "guys"}, Strings.split(x, " "))
					end
				)
				it(
					"splits with empty delimiter",
					function()
						local x = "hi guys"

						assert.are.same({"h", "i", " ", "g", "u", "y", "s"}, Strings.split(x))
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
						local x = "  hi guys "

						assert.are.same("hi guys", Strings.trim(x))
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
			end
		)
	end
)
