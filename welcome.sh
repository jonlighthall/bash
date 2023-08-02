#!/bin/bash
msg=$(echo " Welcome to $(hostname -s) ")
ln=$(for (( i=1;i<=${#msg};i++ )); do echo -n "-"; done)
echo -e "$ln\n$msg\n$ln"
exit