#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# Nov 2021 JCL

if [ $# -eq 0 ]; then
	  echo "Please provide a target directory"
	  exit 1
else
	  if [[ -d $1 ]]; then
		    echo "found $1"

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
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
