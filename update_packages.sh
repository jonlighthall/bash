#!/bin/bash
#
# update_packages.sh - update, upgrade, and clean installed packages
#
# Oct 2020 JCL

# set tab
${TAB:=''}

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
echo -e "${TAB}running ${PSDIR}$BASH_SOURCE${NORMAL}..."
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
echo -en "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} "
if command -v sec2elap &>/dev/null; then
    echo "$(sec2elap $SECONDS)"
else
    echo "elapsed time is $(SECONDS) sec"
fi
