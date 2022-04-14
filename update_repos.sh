#!/bin/bash
echo "${0##*/}"

# list repository paths, relative to home
list="bash batch config fortran hello nrf powershell scripts"

for repo in $list
do
    echo -e "updating $repo... \c"
    if [ -d ${HOME}/$repo ]; then
	echo "OK"
	cd ${HOME}/$repo
	git pull
	git push    
    else
	echo "not found"
    fi
done
