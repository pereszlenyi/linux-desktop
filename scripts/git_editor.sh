#!/bin/bash

# This script is a wrapper for defining the default Git editor.

EDITOR=/usr/bin/geany

function die {
	echo -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

[ -x "$EDITOR" ] || die "'$EDITOR' doesn't exist or it's not executable."

$EDITOR "$@" &>/dev/null || \
die "'$EDITOR' exited with error."
