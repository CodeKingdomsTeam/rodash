#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

export PATH="$PWD/lua_install/bin:$PATH"

busted --helper testInit.lua -m 'modules/?/lib/t.lua' -m './lib/?.lua' spec "$@"