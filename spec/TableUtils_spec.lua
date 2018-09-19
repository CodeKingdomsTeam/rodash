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
			"Assign",
			function()
				it(
					"copies fields from the source tables left to right and overwrites any fields in the target with the same keys",
					function()
						local target = {a = 1, b = 2, c = 3}
						local source1 = {a = 2, b = 3, d = 5}
						local source2 = {b = 4, e = 6}
						local result = TableUtils.Assign(target, source1, source2)
						assert.are.equal(result, target)
						assert.are.same({a = 2, b = 4, c = 3, d = 5, e = 6}, result)
					end
				)
			end
		)
		describe(
			"IsSubset",
			function()
				it(
					"returns true for two empty tables",
					function()
						assert.True(TableUtils.IsSubset({}, {}))
					end
				)
				it(
					"returns true for an empty table and a non-empty table",
					function()
						assert.True(TableUtils.IsSubset({}, {a = 1}))
					end
				)
				it(
					"returns false if either argument is not a table",
					function()
						assert.False(TableUtils.IsSubset({}, 3))
					end
				)
				it(
					"returns true for nested tables whose fields are a subset of the others",
					function()
						assert.True(
							TableUtils.IsSubset(
								{
									a = 1,
									b = 2,
									c = {
										d = 3,
										e = {
											f = 4
										}
									}
								},
								{
									a = 1,
									b = 2,
									g = 5,
									c = {
										d = 3,
										h = 6,
										e = {
											f = 4
										}
									}
								}
							)
						)
					end
				)
				it(
					"returns false if a field that is present in the first argument is not in the second",
					function()
						assert.False(TableUtils.IsSubset({a = 1, b = 2}, {a = 1}))
					end
				)
				it(
					"returns false if a field in the first argument does not equal the corresponding field in the second",
					function()
						assert.False(
							TableUtils.IsSubset(
								{
									a = 1,
									b = {
										c = 2
									}
								},
								{
									a = 1,
									b = {
										c = 3
									}
								}
							)
						)
					end
				)
			end
		)
		describe(
			"DeepEquals",
			function()
				it(
					"returns true if the first argument deep equals the second",
					function()
						assert.True(
							TableUtils.DeepEquals(
								{
									a = 1,
									b = 2,
									c = {
										d = 3,
										e = {
											f = {
												g = {},
												h = 4
											}
										}
									}
								},
								{
									a = 1,
									b = 2,
									c = {
										d = 3,
										e = {
											f = {
												g = {},
												h = 4
											}
										}
									}
								}
							)
						)
					end
				)
				it(
					"returns false if one of the arguments has an additional field",
					function()
						assert.False(
							TableUtils.DeepEquals(
								{
									a = 1,
									b = {}
								},
								{
									a = 1,
									b = {
										c = 2
									}
								}
							)
						)
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
								function(x)
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
