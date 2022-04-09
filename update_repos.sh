#!/bin/bash
echo "${0##*/}"

# list repository paths, relative to home
list="config bash scripts fortran nrf hello"

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
