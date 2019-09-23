# Setup

Note that you only need to follow these steps if you want to contribute to Rodash. Follow the installation instructions in the documentation if you simply want to use the library.

1. Ensure you have Git installed:

   ## Windows

   a. Git for Windows - https://gitforwindows.org/

   b. Use a Bash terminal (such as Git BASH which comes with Git for Windows) to run `sh` scripts.

   ## Mac

   Already installed!

2. Clone the repo locally with `git clone git@github.com:CodeKingdomsTeam/rodash.git`.
3. Install the OS-specific dependencies:

   ## Windows

   a. Install Python - https://www.python.org/downloads/windows/

   b. Install Yarn - https://yarnpkg.com/lang/en/docs/install/#windows-stable

   ## Mac

   ```bash
   # Install Homebrew (see https://brew.sh/)
   /usr/bin/ruby -e "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

   # Install package managers
   brew install python yarn
   ```

4. Run setup.sh

| Name                 | Notes                                                          |
| -------------------- | -------------------------------------------------------------- |
| `setup.sh`           | Installs Lua 5.1 and dependencies locally.                     |
| `build.sh`           | Runs setup, luacheck, tests with coverage and builds the docs. |
| `test.sh`            | Run the unit tests.                                            |
| `tools/buildDocs.sh` | Build the docs.                                                |
| `tools/format.sh`    | Format the code with `lua-fmt`.                                |
| `tools/luacheck.sh`  | Runs `luacheck` against all source.                            |

# Dependencies

Rodash installs a number of dependencies for managing development and builds in a few different languages & their package managers. Notable dependencies include:

* Python with pip
	* virtualenv - allows Lua 5.1 to be run in a virtual environment to prevent any clash with existing installations.
	* hererocks - installs the correct version of Lua in a local directory to avoid clash with existing installations.
	* mkdocs - allows the docs website to be generated from markdown files
	* precommit - automatically lints and formats lua code during commit
* Typescript with Yarn
	* luaparse - parses the Lua source code allowing docs to be automatically generated
	* lua-fmt - formats lua source code
* Lua with luarocks
	* busted - a unit test harness
	* luacov - a coverage tool
	* luacheck - a linter for lua

# Development

We use [Rojo](https://rojo.space/docs/0.5.x/) to test Rodash during development, and suggest the following workflow:

1. Open `Rodash.rbxlx` in Roblox Studio.
2. Run `rojo serve place.project.json`.
3. Make sure you have the Rojo plugin installed, and connect to the rojo server.
4. Test any functions in the `Example` script provided.
5. Once changes have been made, commit them and make PR to this repo.
6. Use `rojo build` to use the updated library in your own projects.

# Versioning

- We use semver
  - Major: Breaking change
  - Minor: New features that do not break the existing API
  - Patch: Fixes
- We maintain a [CHANGELOG](CHANGELOG.md)
- A branch is maintained for each previous major version so that fixes can be backported.
  - E.g. `v1`, `v2` if we are on v3
- Releases are cut from master and tagged when ready e.g. `v1.0.0`.

# Branching

- Development should always be done on a branch like `dev-some-descriptive-name`.

# Discussion

Please [join the discussion](https://discord.gg/PyaNeN5) on the Studio+ discord server!
