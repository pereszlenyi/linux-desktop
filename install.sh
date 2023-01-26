#!/bin/bash

# Run this script to install and setup everything.

ECHO=/usr/bin/echo
SUDO=/usr/bin/sudo
DIRNAME=/usr/bin/dirname
LS=/usr/bin/ls
APTGET=/usr/bin/apt-get
ANSIBLE=/usr/bin/ansible-playbook

function die {
	$ECHO "Error: $1"
	exit 1
}

for FILE in "$ECHO" "$SUDO" "$DIRNAME" "$LS" "$APTGET" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or not executable."
done

function check_ansible {
	[ -x "$ANSIBLE" ]
}

DIR=$($DIRNAME "$0")
cd $DIR || die "Can't enter $DIR."
$LS ./update_ansible.ansible.yml ./setup.ansible.yml >/dev/null || die "Playbooks are missing."

check_ansible || ($ECHO "Installing ansible:" && $SUDO $APTGET install ansible && $ECHO "")
check_ansible || die "Ansible is not installed."

[ -z "$FULLNAME" ] && read -p "Enter your full name: " FULLNAME
[ -z "$FULLNAME" ] && die "Full name can't be empty."

[ -z "$EMAIL" ] && read -p "Enter your email: " EMAIL
[ -z "$EMAIL" ] && die "Email can't be empty."

$ECHO "Using '$FULLNAME' as full name."
$ECHO "Using '$EMAIL' as email."
$ECHO ""

$ANSIBLE ./update_ansible.ansible.yml --ask-become-pass && \
$ANSIBLE ./setup.ansible.yml --ask-become-pass --extra-vars "FULLNAME=\"$FULLNAME\" EMAIL=\"$EMAIL\"" && \
$ECHO "Install was successful." || \
die "Failed to run ansible playbooks."
