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

# load OneDrive library
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source $flib
fi

# load Git library
glib=${HOME}/utils/bash/git/lib_git.sh
if [ -e $glib ]; then
    source $glib
fi

trap 'echo "${TAB}exiting ${BASH_SOURCE[0]##*/}..."' EXIT

check_arg "$@"
itab
get_top
dtab

if [ -f makefile ]; then
    echo "${TAB}makefile found"
    itab
    echo "${TAB}executing make clean..."
    do_cmd make clean out
    echo "${TAB}done"
    dtab
fi

check_repo 0
declare -i RETVAL=$?
if [[ $RETVAL -eq 0 ]]; then
    echo "${TAB}executing git fetch..."
    do_cmd git fetch --verbose --all --prune
    echo "${TAB}done"
    do_cmd git gc
fi
dtab

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
