#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

# Inspiration from https://github.com/LPGhatguy/lemur/blob/master/.travis.yml

git submodule sync --recursive
git submodule update --init --recursive

yarn install --frozen-lockfile --non-interactive

export LUA="lua=5.1"

# Use homebrew pip on OS X
$(which pip2.7 || which pip) install virtualenv

# Add user local bin for Jenkins
export PATH="$HOME/.local/bin:$PATH"

virtualenv tools/venv
VIRTUAL_ENV_DISABLE_PROMPT=true source tools/venv/bin/activate

$(which pip2.7 || which pip) install hererocks==0.19.0

hererocks lua_install -r^ --$LUA

export PATH="$PWD/lua_install/bin:$PATH"

ROCKS=('busted 2.0.rc12-1' 'luacov 0.13.0-1' 'luacov-console 1.1.0-1' 'luacov-cobertura 0.2-1' 'luacheck 0.22.1-1')

for ROCK in "${ROCKS[@]}"
do
	ROCKS_ARGS=($ROCK)
	if ! luarocks show "${ROCKS_ARGS[@]}" > /dev/null
	then
		luarocks install "${ROCKS_ARGS[@]}"
	fi
done

pip install pre-commit==1.8.2 mkdocs mkdocs-material
pre-commit install
