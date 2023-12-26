#!/bin/bash

# This script encrypts a file with a randomly generated passphrase.
# Usage: encrypt.sh file_or_folder_to_encrypt [output_file_name]

PASSWORD_LENGTH=30

ECHO=/usr/bin/echo
DIRNAME=/usr/bin/dirname
BASENAME=/usr/bin/basename
TOUCH=/usr/bin/touch
RM=/usr/bin/rm
MAKEPASSWD=/usr/bin/makepasswd
PWDIR=/usr/bin/pwd
MKDIR=/usr/bin/mkdir
SRM=/usr/bin/srm
TAR=/usr/bin/tar
REALPATH=/usr/bin/realpath
ZIP=/usr/bin/7z
WC=/usr/bin/wc
GPG=/usr/bin/gpg
MV=/usr/bin/mv
LS=/usr/bin/ls
XARGS=/usr/bin/xargs

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

for FILE in "$ECHO" "$DIRNAME" "$BASENAME" "$TOUCH" "$RM" "$MAKEPASSWD" "$PWDIR" \
	"$MKDIR" "$SRM" "$TAR" "$REALPATH" "$ZIP" "$WC" "$GPG" "$MV" "$LS" "$XARGS" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

# Checking for command-line parameters.
[ $# == 1 ] || [ $# == 2 ] || die "Usage: $0 file_or_folder_to_encrypt [output_file_name]"

# Checking if the input file or folder is readable.
[ -r "$1" ] || die "'$1' doesn't exist or it's not readable."
INPUT_FILE="$($REALPATH $1)"

# Determining the name of the output file.
OUTPUT_FILE="$INPUT_FILE.encrypted"
if [ $# == 2 ] ; then
	OUTPUT_FILE="$2"
fi
OUTPUT_FILE="$($REALPATH $OUTPUT_FILE)"

[ "$INPUT_FILE" == "$OUTPUT_FILE" ] && die "The input and output files are the same."

# Confirming to overwrite the output file, if exists.
if [ -e $OUTPUT_FILE ] ; then
	YES_OR_NO="$($DIRNAME $0)/yes_or_no.sh"
	[ -x "$YES_OR_NO" ] || die "'$YES_OR_NO' doesn't exist or it's not executable."
	$YES_OR_NO "File '$OUTPUT_FILE' already exists. Do you want to replace it?" || \
	die "Aborting."
fi

# Checking if the output file is readable.
$TOUCH "$OUTPUT_FILE" && \
$RM "$OUTPUT_FILE" || \
die "Unable to create file '$OUTPUT_FILE'."

# Determining the name of the temporary directory.
HOME_DIR=$(/bin/bash -c "cd ; ${PWDIR}")
TEMP_DIR="$HOME_DIR/encrypt_temp_$($MAKEPASSWD --chars 10)"
[ -e "$TEMP_DIR" ] && die "Internal error: '$TEMP_DIR' exists."

# Saving the default mask.
DEFAULT_UMASK="$(umask -p)"

# Creating the password.
PASSWORD="$($MAKEPASSWD --chars $PASSWORD_LENGTH)"
((PASSWORD_LENGTH++))
[ $($WC --chars <<<$PASSWORD) -eq $PASSWORD_LENGTH ] || \
die "Unable to create password."

# Creating the temporary directory.
umask u=rwx,g=,o= && \
$MKDIR "$TEMP_DIR" || \
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

# Doing the actual work.
$ECHO -n "Running tar on '$INPUT_FILE'... " && \
cd "$($DIRNAME $INPUT_FILE)" && \
$TAR --create --file="${TEMP_DIR}/files.tar" "./$($BASENAME $INPUT_FILE)" && \
$ECHO -e -n "done.\nCompressing... " && \
cd "$TEMP_DIR" && \
$ZIP a -t7z -mx=9 ./compressed.7z ./files.tar >/dev/null && \
$ECHO -e -n "done.\nEncrypting... " && \
$DEFAULT_UMASK && \
$GPG --symmetric --no-symkey-cache --cipher-algo AES256 --passphrase-fd 0 --batch --pinentry-mode loopback \
	--output ./encrypted ./compressed.7z <<<$PASSWORD && \
$MV ./encrypted "$OUTPUT_FILE" && \
$ECHO "done." && \
delete_temp_dir && \
$ECHO -n "The generated password: " && \
$XARGS <<<$PASSWORD && \
$ECHO "The following file was created:" && \
$LS -lah "$OUTPUT_FILE" || \
die_with_cleanup "Unable to encrypt '$INPUT_FILE'."
