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

[ -x "$GIT" ] || die "Can't find Git."

if [ -x "$BASH_PROFILE" ] ; then
	builtin shopt -s expand_aliases || die "Failed to run shopt."
	. "$BASH_PROFILE" || die "Failed to run $BASH_PROFILE."
fi

# Checking for command line parameters.
if [ "$#" -ne 0 ] ; then
	$ECHO "=== Adding files ==="
	for FILE in "$@" ; do
		# Checking if FILE is a regular file.
		if [ ! -f $FILE ] ; then
			die "'$FILE' is not a regular file or it doesn't exist."
		fi
		# Checking if FILE is readable.
		if [ ! -r $FILE ] ; then
			die "'$FILE' is not readable."
		fi
		$GIT add "$FILE" || die "Failed adding file '$FILE'."
		$ECHO "File '$FILE' added."
	done
	$ECHO ""
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
