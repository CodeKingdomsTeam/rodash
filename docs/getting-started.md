To understand how Rodash can be helpful in your game, here is an example code snippet which periodically prints the names of players online. We'll simplify it by using Rodash functions:

```lua
spawn(function()
	while true do
		local playerNames = {}
		for player in pairs(game.Players:GetChildren()) do
			table.insert(playerNames, player.Name)
		end
		local nameList = table.concat(playerNames, ",")
		print(string.format("Players online = %s: %s"), #playerNames, nameList)
		wait(1)
	end
end)
```

Running a piece of code periodically is simplest with `rd.setInterval`:

```lua
local rd = require(game.ReplicatedStorage.Rodash)

rd.setInterval(function()
	local playerNames = {}
	for player in pairs(game.Players:GetChildren()) do
		table.insert(playerNames, player.Name)
	end
	local nameList = table.concat(playerNames, ",")
	print(string.format("Players online = %s: %s"), #playerNames, nameList)
end)
```

You can also cancel an interval when you need to, or use rd.setTimeout if you want to run a function after a delay that you can cancel.

A cleaner way to get the player names from the list of players is using `map`:

```lua
local rd = require(game.ReplicatedStorage.Rodash)

rd.setInterval(function()
	local playerNames = rd.map(game.Players:GetChildren(), function( name )
		return player.Name
	end)
	local nameList = table.concat(playerNames, ",")
	print(string.format("Players online = %s: %s"), #playerNames, nameList)
end)
```

Rodash has lots of different methods to operate on tables and arrays. Some other examples are rd.filter, rd.find, rd.groupBy and rd.slice.

You can use common functions which act on a subject by using rd.fn, or you can make your own using rd.chain:

```lua
local rd = require(game.ReplicatedStorage.Rodash)
local fn = rd.fn

rd.setInterval(function()
	local playerNames = rd.map(game.Players:GetChildren(), fn:get("Name"))
	local nameList = table.concat(playerNames, ",")
	print(string.format("Players online = %s: %s"), #playerNames, nameList)
end, 1)
```

It's often useful to separate functions from the data they act on as these can be used in multiple ways. We can make getting the names of some objects a more general function and then call it on the players:

```lua
local rd = require(game.ReplicatedStorage.Rodash)
local fn = rd.fn

rd.setInterval(function()
	local getNames = fn:map(fn:get("Name"))
	local playerNames = getNames(game.Players:GetChildren())
	local nameList = table.concat(playerNames, ",")
	print(string.format("Players online = %s: %s"), #playerNames, nameList)
end, 1)
```

Rodash rd.format and rd.pretty can be used to quickly print values that you need from Lua. Here, we can quickly get the length of the playerNames array, and then print the array:

```lua
local rd = require(game.ReplicatedStorage.Rodash)
local fn = rd.fn

rd.setInterval(function()
	local getNames = fn:map(fn:get("Name"))
	local playerNames = getNames(game.Players:GetChildren())
	print(rd.format("Players online = {#}: {1:#?}", playerNames))
end, 1)
```

For example, this might print `Players online = 1: {"builderman"}` every second.
