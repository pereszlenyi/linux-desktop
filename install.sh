#!/bin/bash

# Run this script to install and setup everything.
# It is only meant to work with Ubuntu.

ECHO=/usr/bin/echo
SUDO=/usr/bin/sudo
DIRNAME=/usr/bin/dirname
APTGET=/usr/bin/apt-get
ADD_APT_REPO=/usr/bin/add-apt-repository
ANSIBLE=/usr/bin/ansible-playbook

function die {
	$ECHO "Error: $1"
	exit 1
}

for FILE in "$ECHO" "$SUDO" "$DIRNAME" "$APTGET" "$ADD_APT_REPO" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

[ $# == 0 ] || die "\"$0\" doesn't accept any parameters."

function check_ansible {
	[ -x "$ANSIBLE" ]
}

DIR=$($DIRNAME "$0")
cd $DIR || die "Can't enter $DIR."

for FILE in setup.ansible.yml ansible.cfg ; do
	[ -r "./$FILE" ] || die "$FILE is missing or not readable."
done

for FILE in yes_or_no.sh setup_gpg.sh ; do
	[ -x "./scripts/$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

$ECHO "=== Setting up your Linux system ==="
$ECHO ""

check_ansible || ($ECHO "=== Installing Ansible ===" && \
	$SUDO $APTGET update && \
	$SUDO $APTGET --assume-yes --fix-broken install && \
	$SUDO $APTGET --assume-yes dist-upgrade && \
	$SUDO $ADD_APT_REPO --yes --update ppa:ansible/ansible && \
	$SUDO $APTGET --assume-yes install ansible aptitude && \
	$SUDO $APTGET --assume-yes autoremove && \
	$SUDO $APTGET --assume-yes clean && \
	$ECHO "=== Ansible is installed ===" && \
	$ECHO "")
check_ansible || die "Ansible is not installed."

$ECHO "The following information will be used to configure Git."
[ -z "$FULLNAME" ] && read -p "Enter your full name: " FULLNAME
[ -z "$FULLNAME" ] && die "Full name can't be empty."

[ -z "$EMAIL" ] && read -p "Enter your email: " EMAIL
[ -z "$EMAIL" ] && die "Email can't be empty."

$ECHO "Using \"$FULLNAME\" as full name."
$ECHO "Using \"$EMAIL\" as email."
$ECHO ""

INSTALL_CONTAINERIZATION_TECHS=false
if ./scripts/yes_or_no.sh \
	"Do you want to install containerization technologies such as Docker, Kubernetes, etc.?" ; then
	INSTALL_CONTAINERIZATION_TECHS=true
fi
$ECHO ""

$ECHO "=== Running Ansible playbook ==="
$ANSIBLE ./setup.ansible.yml --ask-become-pass \
	--extra-vars "FULLNAME=\"$FULLNAME\" EMAIL=\"$EMAIL\" \
	INSTALL_CONTAINERIZATION_TECHS=\"$INSTALL_CONTAINERIZATION_TECHS\"" && \
$ECHO "=== Install was SUCCESSFUL ===" || \
die "Failed to run Ansible playbook. You can try shutting down and restarting WSL (by \"wsl.exe --shutdown\") then running $0 again."

if [ -e /var/run/reboot-required ] ; then
	$ECHO ""
	$ECHO "You have to shut down and restart WSL for the changes to take effect."
	if ./scripts/yes_or_no.sh "Do you want to shut down WSL now?" ; then
		wsl.exe --shutdown
	else
		$ECHO "To shut down WSL later, execute \"wsl.exe --shutdown\"."
	fi
fi
