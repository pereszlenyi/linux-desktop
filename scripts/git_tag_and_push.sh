#!/bin/bash

# This script creates a tag and pushes it to the remote Git repository.
# The single argument is the name of the tag to create.

ECHO="builtin echo"
GIT=/usr/bin/git

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

[ -x "$GIT" ] || die "Can't find Git."

# Checking for command-line parameters.
[ $# == 1 ] || die "Usage $0 name_of_the_tag"

# Checking if we are inside a Git working tree.
$GIT rev-parse --is-inside-work-tree &>/dev/null || \
die "You are not in a Git working directory."

# Checking for modified files.
[ "$($GIT status --porcelain --untracked-files=no)" == "" ] || \
die "There are modified files that are not committed."

# Fetching updates from the remote repository.
$GIT fetch --quiet || \
die "Failed to connect to the remote repository."

$ECHO "=== Creating tag ===" && \
$GIT tag --sign "$1" || die "Git tag failed."

$ECHO -e "\n=== Showing tag details ===" && \
$GIT show --no-patch --abbrev-commit "$1" || die "Git show failed."

$ECHO -e "\n=== Pushing tag ===" && \
$GIT push --quiet origin "$1" || die "Git push failed."
$ECHO "OK"
