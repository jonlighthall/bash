#!/bin/bash -u
#
# update_packages.sh - update, upgrade, and clean installed packages
#
# Oct 2020 JCL

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty    
    set_traps
    rtab
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
print_source

# update
bar "update..."
sudo apt update

# upgrade
bar "upgrade and fix missing..."
sudo apt --fix-broken install -y
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
