#!/bin/bash

# This script sets up GPG for the current user.
# Usage: setup_gpg.sh "Full Name" email_address@example.com

ECHO="builtin echo"
GPG=/usr/bin/gpg
GREP=/usr/bin/grep
CUT=/usr/bin/cut

UBUNTU_SIGNING_KEY="0x843938DF228D22F7B3742BC0D94AA3F0EFE21092"

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

function die_internal_error {
	die "Internal error."
}

for FILE in "$GPG" "$GREP" "$CUT" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

[ ! $# == 2 ] && die "Usage: $0 \"Full Name\" email_address@example.com"

USER_ID="$1 <$2>"

function list_secret_key {
	$GPG --list-secret-keys --with-colons "=$USER_ID"
}

if list_secret_key &>/dev/null; then
	$ECHO "GPG key for '$USER_ID' is already present. Exiting."
	exit 0
fi

$ECHO "Creating GPG key for '$USER_ID'..." && \
$GPG --batch --passphrase '' --quick-generate-key "$USER_ID" rsa4096 default 5y 2>&1 || \
die "Failed to create GPG key for '$USER_ID'."

list_secret_key &>/dev/null || die "Failed to create GPG key for '$USER_ID'."
GPGKEY=$(list_secret_key | $GREP -E "^fpr" | $CUT -s -d ":" -f 10) || die_internal_error

$ECHO "Importing Ubuntu's key..." && \
$GPG --keyid-format long --keyserver hkp://keyserver.ubuntu.com --receive-keys 2>&1 \
"$UBUNTU_SIGNING_KEY" || \
die "Failed to import Ubuntu's key."

$ECHO "Signing Ubuntu's key..." && \
$GPG --batch --yes --default-key "$GPGKEY" --sign-key "$UBUNTU_SIGNING_KEY" 2>&1 || \
die "Failed to sign Ubuntu's key."

$ECHO "GPG was set up successfully." || die_internal_error
