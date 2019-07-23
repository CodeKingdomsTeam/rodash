# Setup

Clone the repo locally with `git clone git@github.com:CodeKingdomsTeam/rodash.git`.

| Name                 | Notes                                                          |
| -------------------- | -------------------------------------------------------------- |
| `setup.sh`           | Installs Lua 5.1 and dependencies locally.                     |
| `build.sh`           | Runs setup, luacheck, tests with coverage and builds the docs. |
| `test.sh`            | Run the tests.                                                 |
| `tools/buildDocs.sh` | Build the docs.                                                |
| `tools/format.sh`    | Format the code with `lua-fmt`.                                |
| `tools/luacheck.sh`  | Runs `luacheck` against all source.                            |

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
