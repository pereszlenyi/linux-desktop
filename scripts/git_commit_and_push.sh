#!/bin/bash

# This script commits the staged files and pushes the changes to the remote Git repository.
# If there are any arguments then it adds those files to the staged area first.

ECHO="builtin echo"
GIT=/usr/bin/git
BASH_PROFILE=~/bash_profile.sh

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

function die_internal_error {
	die "Internal error."
}

[ -x "$GIT" ] || die "Can't find Git."

if [ -x "$BASH_PROFILE" ] ; then
	builtin shopt -s expand_aliases || die "Failed to run shopt."
	. "$BASH_PROFILE" || die "Failed to run $BASH_PROFILE."
fi

# Checking if we are inside a Git working tree.
$GIT rev-parse --is-inside-work-tree &>/dev/null || \
die "You are not in a Git working directory."

# Fetching updates from the remote repository.
$GIT fetch --quiet || \
die "Failed to connect to the remote repository."

# Checking for command line parameters.
if [ "$#" -ne 0 ] ; then
	$ECHO "=== Adding files ===" || die_internal_error
	for FILE in "$@" ; do
		# Checking if FILE is a regular file.
		[ -f "$FILE" ] || die "'$FILE' is not a regular file or it doesn't exist."
		# Checking if FILE is readable.
		[ -r "$FILE" ] || die "'$FILE' is not readable."
		$GIT add "$FILE" || die "Failed adding file '$FILE'."
		$ECHO "File '$FILE' added." || die_internal_error
	done
	$ECHO "" || die_internal_error
fi

# Committing staged files.
$ECHO "=== Commit ===" && \
if builtin type -t git_commit &>/dev/null ; then
	$ECHO "Committing using git_commit"
	git_commit
else
	$GIT commit --gpg-sign
fi || die "Git commit failed."

# Pushing to the remote repository.
$ECHO -e "\n=== Push ===" && \
$GIT push --quiet || die "Git push failed."
$ECHO "OK"

# Displaying status.
$ECHO -e "\n=== Status ===" && \
$GIT fetch --quiet && $GIT status || \
die "Git status failed."
