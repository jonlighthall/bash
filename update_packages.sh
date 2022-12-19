#!/bin/sh

# update and upgrade
sudo apt update
sudo apt upgrade -y

# re-check and cleanup
sudo apt upgrade -y --fix-missing
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean
