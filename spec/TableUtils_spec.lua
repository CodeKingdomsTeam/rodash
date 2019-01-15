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
			"Merge",
			function()
				it(
					"copies fields from the source tables left to right and merges any fields in the target with the same keys",
					function()
						local target = {a = 1, b = 2, c = {x = 2, y = 3}, d = {a = 3, b = 5}, e = {f = 6, g = 7, j = 10}}
						local source1 = {a = 2, b = 3, d = 5, e = {f = 8, h = 10}}
						local source2 = {b = 4, c = 3, e = {f = 2, i = 12}}
						local result = TableUtils.Merge(target, source1, source2)
						assert.are.equal(result, target)
						assert.are.same({a = 2, b = 4, c = 3, d = 5, e = {f = 2, i = 12, g = 7, j = 10, h = 10}}, result)
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
			"Invert",
			function()
				it(
					"inverts an array",
					function()
						assert.are.same({1, 3, 4, 2}, TableUtils.Invert({1, 4, 2, 3}))
					end
				)
				it(
					"inverts a table",
					function()
						assert.are.same(
							{["1.a"] = "a", ["2.b"] = "b", ["3.c"] = "c", ["4.d"] = "d"},
							TableUtils.Invert({a = "1.a", b = "2.b", c = "3.c", d = "4.d"})
						)
					end
				)
			end
		)

		describe(
			"Includes",
			function()
				it(
					"checks array",
					function()
						assert.truthy(TableUtils.Includes({1, 4, 8, 3}, 8))
						assert.not_truthy(TableUtils.Includes({1, 4, 8, 3}, 9))
					end
				)
				it(
					"checks table",
					function()
						assert.truthy(TableUtils.Includes({a = "1.a", b = "2.b", c = "3.c", d = "4.d"}, "3.c"))
						assert.not_truthy(TableUtils.Includes({a = "1.a", b = "2.b", c = "3.c", d = "4.d"}, "3.d"))
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
			"Compact",
			function()
				it(
					"filters out falsey values from an array",
					function()
						assert.are.same({"b", "e"}, TableUtils.Compact({"b", false, false, "e", false}))
					end
				)
			end
		)
		describe(
			"KeyBy",
			function()
				it(
					"can use number keys",
					function()
						assert.are.same(
							{{name = "a", i = 1}, {name = "c", i = 2}, {name = "b", i = 3}},
							TableUtils.KeyBy(
								{{name = "a", i = 1}, {name = "b", i = 3}, {name = "c", i = 2}},
								function(obj)
									return obj.i
								end
							)
						)
					end
				)
				it(
					"can use string keys",
					function()
						assert.are.same(
							{a = {name = "a", i = 1}, c = {name = "c", i = 2}, b = {name = "b", i = 3}},
							TableUtils.KeyBy(
								{{name = "a", i = 1}, {name = "b", i = 3}, {name = "c", i = 2}},
								function(obj)
									return obj.name
								end
							)
						)
					end
				)
				it(
					"filters out nil keys",
					function()
						assert.are.same(
							{a = {name = "a", i = 1}, b = {name = "b", i = 3}},
							TableUtils.KeyBy(
								{{name = "a", i = 1}, {name = "b", i = 3}, {i = 2}},
								function(obj)
									return obj.name
								end
							)
						)
					end
				)
			end
		)
		describe(
			"GroupBy",
			function()
				it(
					"can use number keys",
					function()
						assert.are.same(
							{{{name = "a", i = 1}}, {{name = "c", i = 2}, {name = "b", i = 2}}},
							TableUtils.GroupBy(
								{{name = "a", i = 1}, {name = "c", i = 2}, {name = "b", i = 2}},
								function(obj)
									return obj.i
								end
							)
						)
					end
				)
				it(
					"can use string keys",
					function()
						assert.are.same(
							{a = {{name = "a", i = 1}}, c = {{name = "c", i = 3}, {name = "c", i = 2}}},
							TableUtils.GroupBy(
								{{name = "a", i = 1}, {name = "c", i = 3}, {name = "c", i = 2}},
								function(obj)
									return obj.name
								end
							)
						)
					end
				)
				it(
					"filters out nil keys",
					function()
						assert.are.same(
							{a = {{name = "a", i = 1}}, b = {{name = "b", i = 3}}},
							TableUtils.GroupBy(
								{{name = "a", i = 1}, {name = "b", i = 3}, {i = 2}},
								function(obj)
									return obj.name
								end
							)
						)
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
			"Keys",
			function()
				it(
					"gets the keys from a table",
					function()
						local output = TableUtils.Keys({one = "a", two = "b", three = "c", four = "d", five = "e"})
						table.sort(
							output,
							function(a, b)
								return a < b
							end
						)
						assert.are.same({"five", "four", "one", "three", "two"}, output)
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
			"Entries",
			function()
				it(
					"gets the entries from a table",
					function()
						local output = TableUtils.Entries({one = "a", two = "b", three = "c", four = "d", five = "e"})
						table.sort(
							output,
							function(a, b)
								return a[2] < b[2]
							end
						)
						assert.are.same({{"one", "a"}, {"two", "b"}, {"three", "c"}, {"four", "d"}, {"five", "e"}}, output)
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
								{one = "a", two = "b", three = "c", four = "d", five = "e"},
								function(x, i)
									return x == "d"
								end
							)
						)
					end
				)
			end
		)
		describe(
			"KeyOf",
			function()
				it(
					"gets the first matching value from a table",
					function()
						assert.are.same(4, TableUtils.KeyOf({"a", "b", "c", "d", "e"}, "d"))
					end
				)
				it(
					"returns nil for a missing value",
					function()
						assert.truthy(nil == TableUtils.KeyOf({"a", "b", "c", "d", "e"}, "f"))
					end
				)
				it(
					"gets the first matching value from a non-sequential table",
					function()
						assert.are.same("four", TableUtils.KeyOf({one = "a", two = "b", three = "c", four = "d", five = "e"}, "d"))
					end
				)
			end
		)
		describe(
			"Reduce",
			function()
				it(
					"returns the base case for an empty array",
					function()
						assert.are.same(
							"f",
							TableUtils.Reduce(
								{},
								function(prev, next)
									return prev .. next
								end,
								"f"
							)
						)
					end
				)
				it(
					"applies an iterator to reduce a table",
					function()
						assert.are.same(
							"fabcde",
							TableUtils.Reduce(
								{"a", "b", "c", "d", "e"},
								function(prev, next)
									return prev .. next
								end,
								"f"
							)
						)
					end
				)
				it(
					"can operate on the index",
					function()
						assert.are.same(
							"f1a2b3c4d5e",
							TableUtils.Reduce(
								{"a", "b", "c", "d", "e"},
								function(prev, next, i)
									return (prev or "f") .. i .. next
								end
							)
						)
					end
				)
			end
		)
		describe(
			"All",
			function()
				it(
					"returns true if the table is empty",
					function()
						assert.is_true(TableUtils.All({}))
					end
				)
				it(
					"returns true if the table contains only truthy expressions",
					function()
						assert.is_true(TableUtils.All({2, "a", true, {}}))
					end
				)
				it(
					"returns false if one expression in the input table is false",
					function()
						assert.is_false(TableUtils.All({2, "a", false, {}}))
					end
				)
				it(
					"returns true if the provided handler evaluates to true for all values in the table",
					function()
						assert.is_true(
							TableUtils.All(
								{2, 4, 6, 8},
								function(value)
									return value % 2 == 0
								end
							)
						)
					end
				)
				it(
					"returns false if the provided handler evaluates to false for any value in the table",
					function()
						assert.is_false(
							TableUtils.All(
								{2, 4, 5, 8},
								function(value)
									return value % 2 == 0
								end
							)
						)
					end
				)
			end
		)
		describe(
			"Any",
			function()
				it(
					"returns false if the table is empty",
					function()
						assert.is_false(TableUtils.Any({}))
					end
				)
				it(
					"returns false if the table contains only false expressions",
					function()
						assert.is_false(TableUtils.Any({1 == 0, false}))
					end
				)
				it(
					"returns true if one expression in the input table is true",
					function()
						assert.is_true(TableUtils.Any({1 == 0, 2 == 2}))
					end
				)
				it(
					"returns false if the provided handler evalutes to false for all values in the table",
					function()
						assert.is_false(
							TableUtils.Any(
								{1, 2, 3},
								function(value)
									return value > 3
								end
							)
						)
					end
				)
				it(
					"returns true if one expression in the input table is true",
					function()
						assert.is_true(
							TableUtils.Any(
								{1, 2, 3, 4},
								function(value)
									return value > 3
								end
							)
						)
					end
				)
			end
		)
	end
)
