#!/bin/bash
echo "${0##*/}"

# deinfe horizontal line
hline() {
    for i in {1..64}; do echo -n "-"; done
    echo
}

# list repository paths, relative to home
list="bash batch config fortran hello matlab/macros nrf powershell scripts"

for repo in $list
do
    hline
    echo -e "updating $repo... \c"
    if [ -d ${HOME}/$repo ]; then
	echo "OK"
	cd ${HOME}/$repo
	git pull --all
	git push --all
    else
	echo "not found"
    fi
    hline
    echo
done
