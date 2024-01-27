#!/bin/bash

# Run this script to install and setup everything.
# It is only meant to work with Ubuntu.

ECHO="builtin echo"
SUDO=/usr/bin/sudo
DIRNAME=/usr/bin/dirname
BASENAME=/usr/bin/basename
GROUPS_CMD=/usr/bin/groups
GREP=/usr/bin/grep
APTGET=/usr/bin/apt-get
ADD_APT_REPO=/usr/bin/add-apt-repository
ANSIBLE=/usr/bin/ansible-playbook
DIALOG=/usr/bin/dialog
CLEAR=/usr/bin/clear
REBOOT=/usr/sbin/reboot
KILLALL=/usr/bin/killall
WHOAMI=/usr/bin/whoami

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

function die_internal_error {
	die "Internal error."
}

for FILE in "$SUDO" "$DIRNAME" "$BASENAME" "$GROUPS_CMD" "$GREP" "$APTGET" "$ADD_APT_REPO"
do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

# We make sure that the language for the installation is English.
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Setting the user file-creation mask.
umask u=rwx,g=rx,o=rx || \
die "Unable to set the file-creation mask."

FILENAME=$($BASENAME "$0") || die_internal_error
[ $# == 0 ] || die "$FILENAME doesn't accept any parameters."

function check_ansible {
	[ -x "$ANSIBLE" ]
}

DIR=$($DIRNAME "$0") || die_internal_error
cd "$DIR" || die "Can't enter '$DIR'."

for FILE in setup.ansible.yml ansible.cfg include_tasks/apt_repository.ansible.yml \
	include_tasks/create_upgrade_source_for_ppa.ansible.yml \
	include_tasks/create_upgrade_source_for_repository.ansible.yml
do
	[ -r "./$FILE" ] || die "$FILE is missing or not readable."
done

for FILE in yes_or_no.sh setup_gpg.sh ; do
	[ -x "./scripts/$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

# Checking if there was a successful installation before.
[ -e ~/.applications_were_automatically_configured.txt ]
MARKER_FILE_EXISTS=$?

$ECHO "=== Setting up your Linux system ===" && \
$ECHO "" || die_internal_error

function has_sudo_rights {
	$GROUPS_CMD | $GREP --fixed-strings "sudo" &>/dev/null
}

if has_sudo_rights ; then
	ANSIBLE_COMMAND="$ANSIBLE --ask-become-pass"
else
	$ECHO "Note: The current user doesn't have sudo rights." || die_internal_error
	check_ansible || die "You need to run this script first with a user that has sudo rights."
	$ECHO "Systemwide changes will be skipped." && \
	$ECHO "" || die_internal_error
	ANSIBLE_COMMAND="$ANSIBLE --skip-tags system"
fi

INSTALL_COMMAND="$ECHO \"=== Installing Ansible ===\" && \
	$APTGET update && \
	$APTGET --assume-yes dist-upgrade && \
	$ADD_APT_REPO --yes --update ppa:ansible/ansible && \
	$APTGET --assume-yes install ansible aptitude dialog ncurses-bin && \
	$APTGET --assume-yes autoremove && \
	$APTGET --assume-yes clean && \
	$ECHO \"=== Ansible is installed ===\" && \
	$ECHO \"\""

check_ansible || $SUDO /bin/bash -c "$INSTALL_COMMAND" || \
die "Unable to install Ansible."
check_ansible || die "Ansible is not installed."

$ECHO "The following information will be used to configure Git." || die_internal_error
[ -z "$FULLNAME" ] && { read -p "Enter your full name: " FULLNAME || die_internal_error ; }
[ -z "$FULLNAME" ] && die "Full name can't be empty."

[ -z "$EMAIL" ] && { read -p "Enter your email: " EMAIL || die_internal_error ; }
[ -z "$EMAIL" ] && die "Email can't be empty."

$ECHO "Using \"$FULLNAME\" as full name." && \
$ECHO "Using \"$EMAIL\" as email." && \
$ECHO "" || die_internal_error

function check_with_grep {
	$GREP --fixed-strings "$1" &>/dev/null && \
	$ECHO "true" || \
	$ECHO "false"
}

function create_dialog {
	$DIALOG --no-tags --checklist "Install these additional components:" 0 0 0 \
	container "Containerization technologies such as Docker, Kubernetes, etc." off \
	java "Development tools for Java" off || \
	die "Internal error: Failed to create the dialog."
}

INSTALL_CONTAINERIZATION_TECHS=false
INSTALL_JAVA_TOOLS=false
JDK_VERSION=17

if [ ! -x "$DIALOG" ] || [ ! -x "$CLEAR" ] ; then
	$ECHO "Note: Defaulting to basic installation since required applications are missing." && \
	$ECHO "After successfully finishing this installation, run $FILENAME again" && \
	$ECHO "if you want to set additional installation options." && \
	$ECHO "" || die_internal_error
elif ./scripts/yes_or_no.sh \
	"Do you want to run the basic installation? Answering no will give additional installation options." ; then
	$ECHO "" || die_internal_error
else
	# Creating a copy of stdout on descriptor 3
	exec 3>&1
	DIALOG_RESULT=$(create_dialog 2>&1 1>&3) || die_internal_error
	# Closing file descriptor 3
	exec 3>&-
	$CLEAR || die_internal_error

	INSTALL_CONTAINERIZATION_TECHS=$(check_with_grep "container" <<<"$DIALOG_RESULT") && \
	INSTALL_JAVA_TOOLS=$(check_with_grep "java" <<<"$DIALOG_RESULT") || die_internal_error
fi

if [ "$INSTALL_JAVA_TOOLS" == "true" ] && has_sudo_rights ; then
	$ECHO "Azul Zulu build of OpenJDK version ${JDK_VERSION} will be installed." && \
	$ECHO "If you want to change the version, set variable JDK_VERSION in $FILENAME." && \
	$ECHO "" || die_internal_error
fi

$ECHO "=== Running Ansible playbook ===" || die_internal_error
$ANSIBLE_COMMAND \
	--extra-vars "FULLNAME=\"$FULLNAME\" EMAIL=\"$EMAIL\" \
	INSTALL_JAVA_TOOLS=\"$INSTALL_JAVA_TOOLS\" \
	JDK_VERSION=\"$JDK_VERSION\" \
	INSTALL_CONTAINERIZATION_TECHS=\"$INSTALL_CONTAINERIZATION_TECHS\"" \
	./setup.ansible.yml && \
$ECHO "=== Install was SUCCESSFUL ===" || \
die "Failed to run Ansible playbook.\nYou can try restarting your computer then running $FILENAME again."

if [ -e /var/run/reboot-required ] ; then
	$ECHO "" && \
	$ECHO "You have to restart your computer for the changes to take effect." && \
	$ECHO "After restarting, you can run this install script again by executing 'run_install_script'." && \
	if [ -x "$REBOOT" ] && has_sudo_rights && \
		./scripts/yes_or_no.sh "Do you want to restart now?"
	then
		$REBOOT && exit 0
	fi
fi

if [ $MARKER_FILE_EXISTS -ne 0 ] ; then
	$ECHO "" && \
	$ECHO "You have to sign out for the configuration changes to take effect." && \
	if [ -x "$KILLALL" ] && [ -x "$WHOAMI" ] && \
		./scripts/yes_or_no.sh "Do you want to kill all running programs and sign out now?"
	then
		$KILLALL --user "$($WHOAMI)"
	fi
fi
