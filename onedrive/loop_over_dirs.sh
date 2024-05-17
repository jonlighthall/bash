#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# Nov 2021 JCL

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	  set_traps
fi

if [ $# -eq 0 ]; then
	  echo "Please provide a target directory"
	  exit 1
else
	  if [[ -d $1 ]]; then
		    echo -n "found "
		    cd $1
		    echo $PWD
        parent_dir=$PWD

        for dir in */ ; do
            cd $dir
            echo $PWD

            ~/utils/bash/onedrive/rm_tracked_bad_extensions.sh .

            cd $parent_dir
           
        done
	  else
		    echo "$1 is not found"
		    exit 1
	  fi
fi
