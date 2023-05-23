#!/bin/bash
# Checks a Git repository for deleted files and restores those files
# by checking them out

# source formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source at start
echo "${TAB}running $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# get list of deleted files
list=$(git ls-files -d)

# checkout deleted files
for fname in $list
do
    echo $fname
    git checkout $fname
done
wait 
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
