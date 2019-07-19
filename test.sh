#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

export PATH="$PWD/lua_install/bin:$PATH"

if [ -n "${DEBUG:-}" ]
then
	echo "Testing with debug mode..."
fi

set -o xtrace
busted --helper tools/testInit.lua -Xhelper "${DEBUG:+debug}" -m 'modules/?/lib/t.lua' -m 'modules/?/lib/init.lua' -m './lib/?.lua' -m './src/?.lua' -p "%.spec" spec ${COVERAGE:-} "$@"

if [ -n "${COVERAGE:-}" ]
then
	echo "Generating coverage..."
	./lua_install/bin/luacov-cobertura -o cobertura-coverage.xml
	sed -i.bak -E "s%<sources/>%<sources><source>$(pwd)</source></sources>%p" cobertura-coverage.xml
	rm cobertura-coverage.xml.bak
fi