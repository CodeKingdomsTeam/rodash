#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

export PATH="$PWD/lua_install/bin:$PATH"

if [ $# -eq 0 ]
then
	luacheck lib spec
else
	luacheck "$@"
fi

