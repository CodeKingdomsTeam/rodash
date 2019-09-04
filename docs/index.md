![logo](logo.png)

Rodash is a collection of functions designed to aid everyday game programming in Roblox. It borrows ideas from [lodash](https://lodash.com) in JS, some simpler functionality of [Penlight](https://github.com/stevedonovan/Penlight) and standalone helper scripts in circulation among the Roblox community.

# Usage

```lua
local _ = require(game.ReplicatedStorage.Rodash)

local function onlyLocalPlayerHasGold()

	local playersWithGold = _.filter(game.Players:GetChildren(), function( player )
		_.debug("Tools: {:#?}", player.Backpack)
		return _.some(player.Backpack:GetChildren(), _.fn:get("OreType", "Value"):endsWith("Gold") end)
	end)

	return _.shallowEqual(playersWithGold, {game.Players.LocalPlayer})

end
```

# Installation

There are currently two ways to install Rodash:

#### **Method 1. Model File (Roblox Studio)**

1. Download the _rbxm_ model from the [Github releases page](https://github.com/CodeKingdomsTeam/rodash/releases).
1. Insert the model into Studio and place it in `ReplicatedStorage`

#### **Method 2. Filesystem**

1. Clone this repo using `git clone git@github.com:CodeKingdomsTeam/rodash.git` in a suitable directory
1. Rename the `src` folder to `Rodash`
1. Use [rojo](https://github.com/LPGhatguy/rojo) to sync the files into a place

#### Importing

If you prefer not to reuse `_`, you can also import the library under a different name, or just import a specific module:

```
local _r = require(game.ReplicatedStorage.Rodash)

local Tables = require(game.ReplicatedStorage.Rodash.Tables)
```

# Design Principles

The Rodash design principles make it quick and easy to use the library to write concise operations, or incrementally simplify existing Roblox code.

Functions:

- **Avoid abstractions**, working on native lua types to avoid enforcing specific coding styles
- **Only do one thing** by avoiding parameter overloading or flags
- **Enforce type safety** to avoid silent error propagation
- **Prefer immutability** to promote functional design and reduce race conditions
- **Avoid duplication**, mimicking existing functionality or aliasing other functions
- **Maintain backwards compatibility** with older versions of the library

# Discussion

If you have any queries or feedback, please [join the discussion](https://discord.gg/PyaNeN5) on the Studio+ discord server!
