#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

export PATH="$PWD/lua_install/bin:$PATH"

luacheck lib spec