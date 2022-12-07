#!/bin/bash
# Checks a Git repository for deleted files and restores those files
# by checking them out

echo $BASH_SOURCE

# get list of deleted files
list=$(git status | grep deleted | awk '{print $2}')
echo $list

# checkout deleted files
for fname in $list
do
    echo $fname
    git checkout $fname
done
wait 
echo "${TAB}$(date): ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
