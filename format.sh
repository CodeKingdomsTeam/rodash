#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

find lib spec -name '*.lua' -exec ./node_modules/lua-fmt/dist/bin/luafmt.js --use-tabs --write-mode replace {} \;