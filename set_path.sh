#!/bin/bash -u
# set_path.sh - prepends the parent and grandparent directories of the current directory to
# PATH. Add the directories one and two levels up from the present working directory to the start
# of the PATH environmental variable.
#
# Jun 2022 JCL

# NB: remember to 'source' this script, don't just execute it
if ! (return 0 2>/dev/null); then
    # exit on errors
    set -e
    # print note
    echo -e "\x1b[31mNOTICE: this script must be soured to save changes to path!\x1b[m"
fi

# set variable
unset path
declare -a path

# Path additions
path="$(dirname "$PWD")"       # parent directory
path+=( "$(dirname "$path")" ) # grandparent directory

source add_path "${path[@]}"

# print time at exit
echo -e "\n${BASH_SOURCE##*/} "$(sec2elap $SECONDS)"on $(date +"%a %b %-d %-l:%M %p %Z")"
