#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

./setup.sh

./luacheck.sh

./test.sh --verbose --coverage "$@"

luacov-console
luacov-console -s