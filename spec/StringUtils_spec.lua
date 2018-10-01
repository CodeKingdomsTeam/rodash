local StringUtils = require "StringUtils"

describe(
	"StringUtils",
	function()
		describe(
			"Split",
			function()
				it(
					"splits",
					function()
						local x = "hi guys"

						assert.are.same({"hi", "guys"}, StringUtils.Split(x, " "))
					end
				)
				it(
					"splits with empty delimiter",
					function()
						local x = "hi guys"

						assert.are.same({"h", "i", " ", "g", "u", "y", "s"}, StringUtils.Split(x))
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

						assert.are.same("hi guys", StringUtils.Trim(x))
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

						assert.True(StringUtils.StartsWith(x, "rob"))
						assert.False(StringUtils.StartsWith(x, "x"))
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

						assert.False(StringUtils.EndsWith(x, "rob"))
						assert.True(StringUtils.EndsWith(x, "x"))
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
						assert.are.same("    nice", StringUtils.LeftPad("nice", 8))
					end
				)
				it(
					"doesn't add extra if string is too long",
					function()
						assert.are.same("nice", StringUtils.LeftPad("nice", 2))
					end
				)
				it(
					"pads with different character",
					function()
						assert.are.same("00000nice", StringUtils.LeftPad("nice", 9, "0"))
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
						assert.are.same("nice    ", StringUtils.RightPad("nice", 8))
					end
				)
				it(
					"doesn't add extra if string is too long",
					function()
						assert.are.same("nice", StringUtils.RightPad("nice", 2))
					end
				)
				it(
					"pads with different character",
					function()
						assert.are.same("nice00000", StringUtils.RightPad("nice", 9, "0"))
					end
				)
			end
		)
	end
)
