#!/bin/bash

# This script verifies a downloaded Ubuntu image.
# Usage: verify_ubuntu_iso.sh image_filename

ECHO="builtin echo"
GPG=/usr/bin/gpg
GREP=/usr/bin/grep
CUT=/usr/bin/cut
SHA256SUM=/usr/bin/sha256sum
DIRNAME=/usr/bin/dirname
BASENAME=/usr/bin/basename

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

function die_internal_error {
	die "Internal error."
}

for FILE in "$GPG" "$GREP" "$CUT" "$SHA256SUM" "$DIRNAME" "$BASENAME" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

[ ! $# == 1 ] && die "Usage: $0 image_filename"

[ -r "$1" ] || die "'$1' is not readable."
[ -f "$1" ] || die "'$1' is not a regular file."

DIR=$($DIRNAME "$1") && \
cd "$DIR" || die "Can't enter '$DIR'."

IMAGE_FILE=$($BASENAME "$1") || die_internal_error

for FILE in "$IMAGE_FILE" SHA256SUMS SHA256SUMS.gpg; do
	[ -r "./${FILE}" ] || die "'$FILE' doesn't exist or not readable."
done

$GPG --batch --keyid-format long --verify ./SHA256SUMS.gpg ./SHA256SUMS || \
die "Signature of the checksum file is bad."

OFFICIAL_CHECKSUM=$($GREP -F "$IMAGE_FILE" ./SHA256SUMS | $CUT -s -d " " -f 1)
[ -z "$OFFICIAL_CHECKSUM" ] && die "No checksum of '$IMAGE_FILE' in SHA256SUMS."
$ECHO "Official checksum:   '$OFFICIAL_CHECKSUM'" || die_internal_error

CALCULATED_CHECKSUM=$($SHA256SUM "./${IMAGE_FILE}" | $CUT -s -d " " -f 1)
[ -z "$CALCULATED_CHECKSUM" ] && die "Failed to calculate the checksum of '$IMAGE_FILE'."
$ECHO "Calculated checksum: '$CALCULATED_CHECKSUM'" || die_internal_error

[ "$OFFICIAL_CHECKSUM" == "$CALCULATED_CHECKSUM" ] || die "The checksums don't match."

$ECHO -e "\nImage '$IMAGE_FILE' was VERIFIED." || die_internal_error
