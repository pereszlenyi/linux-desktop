#!/bin/bash

# This script verifies a downloaded Ubuntu image.
# Usage: verify_ubuntu_iso.sh image_filename

function die {
	echo "Error: $1"
	exit 1
}

[ ! $# == 1 ] && die "Usage: $0 image_filename"

DIR=$(dirname "$1")
cd $DIR || die "Can't enter $DIR."

IMAGE_FILE=$(basename "$1")

for FILE in "$IMAGE_FILE" SHA256SUMS SHA256SUMS.gpg; do
	[ -r "./${FILE}" ] || die "'$FILE' doesn't exist or not readable."
done

gpg --batch --keyid-format long --verify ./SHA256SUMS.gpg ./SHA256SUMS || \
die "Signature of the checksum file is bad."

OFFICIAL_CHECKSUM=$(grep -F "$IMAGE_FILE" ./SHA256SUMS | cut -s -d " " -f 1)
[ -z "$OFFICIAL_CHECKSUM" ] && die "No checksum of '$IMAGE_FILE' in SHA256SUMS."
echo "Official checksum:   '$OFFICIAL_CHECKSUM'"

CALCULATED_CHECKSUM=$(sha256sum "./${IMAGE_FILE}" | cut -s -d " " -f 1)
[ -z "$CALCULATED_CHECKSUM" ] && die "Failed to calculate the checksum of '$IMAGE_FILE'."
echo "Calculated checksum: '$CALCULATED_CHECKSUM'"

[ "$OFFICIAL_CHECKSUM" == "$CALCULATED_CHECKSUM" ] || die "The checksums don't match."

echo -e "\nImage '$IMAGE_FILE' was VERIFIED."
