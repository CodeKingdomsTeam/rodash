#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

if [ -n "$(git status --porcelain)" ]; then 
	echo "There are uncommitted changes in the work directory - this would prevent the code style check from working"
	exit 1
fi

./format.sh

if [ -n "$(git status --porcelain)" ]; then 
	echo "The code style is invalid in the following files (run format.sh before committing):"
	git status
	exit 1
fi