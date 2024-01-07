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

function die {
	$ECHO -e "\033[00;31mError: $1\033[00m" >&2
	exit 1
}

for FILE in "$SUDO" "$DIRNAME" "$BASENAME" "$GROUPS_CMD" "$GREP" "$APTGET" "$ADD_APT_REPO" ; do
	[ -x "$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

FILENAME=$($BASENAME "$0")
[ $# == 0 ] || die "$FILENAME doesn't accept any parameters."

function check_ansible {
	[ -x "$ANSIBLE" ]
}

DIR=$($DIRNAME "$0")
cd $DIR || die "Can't enter $DIR."

for FILE in setup.ansible.yml ansible.cfg include_tasks/apt_repository.ansible.yml \
	include_tasks/create_upgrade_source_for_ppa.ansible.yml \
	include_tasks/create_upgrade_source_for_repository.ansible.yml ; do
	[ -r "./$FILE" ] || die "$FILE is missing or not readable."
done

for FILE in yes_or_no.sh setup_gpg.sh ; do
	[ -x "./scripts/$FILE" ] || die "'$FILE' doesn't exist or it's not executable."
done

$ECHO "=== Setting up your Linux system ==="
$ECHO ""

function has_sudo_rights {
	$GROUPS_CMD | $GREP --fixed-strings "sudo" &>/dev/null
}

if has_sudo_rights ; then
	ANSIBLE_COMMAND="$ANSIBLE --ask-become-pass"
else
	$ECHO "Note: The current user doesn't have sudo rights."
	check_ansible || die "You need to run this script first with a user that has sudo rights."
	$ECHO "Systemwide changes will be skipped."
	$ECHO ""
	ANSIBLE_COMMAND="$ANSIBLE --skip-tags system"
fi

INSTALL_COMMAND="$ECHO \"=== Installing Ansible ===\" && \
	$APTGET update && \
	$APTGET --assume-yes --fix-broken install && \
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

$ECHO "The following information will be used to configure Git."
[ -z "$FULLNAME" ] && read -p "Enter your full name: " FULLNAME
[ -z "$FULLNAME" ] && die "Full name can't be empty."

[ -z "$EMAIL" ] && read -p "Enter your email: " EMAIL
[ -z "$EMAIL" ] && die "Email can't be empty."

$ECHO "Using \"$FULLNAME\" as full name."
$ECHO "Using \"$EMAIL\" as email."
$ECHO ""

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
	$ECHO "Note: Defaulting to basic installation since required applications are missing."
	$ECHO "After successfully finishing this installation, run $FILENAME again"
	$ECHO "if you want to set additional installation options."
	$ECHO ""
elif ./scripts/yes_or_no.sh \
	"Do you want to run the basic installation? Answering no will give additional installation options." ; then
	$ECHO ""
else
	# Creating a copy of stdout on descriptor 3
	exec 3>&1
	DIALOG_RESULT=$(create_dialog 2>&1 1>&3)
	# Closing file descriptor 3
	exec 3>&-
	$CLEAR

	INSTALL_CONTAINERIZATION_TECHS=$(check_with_grep "container" <<<"$DIALOG_RESULT")
	INSTALL_JAVA_TOOLS=$(check_with_grep "java" <<<"$DIALOG_RESULT")
fi

if [ "$INSTALL_JAVA_TOOLS" == "true" ] && has_sudo_rights ; then
	$ECHO "Azul Zulu build of OpenJDK version ${JDK_VERSION} will be installed."
	$ECHO "If you want to change the version, set variable JDK_VERSION in $FILENAME."
	$ECHO ""
fi

$ECHO "=== Running Ansible playbook ==="
$ANSIBLE_COMMAND \
	--extra-vars "FULLNAME=\"$FULLNAME\" EMAIL=\"$EMAIL\" \
	INSTALL_JAVA_TOOLS=\"$INSTALL_JAVA_TOOLS\" \
	JDK_VERSION=\"$JDK_VERSION\" \
	INSTALL_CONTAINERIZATION_TECHS=\"$INSTALL_CONTAINERIZATION_TECHS\"" \
	./setup.ansible.yml && \
$ECHO "=== Install was SUCCESSFUL ===" || \
die "Failed to run Ansible playbook. You can try shutting down and restarting WSL (by \"wsl.exe --shutdown\") then running $FILENAME again."

if [ -e /var/run/reboot-required ] ; then
	$ECHO ""
	$ECHO "You have to shut down and restart WSL for the changes to take effect."
	$ECHO "After restarting, you can run this install script again by executing 'run_install_script'."
	if ./scripts/yes_or_no.sh "Do you want to shut down WSL now?" ; then
		wsl.exe --shutdown
	else
		$ECHO "To shut down WSL later, execute \"wsl.exe --shutdown\"."
	fi
fi
