local Tables = require "Tables"
local Arrays = require "Arrays"

local function getIteratorForRange(firstNumber, lastNumber)
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
			"deepEqual",
			function()
				it(
					"returns true if the first argument deep equals the second",
					function()
						assert.True(
							Tables.deepEqual(
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
							Tables.deepEqual(
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
			"isArray",
			function()
				it(
					"returns true for an array",
					function()
						assert.equal(true, Tables.isArray({1, 2, 3}))
					end
				)
				it(
					"returns for a table",
					function()
						assert.equal(false, Tables.isArray({a = 1, b = 2, c = 3}))
					end
				)
				it(
					"returns for a sparse array",
					function()
						assert.equal(false, Tables.isArray({[1] = 1, [2] = 2, [4] = 3}))
					end
				)
				it(
					"returns for a sparse array definition",
					function()
						assert.equal(false, Tables.isArray({1, 2, nil, 4}))
					end
				)
				it(
					"can compact a sparse array to an array",
					function()
						assert.equal(true, Tables.isArray(Tables.compact({1, 2, nil, nil, 5})))
					end
				)
			end
		)
		describe(
			"occurrences",
			function()
				it(
					"works for a table",
					function()
						local x = {a = 1, c = 3, b = 2}
						assert.are.same({[x] = 1}, Tables.occurences(x))
					end
				)
				it(
					"works for an array",
					function()
						local x = {1, 2, 3}
						assert.are.same({[x] = 1}, Tables.occurences(x))
					end
				)
				it(
					"works for multiples and cycles",
					function()
						local thrice = {a = 1}
						local once = {d = thrice}
						local result = {b = once, c = thrice, d = thrice}
						result.a = result
						assert.are.same({[result] = 2, [thrice] = 3, [once] = 1}, Tables.occurences(result))
					end
				)
			end
		)
		describe(
			"serialize",
			function()
				it(
					"works for a table",
					function()
						assert.equal('{"a":1,"b":2,"c":3}', Tables.serialize({a = 1, c = 3, b = 2}))
					end
				)
				it(
					"works for an array",
					function()
						assert.equal("{1,2,3}", Tables.serialize({1, 2, 3}))
					end
				)
				it(
					"works for other natural types",
					function()
						local result = {
							a = true,
							c = 'hello\\" world',
							b = function()
							end,
							child = {1, 2, 3}
						}
						print(Tables.serialize(result))
						assert(
							Tables.serialize(result):gmatch(
								'{"a":true,"b":<function: 0x[0-9a-f]+>,"c":"hello\\\\\\" world","child":<table: 0x[0-9a-f]+>}'
							)()
						)
					end
				)
				it(
					"works for a cycle",
					function()
						local result = {a = 1, b = 2, c = 3}
						result.a = result
						assert(Tables.serialize(result):gmatch('{"a":<table: 0x[0-9a-f]+>,"b":2,"c":3}')())
					end
				)
			end
		)
		describe(
			"serializeDeep",
			function()
				it(
					"works for a table",
					function()
						assert.equal('{"a":1,"b":{"d":4,"e":5},"c":3}', Tables.serializeDeep({a = 1, c = 3, b = {d = 4, e = 5}}))
					end
				)
				it(
					"works for an array",
					function()
						assert.equal('{{1,2},{"d":2,"e":4},3}', Tables.serializeDeep({{1, 2}, {d = 2, e = 4}, 3}))
					end
				)
				it(
					"works for other natural types",
					function()
						local result = {
							child = {
								child = {
									a = true,
									c = 'hello\\" world',
									b = function()
									end,
									child = {1, 2, 3}
								}
							}
						}
						assert(
							Tables.serializeDeep(result):gmatch(
								'{"child":{"child":{"a":true,"b":<function: 0x[0-9a-f]+>,"c":"hello\\\\\\" world","child":{1,2,3}}}}'
							)()
						)
					end
				)
				it(
					"works for cycles",
					function()
						local result = {a = {f = 4}, b = {id = 1}, c = 3}
						result.b.d = result
						result.d = result.b
						result.c = result.a
						assert.equal('<1>{"a":<2>{"f":4},"b":<3>{"d":&1,"id":1},"c":&2,"d":&3}', Tables.serializeDeep(result))
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
			"flatMap",
			function()
				it(
					"returning a single value",
					function()
						assert.are.same(
							{1, 2},
							Tables.flatMap(
								{"a", "b"},
								function(val, i)
									return {i}
								end
							)
						)
					end
				)
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
					"can use false",
					function()
						assert.are.same(
							{false, false, "c", 3, "d", 4},
							Tables.flatMap(
								{"a", "b", "c", "d"},
								function(x, i)
									return i > 2 and {x, i} or {false}
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
											return {j}
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
								getIteratorForRange(5, 10),
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
			"without",
			function()
				it(
					"removes elements from an array",
					function()
						assert.are.same({"b", "e"}, Tables.without({"a", "b", "a", "e"}, "a"))
					end
				)
				it(
					"removes elements from a table",
					function()
						assert.are.same({"b", "e"}, Arrays.sort(Tables.without({e1 = "a", e2 = "b", e3 = "a", e4 = "e"}, "a")))
					end
				)
			end
		)
		describe(
			"compact",
			function()
				it(
					"compacts a sparse array preserving key order",
					function()
						assert.are.same(
							{"a", "b", "c"},
							Tables.compact(
								{
									[6] = "c",
									[1] = "a",
									[4] = "b"
								}
							)
						)
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
			"isEmpty",
			function()
				it(
					"returns true for an empty table",
					function()
						assert.are.same(true, Tables.isEmpty({}))
					end
				)
				it(
					"returns false for a table with keys",
					function()
						assert.are.same(false, Tables.isEmpty({a = 1}))
					end
				)
			end
		)
		describe(
			"one",
			function()
				it(
					"returns an element from an array if one exists",
					function()
						local list = {2, 3, 4}
						local value, key = Tables.one(list)
						assert.is_not_nil(value)
						assert.is_not_nil(key)
						assert.are.same(value, list[key])
					end
				)
				it(
					"returns an element from a dictionary if one exists",
					function()
						local list = {a = 2, b = 3, c = 4}
						local value, key = Tables.one(list)
						assert.is_not_nil(value)
						assert.is_not_nil(key)
						assert.are.same(value, list[key])
					end
				)
				it(
					"returns nil for an empty table",
					function()
						assert.is_nil(Tables.one({}))
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
							{"d", 4},
							{
								Tables.find(
									{"a", "b", "c", "d", "e"},
									function(x)
										return x == "d" or x == "e"
									end
								)
							}
						)
					end
				)
				it(
					"gets the first matching index from a table",
					function()
						assert.are.same(
							{"d", 4},
							{
								Tables.find(
									{"a", "b", "c", "d", "e"},
									function(x, i)
										return i == 4 or i == 5
									end
								)
							}
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
							{"d", "four"},
							{
								Tables.find(
									{one = "a", two = "b", three = "c", four = "d", five = "e"},
									function(x, i)
										return x == "d"
									end
								)
							}
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
			"unique",
			function()
				it(
					"removes duplicate values from an array",
					function()
						local list = {1, 2, 3, 1, 2, 3, 6, 5, 5}
						assert.are.same({1, 2, 3, 5, 6}, Arrays.sort(Tables.unique(list)))
					end
				)
				it(
					"removes duplicate values from a table",
					function()
						local object = {bez = "woz", foo = "bor", bof = "bor"}
						assert.are.same({"bor", "woz"}, Arrays.sort(Tables.unique(object)))
					end
				)
			end
		)
	end
)
