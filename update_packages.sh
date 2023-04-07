#!/bin/bash
#
# update_packages.sh - update, upgrade, and clean installed packages
#
# JCL Oct 2020
#
echo "${0##*/}"

# deinfe horizontal line
hline() {
    for i in {1..69}; do echo -n "-"; done
    echo
}
bar() {
    hline
    echo "$1"
    hline
}

# update and upgrade
bar "update..."
sudo apt update
bar "upgrade..."
sudo apt upgrade -y

# re-check and cleanup
sudo apt upgrade -y --fix-missing
bar "autoremove..."
sudo apt autoremove --purge -y
bar "autoclean..."
sudo apt autoclean
bar "clean..."
sudo apt clean

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
