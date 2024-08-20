#!/bin/bash -u
# Checks a Git repository for deleted files and restores those files
# by checking them out

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
    print_source
fi

# load Git library
glib=${HOME}/utils/bash/git/lib_git.sh
if [ -e $glib ]; then
    source $glib
fi

if ! (return 0 2>/dev/null); then
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi

# define counters
declare -i count_found=0
declare -i count_co=0

get_top
unfix_bad_extensions .

# get list of deleted files
list=$(git ls-files -d)

if [ -z "${list[@]}" ]; then
    echo -e "${TAB}${GOOD}no files to restore${RESET}\n"
else
    echo "${TAB}restoring deleted files..."
    itab
    # checkout deleted files
    echo "${#list} files found"
        count_found=$((count_found+${#list}))
     #   echo "${TAB}$list"
        do_cmd git checkout $list
        RETVAL=$?
        #  for fname in $list; do
        if [[ $RETVAL -eq 0 ]]; then
            ((++count_co))
            count_co=$((count_co+${#list}))
        fi
    #done
    dtab
    echo "${TAB}done"

    # print summary
    echo
    echo -e "${UL}Files found: $count_found${NORMAL}"
    echo "Files restored: ${count_co}"
    echo
fi

set_exit
