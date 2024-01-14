#!/bin/bash

# This script hashes all the files in a given directory and prints the checksums to a file.
# Usage: hash_directory_contents.sh input_directory output_file

ECHO="builtin echo"
DIRNAME=/usr/bin/dirname
TOUCH=/usr/bin/touch
RM=/usr/bin/rm
REALPATH=/usr/bin/realpath
WC=/usr/bin/wc
GREP=/usr/bin/grep
FIND=/usr/bin/find
SORT=/usr/bin/sort
SHA_SUM=/usr/bin/sha512sum
CUT=/usr/bin/cut
HOSTNAME_CMD=/usr/bin/hostname
DATE=/usr/bin/date
DIALOG=/usr/bin/dialog
CLEAR=/usr/bin/clear

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

function die_internal_error {
	die "Internal error."
}

for FILE in "$DIRNAME" "$TOUCH" "$RM" "$REALPATH" "$WC" "$GREP" "$FIND" "$SORT" \
	"$SHA_SUM" "$CUT" "$HOSTNAME_CMD" "$DATE" "$DIALOG" "$CLEAR"
do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

# Checking for command-line parameters.
[ $# == 2 ] || die "Usage: $0 input_directory output_file"

# Checking the input directory.
[ -d "$1" ] || die "'$1' is not a directory."
[ -r "$1" ] && [ -x "$1" ] || die "'$1' is not readable."
INPUT_DIRECTORY="$($REALPATH $1)" || die_internal_error

# Confirming to overwrite the output file, if exists.
if [ -e "$2" ] ; then
	YES_OR_NO="$($DIRNAME $0)/yes_or_no.sh" || die_internal_error
	[ -x "$YES_OR_NO" ] || die "'$YES_OR_NO' doesn't exist or it's not executable."
	$YES_OR_NO "'$2' already exists. Do you want to replace it?" || \
	die "Aborting."
fi

OUTPUT_FILE="$($REALPATH $2)" || die_internal_error

# Checking if the output file is writable.
$TOUCH "$OUTPUT_FILE" && \
$RM "$OUTPUT_FILE" && \
[ ! -e "$OUTPUT_FILE" ] || \
die "Unable to create file '$OUTPUT_FILE'."

$GREP --extended-regexp "^${INPUT_DIRECTORY}" <<<"$OUTPUT_FILE" &>/dev/null && \
die "File '$OUTPUT_FILE' is inside '$INPUT_DIRECTORY'."

cd "$INPUT_DIRECTORY" || \
die "Unable to enter '$INPUT_DIRECTORY'."

$ECHO "Scanning '$INPUT_DIRECTORY'..."

DIR_CONTENTS=$($FIND -P .) || \
die "Failed to list the contents of '$INPUT_DIRECTORY'."

function filter_files {
	while IFS='' read -r LINE ; do
		[ -L "$LINE" ] && die "'$LINE' is a symbolic link."
		[ -r "$LINE" ] || die "'$LINE' is not readable."
		if [ -d "$LINE" ] ; then
			[ -x "$LINE" ] || die "Can't enter directory '$LINE'."
		elif [ -f "$LINE" ] ; then
			$GREP --extended-regexp "^\./" <<<"$LINE" || \
			die "'$LINE' is not in the correct format."
		else
			die "'$LINE' is not a directory nor a regular file."
		fi
	done <<<"$1"
}

FILES=$(filter_files "$DIR_CONTENTS") || die "Aborting."
NUMBER_OF_FILES=$($WC --lines <<<"$FILES") || die_internal_error

{
	$ECHO "Directory: '$INPUT_DIRECTORY'" && \
	$ECHO "Host: '$($HOSTNAME_CMD)'" && \
	$ECHO "Number of files: $NUMBER_OF_FILES" && \
	$ECHO -n "Date: " && \
	$DATE "+%F %T %Z" && \
	$ECHO "Checksum tool: '$SHA_SUM'" && \
	$ECHO -e "\n=== Checksums ===" ;
} >"$OUTPUT_FILE" || die_internal_error

SECONDS=0
function print_elapsed_time {
	$DATE --utc --date="@${SECONDS}" "+%T"
}

FILES_DONE=0
GAUGE_WIDTH=60
function show_progress {
	echo $(( FILES_DONE * 100 / NUMBER_OF_FILES )) | \
	$DIALOG --title "Calculating checksums" --gauge \
	"\nRoot directory: ${INPUT_DIRECTORY:0:(( GAUGE_WIDTH - 20))}\nFile: ${1:2:(( GAUGE_WIDTH - 10))}\nElapsed time: $(print_elapsed_time)" \
	10 $GAUGE_WIDTH || \
	die_internal_error
}

SORTED_FILES=$($SORT <<<"$FILES") || die_internal_error

# Calculating hashes
$CLEAR
while IFS='' read -r FILE ; do
	show_progress "$FILE"
	SHA_OUTPUT=$($SHA_SUM "$FILE") || \
	die "Failed to calculate the hash of '$FILE'."
	HASH=$($CUT --delimiter=' ' --fields=1 <<<"$SHA_OUTPUT") || \
	die "Failed to calculate the hash of '$FILE'."
	$ECHO "${FILE:2}   $HASH" >>"$OUTPUT_FILE" || die_internal_error
	(( FILES_DONE++ ))
done <<<"$SORTED_FILES"
show_progress ""

$ECHO "=== End of checksums ===" >>"$OUTPUT_FILE" || die_internal_error
$CLEAR
$ECHO "Successfully calculated the checksum of $NUMBER_OF_FILES files." && \
$ECHO "Results are written to '$OUTPUT_FILE'." || die_internal_error
