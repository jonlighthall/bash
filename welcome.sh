#!/bin/bash -u
msg=$(echo " Welcome to $(hostname -s) ")
ln=$(for ((i = 1; i <= ${#msg}; i++)); do echo -n "-"; done)
echo -e "\033[0;33m$ln\n$msg\n$ln\033[0m"
exit
