local Iterators = require "Iterators"
local Tables = require "Tables"

describe(
	"Iterators",
	function()
		describe(
			"getInsertionSafeIterator",
			function()
				it(
					"iterates through an array and allows insertions",
					function()
						assert.are.same(
							{10, 120, 20, 30, 140, 40, 50, 160, 60},
							Tables.map(
								Iterators.getInsertionSafeIterator({1, 3, 5}),
								function(iterator, i)
									if iterator.value % 2 == 1 then
										iterator:insertAhead(iterator.value + 1)
										iterator:insertAhead(iterator.value + 11)
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
