#!/bin/bash -u
# -----------------------------------------------------------------------------------------------
#
# ~/utils/bash/welcome.sh
#
# Purpose:
#   Display a welcome message, including the host name, on remote host after
#   login
#
# JCL Aug 2023
#
# -----------------------------------------------------------------------------------------------

# define welcome message
msg=$(echo " Welcome to $(hostname -s) ")
#
# create a line of dashes the same width as $msg
ln=$(for ((i = 1; i <= ${#msg}; i++)); do echo -n "-"; done)
#
# define text formatting
fmt=$(echo -e "\E[0;33m")
#
# display welcome message
echo -e "$fmt$ln\n$msg\n$ln\E[0m"
exit
