#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# Nov 2021 JCL

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

unset_traps
set +e

if [ $# -eq 0 ]; then
	  echo "Please provide a target directory"
	  exit 1
else
	  if [[ -d $1 ]]; then
		    echo -n "found "
		    cd "$1"
		    echo "$PWD"
        parent_dir="$PWD"

        for dir in */ ; do
            echo "$dir"
            date_dir $dir
        done
	  else
		    echo "$1 is not found"
		    exit 1
	  fi
fi
