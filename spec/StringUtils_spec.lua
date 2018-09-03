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
	end
)
