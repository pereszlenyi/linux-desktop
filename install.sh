#!/bin/bash

# Run this script to install and setup everything.

function die {
	echo "Error: $1"
	exit 1
}

function check_ansible {
	dpkg-query --show --showformat='${Status}\n' ansible | grep "installed" >/dev/null
}

DIR=$(dirname "$0")
cd $DIR || die "Can't enter $DIR."
ls ./update_ansible.ansible.yml ./setup.ansible.yml >/dev/null || die "Playbooks are missing."

check_ansible || sudo apt-get install ansible
check_ansible || die "Couldn't install ansible."

if [ -z "$FULLNAME" ]; then
	read -p "Enter full name: " FULLNAME
fi
if [ -z "$EMAIL" ]; then
	read -p "Enter email: " EMAIL
fi

echo -e "\nUsing '$FULLNAME' as full name."
echo "Using '$EMAIL' as email."
read -n 1 -s -p "Press any key to continue "
echo -e "\n"

ansible-playbook ./update_ansible.ansible.yml --ask-become-pass && \
ansible-playbook ./setup.ansible.yml --ask-become-pass --extra-vars "FULLNAME=\"$FULLNAME\" EMAIL=\"$EMAIL\"" && \
echo "Install was successful." || \
die "Failed to run ansible playbooks."
