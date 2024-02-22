#!/bin/bash -u
#
# install_packages.sh - install packages for xtest
#
# Oct 2020 JCL

# set tab
:${TAB:=''}

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	set_traps
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# update
bar "update..."
sudo apt update

# upgrade
bar "upgrade and fix missing..."
sudo apt upgrade -y --fix-missing

# install packages
for PACK in dbus-x11 x11-apps xterm; do
    bar "installing ${PACK}..."
    sudo apt install -y --fix-missing ${PACK}
done

# cleanup
bar "autoremove and purge..."
sudo apt autoremove --purge -y
bar "autoclean..."
sudo apt autoclean
bar "clean..."
sudo apt clean
