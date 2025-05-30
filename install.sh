#!/bin/bash

set -e

# !! CHECK: Works for Ubuntu. Does this detect debian/raspbian/rpios?
Flavor="$(grep -oP '(?<=^ID=)[^"]*' /etc/os-release | tr '[:upper:]' '[:lower:]')"
Distro="$(lsb_release -c -s)"
Release="$(lsb_release -s -r)"
Arch="$(apt-config dump | grep '^APT::Architecture ' | sed  's/.* "\(.*\)";$/\1/g')"

# Install default config files
echo "Installing Default Configs For $Flavor-$Distro-$Arch"
rm -f "/etc/lmce-build"
ln -s "$(pwd)/conf-files/${Flavor}-${Distro}-${Arch}" "/etc/lmce-build"

echo "Creating symlink /usr/local/lmce-build to ${pwd}"
rm -f "/usr/local/lmce-build"
ln -s "$(pwd)" "/usr/local/lmce-build"

#echo "Configure APT preferences"
#echo '
#Package: *
#Pin: origin
#Pin-Priority: 9999
#
#Package: *
#Pin: release v='${Release}',o=Ubuntu,a='${Distro}',l=Ubuntu
#Pin-Priority: 9998
#' > /etc/apt/preferences

# Generate ssh key for builder if !exist
if [[ ! -f /etc/lmce-build/builder.key ]] ;then
	echo "Generating SSH Key for this host : /etc/lmce-build/builder.key"
	ssh-keygen -N '' -C "LinuxMCE Builder $Distro $Arch" -f /etc/lmce-build/builder.key
else
	echo "SSH Key found on this host : /etc/lmce-build/builder.key"
fi

