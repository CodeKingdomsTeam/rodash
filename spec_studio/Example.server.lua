print("Examples of using Rodash in your project:")

local dash = require(game.ReplicatedStorage.Rodash)
local fn = dash.fn

dash.setInterval(
	function()
		local getNames = fn:map(fn:get("Name"))
		local playerNames = getNames(game.Players:GetChildren())
		print(dash.format("Players online ({#1}): {:#?}", playerNames))
	end,
	1
)

print(dash.encodeUrlComponent("https://example.com/Egg+Fried Rice!?🤷🏼‍♀️"))
