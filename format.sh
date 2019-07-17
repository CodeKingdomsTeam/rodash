#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

if [ $# -eq 0 ]
then
	find src spec -name '*.lua' -exec ./node_modules/lua-fmt/dist/bin/luafmt.js --use-tabs --write-mode replace {} \;
else
	for FILE in "$@"
	do
		./node_modules/lua-fmt/dist/bin/luafmt.js --use-tabs --write-mode replace "$FILE"
	done
fi
