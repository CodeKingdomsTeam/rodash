#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
cd ..

export PATH="lua_install/bin:$PATH"

if [ $# -eq 0 ]
then
	luacheck src spec tools
else
	luacheck "$@"
fi

