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

# Path additions
path=$(dirname "$PWD")
path+=( $(dirname "$path") )

for ADDPATH in ${path[@]}; do
	  echo -en "   \x1b[33m${ADDPATH}\x1b[m... "
	  # check if path exists
	  if [ -d "${ADDPATH}" ]; then
		    echo "found"
		    ABSPATH=$(readlink -f $ADDPATH)
	  else
		    echo "not found"
		    continue
	  fi
	  # prepend path to PATH
	  if [[ "$PATH" != *"${ADDPATH}:"* ]]; then
		    export PATH=$ABSPATH:$PATH
		    echo "added to PATH"
	  else
		    echo "already in PATH"
	  fi
done
echo "done"

# print time at exit
echo -e "\n${BASH_SOURCE##*/} "$(sec2elap $SECONDS)"on $(date +"%a %b %-d %-l:%M %p %Z")"
