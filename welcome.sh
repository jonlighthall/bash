#!/bin/bash -u
# Purpose: Display a welcome message, including the host name, on remote host after login

# define welcome message
msg=$(echo " Welcome to $(hostname -s) ")
# create a line of dashes the same width as $msg
ln=$(for ((i = 1; i <= ${#msg}; i++)); do echo -n "-"; done)
# display welcome message
echo -e "\033[0;33m$ln\n$msg\n$ln\033[0m"

# update repositories
fup=${HOME}/utils/bash/git/update_repos.sh
if [ -e $fup ]; then
	bash $fup
fi
exit
