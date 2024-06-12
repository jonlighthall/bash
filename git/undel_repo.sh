#!/bin/bash -u
# Checks a Git repository for deleted files and restores those files
# by checking them out

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source at start
if ! (return 0 2>/dev/null); then
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
print_source

# define counters
declare -i found=0
declare -i check=0

# get list of deleted files
list=$(git ls-files -d)

if [ -z "${list[@]}" ]; then
    echo "no files to restore"
else
    echo "restoring deleted files..."

    # checkout deleted files
    for fname in $list; do
        ((++found))
        echo $fname
        git checkout $fname
        RETVAL=$?
        if [[ $RETVAL -eq 0 ]]; then
            ((++check))
        fi
    done
    echo "done"

    # print summary
    echo
    echo -e "\E[4m${found} files found:\E[0m"
    echo "${check} files restored"
fi

set_exit
