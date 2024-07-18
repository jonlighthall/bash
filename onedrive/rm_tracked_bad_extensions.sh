#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# May 2024 JCL

declare -i start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
    print_source
fi

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source $flib
fi

trap 'echo "${TAB}exiting ${BASH_SOURCE[0]##*/}..."' EXIT

check_arg "$@"

itab
# check if PWD is a git repository
if ! git rev-parse --git-dir &>/dev/null; then
		# this is not a git repository
		echo "${TAB}${in_dir} is not part of a Git repsoity"
    dtab
    exit 1
fi

# This is a valid git repository
echo "${TAB}$PWD is part of a Git repository"
GITDIR=$(git rev-parse --git-dir)
echo "${TAB}the .git folder is $GITDIR"

# get repo name
repo_dir=$(git rev-parse --show-toplevel)
echo -e "repository directory is ${PSDIR}${repo_dir}${RESET}"
repo=${repo_dir##*/}
echo "repository name is $repo"
if [[ ${PWD} -ef ${repo_dir} ]]; then
    echo "already in top level directory"
else
    echo "$PWD is part of a Git repository"
    echo "moving to top level directory..."
    cd -L "$repo_dir"
    echo "$PWD"
fi

dtab

if [ -f makefile ]; then
    echo "${TAB}makefile found"
    echo "${TAB}executing make clean..."
    do_cmd make clean out
    echo "${TAB}done"
fi

echo "${TAB}executing git fetch..."
do_cmd git fetch --verbose --all --prune
echo "${TAB}done"
do_cmd git gc

set -E +e
trap -- ERR

# remove tracked binary files
fix_bin

# remove tracked files with bad extensions
if command -v wsl.exe >/dev/null; then
	  echo -n "${TAB}WSL defined: "
    fix_bad_ext
fi

print_stat
set_exit
