#!/bin/bash

# This script helps merging remote Git branches.
# The single argument is the name of the branch passed to git merge.

ECHO="builtin echo"
GIT=/usr/bin/git
GREP=/usr/bin/grep

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

for FILE in "$GIT" "$GREP" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

# Checking for command-line parameters.
[ $# == 1 ] || die "Usage $0 name_of_the_branch"

# Checking if we are inside a Git working tree.
$GIT rev-parse --is-inside-work-tree &>/dev/null || \
die "You are not in a Git working directory."

# Checking for modified files.
[ "$($GIT status --porcelain --untracked-files=no)" == "" ] || \
die "There are modified files that are not committed."

# Checking if we are merging the branch to itself.
[ "$($GIT branch --show-current)" == "$1" ] && \
die "Source and target branches are the same."

function git_pull {
	$GIT pull --quiet --ff-only || \
	die "Failed to run git pull on branch '$($GIT branch --show-current)'."
	$GIT status --untracked-files=no | \
	$GREP --fixed-strings "Your branch is up to date with" || \
	die "Your branch '$($GIT branch --show-current)' is not in sync with the remote branch."
}

# Before merging, updates are pulled from the remotes.
git_pull && \
$GIT switch --quiet "$1" && \
git_pull && \
$GIT switch --quiet - && \
$ECHO -e "\n=== Merging branch '$1' into '$($GIT branch --show-current)' ===" && \
$GIT merge --gpg-sign --no-edit "$1" && \
$ECHO -e "\n=== Git status ===" && \
$GIT status
