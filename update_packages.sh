#!/bin/sh

# update and upgrade
sudo apt update
sudo apt upgrade -y

# re-check and cleanup
sudo apt upgrade -y --fix-missing
sudo apt autoremove --purge -y
sudo apt autoclean
sudo apt clean

# print time at exit
echo -e "\n$(date +"%R) ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"