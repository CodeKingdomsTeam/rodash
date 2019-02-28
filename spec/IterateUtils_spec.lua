local IterateUtils = require "IterateUtils"
local TableUtils = require "TableUtils"

describe(
	"IterateUtils",
	function()
		describe(
			"getInsertIterator",
			function()
				it(
					"iterates through an array and allows insertions",
					function()
						assert.are.same(
							{10, 20, 30, 40, 50, 60},
							TableUtils.Map(
								IterateUtils.getInsertIterator({1, 3, 5}),
								function(iterator, i)
									if iterator.value % 2 == 1 then
										iterator:insert(iterator.value + 1)
									end
									return iterator.value * 10
								end
							)
						)
					end
				)
			end
		)
	end
)
