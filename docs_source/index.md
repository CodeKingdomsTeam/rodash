![logo](logo.png)

# Home

Rodash is a collection of core functions expanding the capabilities of Lua in Roblox. It borrows ideas from [lodash](https://lodash.com) in JS, some simpler functionality of [Penlight](https://github.com/stevedonovan/Penlight) and standalone helper scripts in circulation among the Roblox community.

See the [Getting Started](getting-started) page for examples of how you can use Rodash.

## Installation

## Using the latest release

1. Download the latest _rbxmx_ model from the [Github releases page](https://github.com/CodeKingdomsTeam/rodash/releases).
2. Drag the model file from your _Downloads_ folder into a Roblox Studio project.
3. Open the `Packages` folder which is created and drag `Rodash` and its siblings into `ReplicatedStorage`.

   ![ReplicatedStorage](ReplicatedStorage.png)

### Using Rojo

If you are familiar with Git and [Rojo](https://rojo.space/docs/0.5.x/) you can also clone the [Rodash repo](https://github.com/CodeKingdomsTeam/rodash/) and incorporate the dependencies from the `default.project.json` file into your own project.

## Usage

Require Rodash in any of your scripts:

```lua
local dash = require(game.ReplicatedStorage.Rodash)

local list = {"cheese"}
dash.append(list, {"nachos"}, {}, {"chillies", "bbq sauce"})
list --> {"cheese", "nachos", "chillies", "bbq sauce"}
```

If you prefer, you can alias specific Rodash functions yourself:

```lua
local dash = require(game.ReplicatedStorage.Rodash)
local append = dash.append
```


## Discussion

If you have any queries or feedback, please [join the discussion](https://discord.gg/PyaNeN5) on the Studio+ discord server!

Please report any bugs to the [Issue Tracker](https://github.com/CodeKingdomsTeam/rodash/issues).

## Design Principles

The Rodash design principles make it quick and easy to use the library to write concise operations, or incrementally simplify existing Roblox code.

Functions:

- **Avoid abstractions**, working on native lua types to avoid enforcing specific coding styles
- **Only do one thing** by avoiding parameter overloading or flags
- **Enforce type safety** to avoid silent error propagation
- **Prefer immutability** to promote functional design and reduce race conditions
- **Avoid duplication**, mimicking existing functionality or aliasing other functions
- **Maintain backwards compatibility** with older versions of the library
