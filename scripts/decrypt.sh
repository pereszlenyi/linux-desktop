#!/bin/bash

# This script decrypts a file that was encrypted with encrypt.sh.
# Usage: decrypt.sh file_to_decrypt [destination_folder_to_decrypt_to]

ECHO=/usr/bin/echo
DIRNAME=/usr/bin/dirname
BASENAME=/usr/bin/basename
RM=/usr/bin/rm
MAKEPASSWD=/usr/bin/makepasswd
PWDIR=/usr/bin/pwd
MKDIR=/usr/bin/mkdir
SRM=/usr/bin/srm
TAR=/usr/bin/tar
REALPATH=/usr/bin/realpath
ZIP=/usr/bin/7z
GPG=/usr/bin/gpg
MV=/usr/bin/mv
LS=/usr/bin/ls
XARGS=/usr/bin/xargs
HEAD=/usr/bin/head

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

for FILE in "$ECHO" "$DIRNAME" "$BASENAME" "$RM" "$MAKEPASSWD" "$PWDIR" \
	"$MKDIR" "$SRM" "$TAR" "$REALPATH" "$ZIP" "$GPG" "$MV" "$LS" "$XARGS" "$HEAD" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

# Checking for command-line parameters.
[ $# == 1 ] || [ $# == 2 ] || die "Usage: $0 file_to_decrypt [destination_folder_to_decrypt_to]"

# Checking if the input file is readable.
[ -r "$1" ] || die "'$1' doesn't exist or it's not readable."
INPUT_FILE="$($REALPATH $1)"

# Determining the name of the destination directory.
DESTINATION_DIR="."
if [ $# == 2 ] ; then
	DESTINATION_DIR="$2"
fi
DESTINATION_DIR="$($REALPATH $DESTINATION_DIR)"

# Checking if the destination directory is writable.
[ -w "$DESTINATION_DIR" ] || die "'$DESTINATION_DIR' doesn't exist or it's not writable."

cd "$DESTINATION_DIR" || \
die "Unable to enter into '$DESTINATION_DIR'."

# Determining the name of the temporary directory.
HOME_DIR=$(/bin/bash -c "cd ; ${PWDIR}")
TEMP_DIR="$HOME_DIR/encrypt_temp_$($MAKEPASSWD --chars 10)"
[ -e "$TEMP_DIR" ] && die "Internal error: '$TEMP_DIR' exists."

# Saving the default mask.
DEFAULT_UMASK="$(umask -p)"

# Creating the temporary directory.
umask u=rwx,g=,o= && \
$MKDIR "$TEMP_DIR" && \
cd "$TEMP_DIR" || \
die "Unable to create directory '$TEMP_DIR'."

function delete_temp_dir {
	$ECHO -n "Cleaning up... "
	$SRM -rz "$TEMP_DIR"
	$ECHO "done."
}

function die_with_cleanup {
	delete_temp_dir
	die "$1"
}

function get_filename_from_tar {
	$TAR --list --file=./files.tar | \
	$HEAD -n 1 | \
	$XARGS $BASENAME || \
	die_with_cleanup "Unable to get file name from tar."
}

function ask_to_overwrite_destination {
	OUTPUT_FILE="${DESTINATION_DIR}/$(get_filename_from_tar)"
	if [ -e $OUTPUT_FILE ] ; then
		YES_OR_NO="$($DIRNAME $0)/yes_or_no.sh"
		[ -x "$YES_OR_NO" ] || die_with_cleanup "'$YES_OR_NO' doesn't exist or it's not executable."
		$YES_OR_NO "Warning: '$OUTPUT_FILE' already exists. Do you want to overwrite it?" && \
		$RM --recursive "$OUTPUT_FILE" || \
		die_with_cleanup "Aborting."
	fi
}

# Doing the actual work.
$ECHO -n "Decrypting '$INPUT_FILE'... " && \
$GPG --decrypt --no-symkey-cache --pinentry-mode ask \
	--quiet --output ./compressed.7z "$INPUT_FILE" && \
$ECHO -e -n "done.\nDecompressing... " && \
$ZIP e ./compressed.7z >/dev/null && \
$ECHO "done." && \
ask_to_overwrite_destination && \
$ECHO -n "Running tar... " && \
$DEFAULT_UMASK && \
$TAR --extract --preserve-permissions --no-same-owner --file=./files.tar && \
$MV "./$(get_filename_from_tar)" "$DESTINATION_DIR" && \
$ECHO "done." && \
delete_temp_dir && \
$ECHO "The following file/folder was created:" && \
$LS -lahd "$OUTPUT_FILE" || \
die_with_cleanup "Unable to decrypt '$INPUT_FILE'."
