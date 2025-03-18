#!/bin/bash -u
# ------------------------------------------------------------------------------
#
# git/undel_repo.sh
#
# PURPOSE: Checks a Git repository for deleted files and restores those files by
#   checking them out
#
# Mar 2023 JCL
#
# ------------------------------------------------------------------------------

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

declare -i start_time=$(date +%s%N)

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

DEBUG=1
get_top
unfix_bad_extensions .

# get list of deleted files
list=$(git ls-files -d)
# create array
declare -a alist
for fname in $list; do
    alist+=( "$fname" )
done

if [ -z "${list[@]}" ]; then
    echo -e "${TAB}${GOOD}no files to restore${RESET}\n"
else
    echo -n "${TAB}restoring deleted files... "
    itab
    # get length
    declare -i nf=${#alist[@]}
    # print file names
    echo "$nf files found"
    for fname in $list; do
        echo "${TAB} $fname"
    done

    # checkout deleted files
    count_found=$((count_found + nf))
    do_cmd git checkout $list
    RETVAL=$?
    if [[ $RETVAL -eq 0 ]]; then
        count_co=$((count_co + nf))
    fi
    dtab
    echo "${TAB}done"

    # print summary
    echo
    echo -e "${UL}Files found: $count_found${NORMAL}"
    echo "Files restored: ${count_co}"
    echo
fi

set_exit
