#!/bin/bash -u
# Checks a Git repository for deleted files and restores those files
# by checking them out

echo $BASH_SOURCE

unfix_bad_extensions ./

# get list of deleted files
list=$(git ls-files -d)

# checkout deleted files
for fname in $list; do
    echo $fname
    git checkout $fname
done
wait
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
