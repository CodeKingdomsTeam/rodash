# Getting Started

## Using this documentation

If you are looking for a specific function check out the [Glossary](/rodash/glossary).

If you want to simplify your code using a specific programming concept, Rodash functions are grouped by subject:

| Subject | Description |
| --- | --- |
| [Arrays](/rodash/api/Arrays) | Functions that operate specifically on arrays |
| [Async](/rodash/api/Async) | Functions that improve the experience of working with asynchronous code in Roblox |
| [Classes](/rodash/api/Classes) | Functions that provide implementations of and functions for higher-order abstractions such as classes, enumerations and symbols |
| [Functions](/rodash/api/Functions) | Utility functions and building blocks for functional programming styles |
| [Strings](/rodash/api/Strings) | Useful functions to manipulate strings, based on similar implementations in other standard libraries |
| [Tables](/rodash/api/Tables) | Functions that operate on all kinds of Lua tables |

The documentation of functions is automatically generated from the source code using comments and type annotations. Rodash uses a complete type langauge for Lua. See the [Types page](/rodash/Types) to learn more about types in Rodash.

## Examples

To understand how Rodash can be helpful in your game, here is an example code snippet which periodically prints the names of players online. We'll simplify it by using Rodash functions:

```lua
spawn(function()
	while true do
		local playerNames = {}
		for player in pairs(game.Players:GetChildren()) do
			table.insert(playerNames, player.Name)
		end
		local nameList = table.concat(playerNames, ",")
		print(string.format("Players online = %s: %s", #playerNames, nameList))
		wait(1)
	end
end)
```

Running a piece of code periodically is simplest with `dash.setInterval`:

```lua
local dash = require(game.ReplicatedStorage.Rodash)

dash.setInterval(function()
	local playerNames = {}
	for player in pairs(game.Players:GetChildren()) do
		table.insert(playerNames, player.Name)
	end
	local nameList = table.concat(playerNames, ",")
	print(string.format("Players online = %s: %s", #playerNames, nameList))
end, 1)
```

You can also cancel an interval when you need to, or use `dash.setTimeout` if you want to run a function after a delay that you can cancel.

A cleaner way to get the player names from the list of players is using `map`:

```lua
local dash = require(game.ReplicatedStorage.Rodash)

dash.setInterval(function()
	local playerNames = dash.map(game.Players:GetChildren(), function(name)
		return player.Name
	end)
	local nameList = table.concat(playerNames, ",")
	print(string.format("Players online = %s: %s", #playerNames, nameList))
end, 1)
```

Rodash has lots of different methods to operate on tables and arrays. Some other examples are `dash.filter`, `dash.find`, `dash.groupBy` and `dash.slice`.

Rodash also has lots of primitive functions such as `dash.noop`, `dash.id`, `dash.get` and `dash.bindTail`. We can use these to simplify small functions you write all the time:

```lua
local dash = require(game.ReplicatedStorage.Rodash)

dash.setInterval(function()
	local playerNames = dash.map(game.Players:GetChildren(), dash.bindTail(dash.get, "Name"))
	local nameList = table.concat(playerNames, ",")
	print(string.format("Players online = %s: %s", #playerNames, nameList))
end, 1)
```

Here `dash.bindTail` takes `dash.get` which looks up a key (or array of keys) in an object, and returns a function which will get the "Name" property of any object passed to it. This seems unnecessary, but it's often useful to separate functions from the data they act on as the functions can then be used with different inputs.

Fortunately, we can write this much more simply. All of the Rodash functions which act on data such as `dash.map`, `dash.filter` and `dash.get` are available beneath `dash.fn` as chained functions, which means that they can be strung together in a concise way to form a function which performs the desired action on any input.

```lua
local dash = require(game.ReplicatedStorage.Rodash)
local fn = dash.fn

dash.setInterval(function()
    local getNames = fn:map(fn:get("Name"))
    local playerNames = getNames(game.Players:GetChildren())
    local nameList = table.concat(playerNames, ",")
    print(string.format("Players online = %s: %s", #playerNames, nameList))
end, 1)
```

The function `dash.format` can be used to quickly print values that you need from Lua. Specifically, format can print variables using `{}` regardless of what type they are. Here, we can quickly get the length of the playerNames array, and then print the array with `dash.pretty` using the `#?` formatter:

```lua
local dash = require(game.ReplicatedStorage.Rodash)
local fn = dash.fn

dash.setInterval(function()
	local getNames = fn:map(fn:get("Name"))
	local playerNames = getNames(game.Players:GetChildren())
	print(dash.format("Players online = {#}: {1:#?}", playerNames))
end, 1)
```

For example, this might print `Players online = 1: {"builderman"}` every second.
