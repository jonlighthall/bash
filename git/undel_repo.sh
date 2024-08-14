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

# get root dir
repo_dir=$(git rev-parse --show-toplevel)
echo -e "${TAB}repository directory is ${PSDIR}${repo_dir}${RESET}"
# get repo name
repo=${repo_dir##*/}
echo "${TAB}repository name is $repo"
# get git dir
GITDIR=$(readlink -f "$(git rev-parse --git-dir)")
echo -e "${TAB}the git-dir folder is ${PSDIR}${GITDIR##*/}${RESET}"
# cd to repo root dir
if [[ ${PWD} -ef ${repo_dir} ]]; then
    echo "${TAB}already in top level directory"
else
    echo "${TAB}$PWD is part of a Git repository"
    echo "${TAB}moving to top level directory..."
    cd -L "$repo_dir"
    echo "${TAB}$PWD"
fi

unfix_bad_extensions .

# get list of deleted files
list=$(git ls-files -d)

if [ -z "${list[@]}" ]; then
    echo -e "${TAB}${GOOD}no files to restore${RESET}\n"
else
    echo "${TAB}restoring deleted files..."
    itab
    # checkout deleted files
    for fname in $list; do
        ((++found))
        echo "${TAB}$fname"
        do_cmd git checkout $fname
        RETVAL=$?
        if [[ $RETVAL -eq 0 ]]; then
            ((++check))
        fi
    done
    dtab
    echo "${TAB}done"

    # print summary
    echo
    echo -e "${TAB}\E[4m${found} files found:\E[0m"
    echo "${TAB}${check} files restored"
    echo
fi

set_exit
