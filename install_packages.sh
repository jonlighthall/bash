#!/bin/sh

# update and upgrade
sudo apt update
sudo apt upgrade -y

# install packages
sudo apt install -y dbus-x11
sudo apt install -y x11-apps
sudo apt install -y xterm

# re-check and cleanup
sudo apt upgrade -y --fix-missing
sudo apt autoremove -y

# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"