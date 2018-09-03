#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 0 ]
then
	find lib spec -name '*.lua' -exec ./node_modules/lua-fmt/dist/bin/luafmt.js --use-tabs --write-mode replace {} \;
else
	./node_modules/lua-fmt/dist/bin/luafmt.js --use-tabs --write-mode replace {} \;
fi
