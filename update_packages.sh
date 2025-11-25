#!/bin/bash -u
#
# update_packages.sh - update, upgrade, and clean installed packages
#
# Oct 2020 JCL

declare -i start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source "$fpretty"
    set_traps
fi

# print source name at start
print_source

# update
bar "update..."
sudo apt update
print_time

# upgrade
bar "upgrade and fix missing..."
sudo apt --fix-broken install -y
sudo apt upgrade -y --fix-missing
print_time

# cleanup
bar "autoremove and purge..."
sudo apt autoremove --purge -y
bar "autoclean..."
sudo apt autoclean
bar "clean..."
sudo apt clean
print_time

# check for distro update
bar "release upgrade..."
trap -- ERR
sudo do-release-upgrade
