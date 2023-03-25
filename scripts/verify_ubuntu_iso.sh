#!/bin/bash

# This script verifies a downloaded Ubuntu image.
# Usage: verify_ubuntu_iso.sh image_filename

ECHO=/usr/bin/echo
GPG=/usr/bin/gpg
GREP=/usr/bin/grep
CUT=/usr/bin/cut
SHA256SUM=/usr/bin/sha256sum

function die {
	$ECHO "Error: $1"
	exit 1
}

for FILE in "$ECHO" "$GPG" "$GREP" "$CUT" "$SHA256SUM" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or not executable."
done

[ ! $# == 1 ] && die "Usage: $0 image_filename"

DIR=$(dirname "$1")
cd $DIR || die "Can't enter $DIR."

IMAGE_FILE=$(basename "$1")

for FILE in "$IMAGE_FILE" SHA256SUMS SHA256SUMS.gpg; do
	[ -r "./${FILE}" ] || die "'$FILE' doesn't exist or not readable."
done

$GPG --batch --keyid-format long --verify ./SHA256SUMS.gpg ./SHA256SUMS || \
die "Signature of the checksum file is bad."

OFFICIAL_CHECKSUM=$($GREP -F "$IMAGE_FILE" ./SHA256SUMS | $CUT -s -d " " -f 1)
[ -z "$OFFICIAL_CHECKSUM" ] && die "No checksum of '$IMAGE_FILE' in SHA256SUMS."
$ECHO "Official checksum:   '$OFFICIAL_CHECKSUM'"

CALCULATED_CHECKSUM=$($SHA256SUM "./${IMAGE_FILE}" | $CUT -s -d " " -f 1)
[ -z "$CALCULATED_CHECKSUM" ] && die "Failed to calculate the checksum of '$IMAGE_FILE'."
$ECHO "Calculated checksum: '$CALCULATED_CHECKSUM'"

[ "$OFFICIAL_CHECKSUM" == "$CALCULATED_CHECKSUM" ] || die "The checksums don't match."

$ECHO -e "\nImage '$IMAGE_FILE' was VERIFIED."
