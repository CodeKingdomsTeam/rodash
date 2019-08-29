local Tables = require "Tables"

local function lazySequence(firstNumber, lastNumber)
	local i = 0
	return function()
		local currentNumber = firstNumber + i
		if currentNumber > lastNumber then
			return
		else
			local currentIndex = i
			i = i + 1
			return currentIndex, currentNumber
		end
	end
end

describe(
	"Tables",
	function()
		describe(
			"slice",
			function()
				it(
					"slices",
					function()
						local x = {"h", "e", "l", "l", "o"}

						assert.are.same({"h", "e", "l"}, Tables.slice(x, 1, 3))
					end
				)
			end
		)

		describe(
			"len",
			function()
				it(
					"gets length",
					function()
						local x = {"h", "e", "l", "l", "o"}

						assert.are.same(5, Tables.len(x))
					end
				)
			end
		)
		describe(
			"clone",
			function()
				it(
					"performs a shallow clone",
					function()
						local x = {"a", "b"}

						local y = Tables.clone(x)

						assert.are.same({"a", "b"}, y)

						x[1] = "c"

						assert.are.same({"a", "b"}, y)
						assert.are.same({"c", "b"}, x)
					end
				)
			end
		)
		describe(
			"assign",
			function()
				it(
					"copies fields from the source tables left to right and overwrites any fields in the target with the same keys",
					function()
						local target = {a = 1, b = 2, c = 3}
						local source1 = {a = 2, b = 3, d = 5}
						local source2 = {b = 4, e = 6}
						local result = Tables.assign(target, source1, source2)
						assert.are.equal(result, target)
						assert.are.same({a = 2, b = 4, c = 3, d = 5, e = 6}, result)
					end
				)
			end
		)
		describe(
			"merge",
			function()
				it(
					"copies fields from the source tables left to right and merges any fields in the target with the same keys",
					function()
						local target = {a = 1, b = 2, c = {x = 2, y = 3}, d = {a = 3, b = 5}, e = {f = 6, g = 7, j = 10}}
						local source1 = {a = 2, b = 3, d = 5, e = {f = 8, h = 10}}
						local source2 = {b = 4, c = 3, e = {f = 2, i = 12}}
						local result = Tables.merge(target, source1, source2)
						assert.are.equal(result, target)
						assert.are.same({a = 2, b = 4, c = 3, d = 5, e = {f = 2, i = 12, g = 7, j = 10, h = 10}}, result)
					end
				)
			end
		)
		describe(
			"isSubset",
			function()
				it(
					"returns true for two empty tables",
					function()
						assert.True(Tables.isSubset({}, {}))
					end
				)
				it(
					"returns true for an empty table and a non-empty table",
					function()
						assert.True(Tables.isSubset({}, {a = 1}))
					end
				)
				it(
					"returns false if either argument is not a table",
					function()
						assert.False(Tables.isSubset({}, 3))
					end
				)
				it(
					"returns true for nested tables whose fields are a subset of the others",
					function()
						assert.True(
							Tables.isSubset(
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
						assert.False(Tables.isSubset({a = 1, b = 2}, {a = 1}))
					end
				)
				it(
					"returns false if a field in the first argument does not equal the corresponding field in the second",
					function()
						assert.False(
							Tables.isSubset(
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
			"deepEquals",
			function()
				it(
					"returns true if the first argument deep equals the second",
					function()
						assert.True(
							Tables.deepEquals(
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
							Tables.deepEquals(
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
			"map",
			function()
				it(
					"maps keys and values of an array",
					function()
						assert.are.same(
							{"a.1", "b.2", "c.3", "d.4"},
							Tables.map(
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
							Tables.map(
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
			"mapKeys",
			function()
				it(
					"maps keys and values of an array",
					function()
						assert.are.same(
							{[2] = "a", [3] = "b", [4] = "c", [5] = "d"},
							Tables.mapKeys(
								{"a", "b", "c", "d"},
								function(x, i)
									return i + 1
								end
							)
						)
					end
				)
				it(
					"maps keys and values of a non-sequential table",
					function()
						assert.are.same(
							{a1 = 1, b2 = 2, c3 = 3, d4 = 4},
							Tables.mapKeys(
								{a = 1, b = 2, c = 3, d = 4},
								function(x, i)
									return i .. x
								end
							)
						)
					end
				)
			end
		)
		describe(
			"flatMap",
			function()
				it(
					"inline returned arrays from handler",
					function()
						assert.are.same(
							{"a", 1, "b", 2, "c", 3, "d", 4},
							Tables.flatMap(
								{"a", "b", "c", "d"},
								function(x, i)
									return {x, i}
								end
							)
						)
					end
				)
				it(
					"does not ignore falsy returns",
					function()
						assert.are.same(
							{false, false, "c", 3, "d", 4},
							Tables.flatMap(
								{"a", "b", "c", "d"},
								function(x, i)
									return i > 2 and {x, i}
								end
							)
						)
					end
				)

				it(
					"returning a truthy non-table",
					function()
						assert.are.same(
							{1, 2},
							Tables.flatMap(
								{"a", "b"},
								function(val, i)
									return i
								end
							)
						)
					end
				)

				it(
					"returning an empty table",
					function()
						assert.are.same(
							{},
							Tables.flatMap(
								{"a", "b"},
								function(val, i)
									return {}
								end
							)
						)
					end
				)

				it(
					"nested",
					function()
						assert.are.same(
							{1, 2, 1, 2},
							Tables.flatMap(
								{"a", "b"},
								function(val, i)
									local x =
										Tables.flatMap(
										{"c", "d"},
										function(val, j)
											return j
										end
									)

									return x
								end
							)
						)
					end
				)
			end
		)
		describe(
			"invert",
			function()
				it(
					"inverts an array",
					function()
						assert.are.same({1, 3, 4, 2}, Tables.invert({1, 4, 2, 3}))
					end
				)
				it(
					"inverts a table",
					function()
						assert.are.same(
							{["1.a"] = "a", ["2.b"] = "b", ["3.c"] = "c", ["4.d"] = "d"},
							Tables.invert({a = "1.a", b = "2.b", c = "3.c", d = "4.d"})
						)
					end
				)
			end
		)

		describe(
			"includes",
			function()
				it(
					"checks array",
					function()
						assert.truthy(Tables.includes({1, 4, 8, 3}, 8))
						assert.not_truthy(Tables.includes({1, 4, 8, 3}, 9))
					end
				)
				it(
					"checks table",
					function()
						assert.truthy(Tables.includes({a = "1.a", b = "2.b", c = "3.c", d = "4.d"}, "3.c"))
						assert.not_truthy(Tables.includes({a = "1.a", b = "2.b", c = "3.c", d = "4.d"}, "3.d"))
					end
				)
			end
		)

		describe(
			"Reverse",
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
			"omitBy",
			function()
				it(
					"omits keys and values of a non-sequential table",
					function()
						local output =
							Tables.omitBy(
							{one = "a", two = "b", three = "a", four = "d", five = "e"},
							function(x, i)
								return x == "b" or i == "five"
							end
						)
						assert.are.same({one = "a", three = "a", four = "d"}, output)
					end
				)
			end
		)

		describe(
			"filter",
			function()
				it(
					"filters keys and values of an array",
					function()
						assert.are.same(
							{"b", "e"},
							Tables.filter(
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
							Tables.filter(
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
				it(
					"works when passed an iterator",
					function()
						assert.are.same(
							{5, 6},
							Tables.filter(
								lazySequence(5, 10),
								function(value)
									return value < 7
								end
							)
						)
					end
				)
			end
		)
		describe(
			"filterKeys",
			function()
				it(
					"filters keys and values of a non-sequential table",
					function()
						local output =
							Tables.filterKeys(
							{one = "a", two = "b", three = "a", four = "d", five = "e"},
							function(x, i)
								return x == "b" or i == "five"
							end
						)
						assert.are.same({two = "b", five = "e"}, output)
					end
				)
			end
		)
		describe(
			"filterKeysMap",
			function()
				it(
					"filters keys and maps results of a non-sequential table",
					function()
						local output =
							Tables.filterKeysMap(
							{one = "a", two = "b", three = "a", four = "d", five = "e"},
							function(x, i)
								if x == "b" then
									return "well"
								elseif i == "five" then
									return "done"
								end
							end
						)
						assert.are.same({two = "well", five = "done"}, output)
					end
				)
			end
		)
		describe(
			"without",
			function()
				it(
					"removes elements of a specific value",
					function()
						assert.are.same({"b", "e"}, Tables.without({"a", "b", "a", "e"}, "a"))
					end
				)
			end
		)
		describe(
			"compact",
			function()
				it(
					"filters out falsey values from an array",
					function()
						assert.are.same({"b", "e"}, Tables.compact({"b", false, false, "e", false}))
					end
				)
			end
		)
		describe(
			"keyBy",
			function()
				it(
					"can use number keys",
					function()
						assert.are.same(
							{{name = "a", i = 1}, {name = "c", i = 2}, {name = "b", i = 3}},
							Tables.keyBy(
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
							Tables.keyBy(
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
							Tables.keyBy(
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
			"groupBy",
			function()
				it(
					"can use number keys",
					function()
						assert.are.same(
							{{{name = "a", i = 1}}, {{name = "c", i = 2}, {name = "b", i = 2}}},
							Tables.groupBy(
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
							Tables.groupBy(
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
							Tables.groupBy(
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
			"insertMany",
			function()
				it(
					"adds multiple values onto an array",
					function()
						local output = {"a", "b"}
						Tables.insertMany(output, {"c", "d", "e"})
						assert.are.same({"a", "b", "c", "d", "e"}, output)
					end
				)
				it(
					"adds no values onto an array",
					function()
						local output = {"a", "b"}
						Tables.insertMany(output, {})
						assert.are.same({"a", "b"}, output)
					end
				)
				it(
					"adds values onto an empty array",
					function()
						local output = {}
						Tables.insertMany(output, {"a", "b"})
						assert.are.same({"a", "b"}, output)
					end
				)
			end
		)
		describe(
			"keys",
			function()
				it(
					"gets the keys from a table",
					function()
						local output = Tables.keys({one = "a", two = "b", three = "c", four = "d", five = "e"})
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
			"values",
			function()
				it(
					"gets the values from a table",
					function()
						local output = Tables.values({one = "a", two = "b", three = "c", four = "d", five = "e"})
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
			"entries",
			function()
				it(
					"gets the entries from a table",
					function()
						local output = Tables.entries({one = "a", two = "b", three = "c", four = "d", five = "e"})
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
			"find",
			function()
				it(
					"gets the first matching value from a table",
					function()
						assert.are.same(
							"d",
							Tables.find(
								{"a", "b", "c", "d", "e"},
								function(x)
									return x == "d" or x == "e"
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
							Tables.find(
								{"a", "b", "c", "d", "e"},
								function(x, i)
									return i == 4 or i == 5
								end
							)
						)
					end
				)
				it(
					"returns nil for a missing value",
					function()
						assert.is_nil(
							Tables.find(
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
							Tables.find(
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
			"findKey",
			function()
				it(
					"gets the first matching key from a table by value",
					function()
						assert.are.same(
							4,
							Tables.findKey(
								{"a", "b", "c", "d", "e"},
								function(x)
									return x == "d" or x == "e"
								end
							)
						)
					end
				)
				it(
					"gets the first matching key from a table by key",
					function()
						assert.are.same(
							4,
							Tables.findKey(
								{"a", "b", "c", "d", "e"},
								function(x, i)
									return i == 4 or i == 5
								end
							)
						)
					end
				)
				it(
					"returns nil for a missing value",
					function()
						assert.is_nil(
							Tables.findKey(
								{"a", "b", "c", "d", "e"},
								function(x, i)
									return x == "f"
								end
							)
						)
					end
				)
				it(
					"gets the first matching key from a non-sequential table",
					function()
						assert.are.same(
							"four",
							Tables.findKey(
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
			"keyOf",
			function()
				it(
					"gets the first matching value from a table",
					function()
						assert.are.same(4, Tables.keyOf({"a", "b", "c", "d", "e"}, "d"))
					end
				)
				it(
					"returns nil for a missing value",
					function()
						assert.is_nil(Tables.keyOf({"a", "b", "c", "d", "e"}, "f"))
					end
				)
				it(
					"gets the first matching value from a non-sequential table",
					function()
						assert.are.same("four", Tables.keyOf({one = "a", two = "b", three = "c", four = "d", five = "e"}, "d"))
					end
				)
			end
		)
		describe(
			"reduce",
			function()
				it(
					"returns the base case for an empty array",
					function()
						assert.are.same(
							"f",
							Tables.reduce(
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
							Tables.reduce(
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
							Tables.reduce(
								{"a", "b", "c", "d", "e"},
								function(prev, next, i)
									return (prev or "f") .. i .. next
								end
							)
						)
					end
				)
				it(
					"works when passed an iterator",
					function()
						assert.are.same(
							15,
							Tables.reduce(
								lazySequence(1, 5),
								function(prev, next, i)
									return prev + next
								end,
								0
							)
						)
					end
				)
			end
		)
		describe(
			"all",
			function()
				it(
					"returns true if the table is empty",
					function()
						assert.is_true(Tables.all({}))
					end
				)
				it(
					"returns true if the table contains only truthy expressions",
					function()
						assert.is_true(Tables.all({2, "a", true, {}}))
					end
				)
				it(
					"returns false if one expression in the input table is false",
					function()
						assert.is_false(Tables.all({2, "a", false, {}}))
					end
				)
				it(
					"returns true if the provided handler evaluates to true for all values in the table",
					function()
						assert.is_true(
							Tables.all(
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
							Tables.all(
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
			"any",
			function()
				it(
					"returns false if the table is empty",
					function()
						assert.is_false(Tables.any({}))
					end
				)
				it(
					"returns false if the table contains only false expressions",
					function()
						assert.is_false(Tables.any({1 == 0, false}))
					end
				)
				it(
					"returns true if one expression in the input table is true",
					function()
						assert.is_true(Tables.any({1 == 0, 2 == 2}))
					end
				)
				it(
					"returns false if the provided handler evalutes to false for all values in the table",
					function()
						assert.is_false(
							Tables.any(
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
							Tables.any(
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

		describe(
			"append",
			function()
				it(
					"concatenates mixed tables and values, ignoring non-arraylike keys",
					function()
						local a = {7, 4}
						local b = 9
						local c = {[1] = 5, x = 12}

						assert.are.same({7, 4, 9, 5}, Tables.append(a, b, c))
					end
				)
			end
		)
		describe(
			"privatize",
			function()
				it(
					"changes public keys and not private ones",
					function()
						assert.are.same(
							{_1 = 1, _public = 2, _private = 3},
							Tables.privatize({[1] = 1, ["public"] = 2, ["_private"] = 3})
						)
					end
				)
			end
		)

		describe(
			"defaults",
			function()
				it(
					"assigns missing properties in order",
					function()
						local a = {foo = "bar"}
						local b = {bar = "baz", bez = "boz"}
						local c = {bez = "woz", foo = "bor", bof = "buf"}

						assert.are.same({foo = "bar", bar = "baz", bez = "boz", bof = "buf"}, Tables.defaults(a, b, c))
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
						input = {1, 3, 2},
						expected = {3, 2, 1},
						comparator = function(a, b)
							return a > b
						end,
						name = "with a comparator"
					}
				}

				for _, case in ipairs(cases) do
					it(
						case.name,
						function()
							local result = Tables.sort(case.input, case.comparator)
							assert.are.same(case.expected, result)
						end
					)
				end

				it(
					"throws if the comparator returns a bad value",
					function()
						assert.has_errors(
							function()
								Tables.sort(
									{1, 3, 2},
									function(a, b)
										return a
									end
								)
							end
						)
					end
				)
			end
		)
	end
)
