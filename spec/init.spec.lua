local dash = require "init"
local Clock = require "spec_source.Clock"

describe(
	"macro-level functions",
	function()
		local clock
		before_each(
			function()
				clock = Clock.setup()
				getmetatable(dash.fn).__index = function(self, key)
					return dash.chain(dash)[key]
				end
			end
		)
		after_each(
			function()
				clock:teardown()
			end
		)
		describe(
			"chain",
			function()
				it(
					"works with vanilla functions",
					function()
						local numberChain =
							dash.chain(
							{
								addN = function(list, n)
									return dash.map(
										list,
										function(element)
											return element + n
										end
									)
								end,
								sum = function(list)
									return dash.sum(list)
								end
							}
						)
						local op = numberChain:addN(2):sum()
						assert.are.same(12, op({1, 2, 3}))
					end
				)
				it(
					"works with functions using chainFn",
					function()
						local numberChain =
							dash.chain(
							{
								addN = dash.chainFn(
									function(n)
										return function(list)
											return dash.map(
												list,
												function(element)
													return element + n
												end
											)
										end
									end
								),
								sum = dash.chainFn(
									function()
										return function(list)
											return dash.sum(list)
										end
									end
								)
							}
						)
						local op = numberChain:addN(2):sum()
						assert.are.same(12, op({1, 2, 3}))
					end
				)
				it(
					"works with functions using chainFn and rodash function",
					function()
						local numberChain =
							dash.chain(
							{
								addN = dash.chainFn(
									function(n)
										return dash.fn:map(
											function(element)
												return element + n
											end
										)
									end
								),
								sum = dash.chainFn(
									function()
										return dash.fn:sum()
									end
								)
							}
						)
						local op = numberChain:addN(2):sum()
						assert.are.same(12, op({1, 2, 3}))
					end
				)
				it(
					"works with rodash functions",
					function()
						local fn =
							dash.fn:map(
							function(value)
								return value + 2
							end
						):filter(
							function(value)
								return value >= 5
							end
						):sum()
						assert.equals("fn::map::filter::sum", tostring(fn))
						assert.are.same(12, fn({1, 3, 5}))
					end
				)
				it(
					"works with custom functors built with .fn",
					function()
						local chain =
							dash.chain(
							{
								addTwo = dash.fn:map(
									function(value)
										return value + 2
									end
								),
								sumGteFive = dash.fn:filter(
									function(value)
										return value >= 5
									end
								):sum()
							}
						)
						local fn = chain:addTwo():sumGteFive()
						assert.equals("Chain::addTwo::sumGteFive", tostring(fn))
						assert.are.same(12, fn({1, 3, 5}))
					end
				)
				it(
					"works with composed functions",
					function()
						local getName = function(player)
							return player.Name
						end
						local players =
							dash.chain(
							{
								filterHurt = dash.fn:filter(
									function(player)
										return player.Health < 100
									end
								),
								filterBaggins = dash.fn:filter(dash.fn:call(getName):endsWith("Baggins"))
							}
						)
						local hurtHobbits = players:filterHurt():filterBaggins()
						local mapNames = dash.fn:map(getName)
						local filterHurtBagginsNames = dash.compose(hurtHobbits, mapNames)
						local crew = {
							{
								Name = "Frodo Baggins",
								Health = 50
							},
							{
								Name = "Bilbo Baggins",
								Health = 100
							},
							{
								Name = "Boromir",
								Health = 0
							}
						}
						assert.are.same({"Frodo Baggins"}, filterHurtBagginsNames(crew))
					end
				)
			end
		)
		describe(
			"continue",
			function()
				it(
					"works with a mix of sync and async primitives",
					function()
						local getName = function(player)
							return dash.delay(1):andThen(dash.returns(player.Name))
						end
						local players
						players =
							dash.chain(
							{
								-- Any chainable function can be used
								filter = dash.filter,
								-- A chain which evaluates a promise of the player names
								mapNames = dash.fn:map(getName):parallel(),
								filterHurt = dash.fn:filter(
									function(player)
										return player.Health < 100
									end
								),
								mapNameIf = dash.chainFn(
									function(expectedName)
										-- Methods on self work as expected
										return players:mapNames():filter(dash.fn:endsWith(expectedName))
									end
								)
							},
							dash.continue()
						)
						local filterHurtHobbitNames = players:filterHurt():mapNameIf("Baggins")
						local crew = {
							{
								Name = "Frodo Baggins",
								Health = 50
							},
							{
								Name = "Bilbo Baggins",
								Health = 100
							},
							{
								Name = "Boromir",
								Health = 0
							}
						}
						local andThen =
							spy.new(
							function(result)
								assert.are.same({"Frodo Baggins"}, result)
							end
						)
						filterHurtHobbitNames(crew):andThen(andThen)
						assert.spy(andThen).not_called()
						clock:process()
						-- Ensure that delays are set for the lookup of the hurt names
						assert.are.same({1, 1}, dash.fn:map(dash.fn:get("time"))(clock.events))
						wait(1)
						clock:process()
						-- Ensure spy called
						assert.spy(andThen).called()
					end
				)
				it(
					"rejections pass-through",
					function()
						local getName = function(player)
							return dash.delay(1):andThen(dash.throws("NoNameError"))
						end
						local players =
							dash.chain(
							{
								-- Any chainable function can be used
								filter = dash.filter,
								-- A chain which evaluates a promise of the player names
								mapNames = dash.fn:map(getName):parallel()
							},
							dash.continue()
						)
						local filterHobbitNames = players:mapNames():filter(dash.fn:endsWith("Baggins"))
						local crew = {
							{
								Name = "Frodo Baggins",
								Health = 50
							},
							{
								Name = "Bilbo Baggins",
								Health = 100
							},
							{
								Name = "Boromir",
								Health = 0
							}
						}
						local andThen =
							spy.new(
							function()
							end
						)
						local catch =
							spy.new(
							function(message)
								assert(message:find("NoNameError"))
							end
						)
						filterHobbitNames(crew):andThen(andThen):catch(catch)
						assert.spy(andThen).not_called()
						assert.spy(catch).not_called()
						clock:process()
						-- Ensure that delays are set for the lookup of the hurt names
						assert.are.same({1, 1, 1}, dash.fn:map(dash.fn:get("time"))(clock.events))
						wait(1)
						clock:process()

						assert.spy(andThen).not_called()
						assert.spy(catch).called()
					end
				)
			end
		)
		describe(
			"maybe",
			function()
				it(
					"works with methods that return nil",
					function()
						local maybeFn = dash.chain(dash, dash.maybe())
						local getName = function(player)
							return player.Name
						end
						local players =
							dash.chain(
							{
								filterHurt = dash.fn:filter(
									function(player)
										return player.Health < 100
									end
								),
								filterBaggins = dash.chainFn(
									function()
										-- Methods on self work as expected
										return dash.fn:filter(maybeFn:call(getName):endsWith("Baggins"))
									end
								)
							}
						)
						local hurtHobbits = players:filterHurt():filterBaggins()
						local mapNames = dash.fn:map(getName)
						local filterHurtBagginsNames = dash.compose(hurtHobbits, mapNames)
						local crew = {
							{
								Name = "Frodo Baggins",
								Health = 50
							},
							{
								Name = "Bilbo Baggins",
								Health = 100
							},
							{
								Health = 0
							}
						}
						assert.are.same({"Frodo Baggins"}, filterHurtBagginsNames(crew))
					end
				)
			end
		)
	end
)
