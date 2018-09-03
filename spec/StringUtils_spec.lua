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
	end
)
