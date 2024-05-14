#!/bin/bash -u
#
# install_packages.sh - install packages for xtest
#
# Oct 2020 JCL

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
    rtab
    set_traps
fi

# print source name at start
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
sudo apt upgrade -y --fix-missing

# install packages
bar "install packages..."
for PACK in dbus-x11 x11-apps xterm; do
    echo "installing ${PACK}..."
    sudo apt install -y --fix-missing ${PACK}
done

# re-check
bar "upgrade and fix missing..."
sudo apt upgrade -y --fix-missing

# cleanup
bar "autoremove and purge..."
sudo apt autoremove --purge -y
bar "autoclean..."
sudo apt autoclean
bar "clean..."
sudo apt clean
