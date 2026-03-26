#!/bin/bash -u
#
# update_packages.sh - update, upgrade, and clean installed packages
#
# Oct 2020 JCL

set -e

declare -i start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
fi

# print source name at start
print_source

# update
bar "update..."
sudo apt-get update
print_time

# upgrade
bar "upgrade..."
if ! sudo apt-get upgrade -y; then
    echo "Initial upgrade failed; attempting one repair and retry..."
    bar "repair and retry..."
    sudo apt-get -f install -y
    sudo apt-get update
    if ! sudo apt-get upgrade -y --fix-missing; then
        echo "Upgrade failed after repair retry."
        echo "Please review apt output and resolve manually."
        exit 1
    fi
fi
print_time

# cleanup
bar "autoremove and purge..."
sudo apt-get autoremove --purge -y
bar "autoclean..."
sudo apt-get autoclean
bar "clean..."
sudo apt-get clean
print_time
