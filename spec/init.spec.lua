local _ = require "init"
local Clock = require "spec_source.Clock"

describe(
	"macro-level functions",
	function()
		local clock
		before_each(
			function()
				clock = Clock.setup()
				getmetatable(_.fn).__index = function(self, key)
					return _.chain(_)[key]
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
							_.chain(
							{
								addN = function(list, n)
									return _.map(
										list,
										function(element)
											return element + n
										end
									)
								end,
								sum = function(list)
									return _.sum(list)
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
							_.chain(
							{
								addN = _.chainFn(
									function(n)
										return function(list)
											return _.map(
												list,
												function(element)
													return element + n
												end
											)
										end
									end
								),
								sum = _.chainFn(
									function()
										return function(list)
											return _.sum(list)
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
							_.chain(
							{
								addN = _.chainFn(
									function(n)
										return _.fn:map(
											function(element)
												return element + n
											end
										)
									end
								),
								sum = _.chainFn(
									function()
										return _.fn:sum()
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
							_.fn:map(
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
							_.chain(
							{
								addTwo = _.fn:map(
									function(value)
										return value + 2
									end
								),
								sumGteFive = _.fn:filter(
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
							_.chain(
							{
								filterHurt = _.fn:filter(
									function(player)
										return player.Health < 100
									end
								),
								filterBaggins = _.fn:filter(_.fn:call(getName):endsWith("Baggins"))
							}
						)
						local hurtHobbits = players:filterHurt():filterBaggins()
						local mapNames = _.fn:map(getName)
						local filterHurtBagginsNames = _.compose(hurtHobbits, mapNames)
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
							return _.delay(1):andThen(_.returns(player.Name))
						end
						local players
						players =
							_.chain(
							{
								-- Any chainable function can be used
								filter = _.filter,
								-- A chain which evaluates a promise of the player names
								mapNames = _.fn:map(getName):parallel(),
								filterHurt = _.fn:filter(
									function(player)
										return player.Health < 100
									end
								),
								mapNameIf = _.chainFn(
									function(expectedName)
										-- Methods on self work as expected
										return players:mapNames():filter(_.fn:endsWith(expectedName))
									end
								)
							},
							_.continue()
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
						assert.are.same({1, 1}, _.fn:map(_.fn:get("time"))(clock.events))
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
							return _.delay(1):andThen(_.throws("NoNameError"))
						end
						local players
						players =
							_.chain(
							{
								-- Any chainable function can be used
								filter = _.filter,
								-- A chain which evaluates a promise of the player names
								mapNames = _.fn:map(getName):parallel()
							},
							_.continue()
						)
						local filterHobbitNames = players:mapNames():filter(_.fn:endsWith("Baggins"))
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
						assert.are.same({1, 1, 1}, _.fn:map(_.fn:get("time"))(clock.events))
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
						local maybeFn = _.chain(_, _.maybe())
						local getName = function(player)
							return player.Name
						end
						local players
						players =
							_.chain(
							{
								filterHurt = _.fn:filter(
									function(player)
										return player.Health < 100
									end
								),
								filterBaggins = _.chainFn(
									function()
										-- Methods on self work as expected
										return _.fn:filter(maybeFn:call(getName):endsWith("Baggins"))
									end
								)
							}
						)
						local hurtHobbits = players:filterHurt():filterBaggins()
						local mapNames = _.fn:map(getName)
						local filterHurtBagginsNames = _.compose(hurtHobbits, mapNames)
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
