#!/bin/bash
#
# update_packages.sh - update, upgrade, and clean installed packages
#
# JCL Oct 2020
#
echo "${0##*/}"

fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# deinfe bar
bar() {
    echo
    hline 69
    echo "$1"
    hline 69
}

# update
bar "update..."
sudo apt update

# upgrade
bar "upgrade..."
sudo apt upgrade -y
bar "upgrade (again) and fix missing..."
sudo apt upgrade -y --fix-missing

# cleanup
bar "autoremove and purge..."
sudo apt autoremove --purge -y
bar "autoclean..."
sudo apt autoclean
bar "clean..."
sudo apt clean

# check for distro update
bar "release upgrade..."
sudo do-release-upgrade

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
