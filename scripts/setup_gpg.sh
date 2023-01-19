#!/bin/bash

# This script sets up GPG for the current user.
# Usage: setup_gpg.sh "Full Name" email_address@example.com

UBUNTU_SIGNING_KEY="0x843938DF228D22F7B3742BC0D94AA3F0EFE21092"

function die {
	echo "Error: $1"
	exit 1
}

[ ! $# == 2 ] && die "Usage: $0 \"Full Name\" email_address@example.com"

function list_secret_key {
	gpg --list-secret-keys --with-colons "=$1"
}

USER_ID="$1 <$2>"

if list_secret_key "$USER_ID" &>/dev/null; then
	echo "GPG key for '$USER_ID' is already present. Exiting."
	exit 0
fi

echo "Creating GPG key for '$USER_ID'..."
gpg --batch --passphrase '' --quick-generate-key "$USER_ID" rsa4096 default 5y || \
die "Failed to create GPG key for '$USER_ID'."

list_secret_key "$USER_ID" &>/dev/null || die "Failed to create GPG key for '$USER_ID'."
GPGKEY=$(list_secret_key "$USER_ID" | grep -E "^fpr" | cut -s -d ":" -f 10)

echo "Importing Ubuntu's key..."
gpg --keyid-format long --keyserver hkp://keyserver.ubuntu.com --receive-keys \
"$UBUNTU_SIGNING_KEY" || \
die "Failed to import Ubuntu's key."

echo "Signing Ubuntu's key..."
gpg --batch --yes --default-key "$GPGKEY" --sign-key "$UBUNTU_SIGNING_KEY" || \
die "Failed to sign Ubuntu's key."

echo "GPG was set up successfully."
