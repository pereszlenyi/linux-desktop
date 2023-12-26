#!/bin/bash

# This script asks a yes-no question.
# It returns 0 if the answer was yes or 1 if the answer was no.
# Usage: yes_or_no.sh "Question"

ECHO=/usr/bin/echo
TR=/usr/bin/tr

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 2
}

for FILE in "$ECHO" "$TR" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

[ ! $# == 1 ] && die "Usage: $0 \"Question\""

while true; do
	read -p "$1 [yes/no]: " ANSWER
	ANSWER=$($TR "[:upper:]" "[:lower:]" <<<"$ANSWER")
	([ "$ANSWER" == "yes" ] || [ "$ANSWER" == "y" ]) && exit 0
	([ "$ANSWER" == "no" ] || [ "$ANSWER" == "n" ]) && exit 1
	$ECHO "Please type in \"y\" or \"n\"."
done
