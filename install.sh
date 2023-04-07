#!/bin/bash

# Run this script to install and setup everything.
# It is only meant to work with Ubuntu.

ECHO=/usr/bin/echo
SUDO=/usr/bin/sudo
DIRNAME=/usr/bin/dirname
APTGET=/usr/bin/apt-get
ANSIBLE=/usr/bin/ansible-playbook

function die {
	$ECHO "Error: $1"
	exit 1
}

for FILE in "$ECHO" "$SUDO" "$DIRNAME" "$APTGET" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or not executable."
done

function check_ansible {
	[ -x "$ANSIBLE" ]
}

DIR=$($DIRNAME "$0")
cd $DIR || die "Can't enter $DIR."

for FILE in update_ansible.ansible.yml setup.ansible.yml ; do
	[ -r "./$FILE" ] || die "$FILE is missing or not readable."
done

for FILE in yes_or_no.sh setup_gpg.sh ; do
	[ -x "./scripts/$FILE" ] || die "'$FILE' doesn't exist or not executable."
done

$ECHO "=== Setting up your Linux system ==="
$ECHO ""

check_ansible || ($ECHO "=== Installing Ansible ===" && $SUDO $APTGET --assume-yes install ansible && $ECHO "")
check_ansible || die "Ansible is not installed."

$ECHO "The following information will be used to configure Git."
[ -z "$FULLNAME" ] && read -p "Enter your full name: " FULLNAME
[ -z "$FULLNAME" ] && die "Full name can't be empty."

[ -z "$EMAIL" ] && read -p "Enter your email: " EMAIL
[ -z "$EMAIL" ] && die "Email can't be empty."

$ECHO "Using \"$FULLNAME\" as full name."
$ECHO "Using \"$EMAIL\" as email."
$ECHO ""

$ECHO "=== Running Ansible playbooks ==="
$ANSIBLE ./update_ansible.ansible.yml --ask-become-pass && \
$ANSIBLE ./setup.ansible.yml --ask-become-pass --extra-vars "FULLNAME=\"$FULLNAME\" EMAIL=\"$EMAIL\"" && \
$ECHO "=== Install was SUCCESSFUL ===" || \
die "Failed to run Ansible playbooks."

if [ -e /var/run/reboot-required ] ; then
	$ECHO ""
	$ECHO "You have to shut down and restart WSL for the changes to take effect."
	if ./scripts/yes_or_no.sh "Do you want to shut down WSL now?" ; then
		wsl.exe --shutdown
	else
		$ECHO "To shut down WSL later, execute \"wsl.exe --shutdown\"."
	fi
fi
