local TableUtils = require "TableUtils"

describe(
	"TableUtils",
	function()
		describe(
			"Slice",
			function()
				it(
					"slices",
					function()
						local x = {"h", "e", "l", "l", "o"}

						assert.are.same({"h", "e", "l"}, TableUtils.Slice(x, 1, 3))
					end
				)
			end
		)

		describe(
			"GetLength",
			function()
				it(
					"gets length",
					function()
						local x = {"h", "e", "l", "l", "o"}

						assert.are.same(5, TableUtils.GetLength(x))
					end
				)
			end
		)
		describe(
			"Clone",
			function()
				it(
					"performs a shallow clone",
					function()
						local x = {"a", "b"}

						local y = TableUtils.Clone(x)

						assert.are.same({"a", "b"}, y)

						x[1] = "c"

						assert.are.same({"a", "b"}, y)
						assert.are.same({"c", "b"}, x)
					end
				)
			end
		)
		describe(
			"Map",
			function()
				it(
					"maps keys and values of an array",
					function()
						assert.are.same(
							{"a.1", "b.2", "c.3", "d.4"},
							TableUtils.Map(
								{"a", "b", "c", "d"},
								function(x, i)
									return x .. "." .. i
								end
							)
						)
					end
				)
				it(
					"maps keys and values of a non-sequential table",
					function()
						assert.are.same(
							{a = "1.a", b = "2.b", c = "3.c", d = "4.d"},
							TableUtils.Map(
								{a = 1, b = 2, c = 3, d = 4},
								function(x, i)
									return x .. "." .. i
								end
							)
						)
					end
				)
			end
		)
		describe(
			"Filter",
			function()
				it(
					"filters keys and values of an array",
					function()
						assert.are.same(
							{"b", "e"},
							TableUtils.Filter(
								{"a", "b", "a", "d", "e"},
								function(x, i)
									return x == "b" or i == 5
								end
							)
						)
					end
				)
				it(
					"filters keys and values of a non-sequential table",
					function()
						local output =
							TableUtils.Filter(
							{one = "a", two = "b", three = "a", four = "d", five = "e"},
							function(x, i)
								return x == "b" or i == "five"
							end
						)
						table.sort(
							output,
							function(a, b)
								return a < b
							end
						)
						assert.are.same({"b", "e"}, output)
					end
				)
			end
		)
		describe(
			"InsertMany",
			function()
				it(
					"adds multiple values onto an array",
					function()
						local output = {"a", "b"}
						TableUtils.InsertMany(output, {"c", "d", "e"})
						assert.are.same({"a", "b", "c", "d", "e"}, output)
					end
				)
				it(
					"adds no values onto an array",
					function()
						local output = {"a", "b"}
						TableUtils.InsertMany(output, {})
						assert.are.same({"a", "b"}, output)
					end
				)
				it(
					"adds values onto an empty array",
					function()
						local output = {}
						TableUtils.InsertMany(output, {"a", "b"})
						assert.are.same({"a", "b"}, output)
					end
				)
			end
		)
		describe(
			"Values",
			function()
				it(
					"gets the values from a table",
					function()
						local output = TableUtils.Values({one = "a", two = "b", three = "c", four = "d", five = "e"})
						table.sort(
							output,
							function(a, b)
								return a < b
							end
						)
						assert.are.same({"a", "b", "c", "d", "e"}, output)
					end
				)
			end
		)
		describe(
			"Find",
			function()
				it(
					"gets the first matching value from a table",
					function()
						assert.are.same(
							"d",
							TableUtils.Find(
								{"a", "b", "c", "d", "e"},
								function(x, i)
									return x == "d"
								end
							)
						)
					end
				)
				it(
					"gets the first matching index from a table",
					function()
						assert.are.same(
							"d",
							TableUtils.Find(
								{"a", "b", "c", "d", "e"},
								function(x, i)
									return i == 4
								end
							)
						)
					end
				)
				it(
					"returns nil for a missing value",
					function()
						assert.truthy(
							nil ==
								TableUtils.Find(
									{"a", "b", "c", "d", "e"},
									function(x, i)
										return x == "f"
									end
								)
						)
					end
				)
				it(
					"gets the first matching value from a non-sequential table",
					function()
						assert.are.same(
							"d",
							TableUtils.Find(
								{one = "a", two = "b", three == "c", four = "d", five = "e"},
								function(x, i)
									return x == "d"
								end
							)
						)
					end
				)
			end
		)
	end
)
