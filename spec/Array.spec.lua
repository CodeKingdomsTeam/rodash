local Arrays = require "Arrays"
local Tables = require "Tables"

describe(
	"Array",
	function()
		describe(
			"slice",
			function()
				it(
					"slices",
					function()
						local x = {"h", "e", "l", "l", "o"}

						assert.are.same({"h", "e", "l"}, Arrays.slice(x, 1, 3))
					end
				)
				it(
					"slices with gap",
					function()
						local x = {"h", "e", "l", "l", "o"}

						assert.are.same({"h", "l", "o"}, Arrays.slice(x, 1, 5, 2))
					end
				)
			end
		)
		describe(
			"first",
			function()
				it(
					"works for no handler",
					function()
						local x = {20, 30, 40, 10}
						assert.are.same({20, 1}, {Arrays.first(x)})
					end
				)
				it(
					"works for a simple handler",
					function()
						local x = {20, 30, 40, 10}
						assert.are.same(
							{30, 2},
							{
								Arrays.first(
									x,
									function(value)
										return value > 25
									end
								)
							}
						)
					end
				)
				it(
					"works for a missing element",
					function()
						local x = {20, 30, 40, 10}
						assert.is_nil(
							Arrays.first(
								x,
								function(value)
									return value > 45
								end
							)
						)
					end
				)
				it(
					"works for a handler on a key",
					function()
						local x = {20, 30, 40, 10}
						assert.are.same(
							{10, 4},
							{
								Arrays.first(
									x,
									function(value, key)
										return key > 3
									end
								)
							}
						)
					end
				)
				it(
					"doesn't detect unnatural keys",
					function()
						local x = {20, nil, nil, 10}
						assert.is_nil(
							Arrays.first(
								x,
								function(value, key)
									return key > 3
								end
							)
						)
					end
				)
			end
		)

		describe(
			"last",
			function()
				it(
					"works for no handler",
					function()
						local x = {20, 30, 40, 10}
						assert.are.same({10, 4}, {Arrays.last(x)})
					end
				)
				it(
					"works for a simple handler",
					function()
						local x = {20, 30, 40, 10}
						assert.are.same(
							{40, 3},
							{
								Arrays.last(
									x,
									function(value)
										return value > 25
									end
								)
							}
						)
					end
				)
				it(
					"works for a missing element",
					function()
						local x = {20, 30, 40, 10}
						assert.is_nil(
							Arrays.last(
								x,
								function(value)
									return value > 45
								end
							)
						)
					end
				)
				it(
					"works for a handler on a key",
					function()
						local x = {20, 30, 40, 10}
						assert.are.same(
							{30, 2},
							{
								Arrays.last(
									x,
									function(value, key)
										return key < 3
									end
								)
							}
						)
					end
				)
			end
		)

		describe(
			"shuffle",
			function()
				it(
					"shuffle",
					function()
						local x = {20, 30, 40, 10}
						assert.are.same({10, 20, 30, 40}, Arrays.sort(Arrays.shuffle(x)))
					end
				)
			end
		)

		describe(
			"sort",
			function()
				local cases = {
					{
						input = {1, 3, 2},
						expected = {1, 2, 3},
						name = "with no comparator"
					},
					{
						input = {1, "mission", 3, "impossible", 2, true},
						expected = {true, 1, 2, 3, "impossible", "mission"},
						name = "elements of different types"
					},
					{
						input = {"use", "the", "force", "Luke"},
						expected = {"Luke", "force", "the", "use"},
						name = "with strings"
					},
					{
						input = {1, 3, 2},
						expected = {3, 2, 1},
						comparator = function(a, b)
							return a > b
						end,
						name = "with a comparator"
					},
					{
						input = {1, 3, 2},
						expected = {3, 2, 1},
						comparator = function(a, b)
							return b - a
						end,
						name = "with a numeric comparator"
					}
				}

				for _, case in ipairs(cases) do
					it(
						case.name,
						function()
							local result = Arrays.sort(case.input, case.comparator)
							assert.are.same(case.expected, result)
						end
					)
				end

				it(
					"throws if the comparator returns a bad value",
					function()
						assert.has_errors(
							function()
								Arrays.sort(
									{1, 3, 2},
									function(a, b)
										return "throws"
									end
								)
							end
						)
					end
				)
			end
		)

		describe(
			"reverse",
			function()
				it(
					"reverses an array",
					function()
						assert.are.same({1, 2, 3, 4, 5}, Tables.reverse({5, 4, 3, 2, 1}))
					end
				)
			end
		)

		describe(
			"append",
			function()
				it(
					"concatenates mixed tables and values, ignoring unnatural keys",
					function()
						local a = {7, 4}
						local b = 9
						local c = {[1] = 5, x = 12}

						assert.are.same({7, 4, 9, 5}, Arrays.append(a, b, c))
						assert.are.same({7, 4, 9, 5}, a)
					end
				)
				it(
					"adds no values onto an array",
					function()
						local target = {"a", "b"}
						Arrays.append(target, {})
						assert.are.same({"a", "b"}, target)
					end
				)
				it(
					"adds values onto an empty array",
					function()
						local target = {}
						Arrays.append(target, {"a", "b"})
						assert.are.same({"a", "b"}, target)
					end
				)
			end
		)
	end
)
