#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# Nov 2021 JCL

declare -i start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

if [ $# -eq 0 ]; then
	  echo "Please provide a target directory"
	  exit 1
fi

if ! [[ -d "$1" ]]; then
  	echo "$1 is not found"
		exit 1
fi
echo "found $1"

cd $1
echo $PWD

# check if PWD is a git repository
if git rev-parse --git-dir &>/dev/null; then
    # This is a valid git repository
    echo "${TAB}$PWD is part of a Git repository"
    GITDIR=$(git rev-parse --git-dir)
		echo "the .git folder is $GITDIR"

		# first, remove tracked files from the repository
		echo "removing tracked binary (and empty) files from the repository..."
		find ./ -type f -not -path "*$GITDIR/*" -not -path "*/.git/*" | perl -lne 'print if -B' | xargs -r git rm --ignore-unmatch

		# then, remove remaining binary files
		echo "removing untracked binary files..."
		find ./ -type f -not -path "*$GITDIR/*" -not -path "*/.git/*" | perl -lne 'print if -B' | xargs -r rm -v
else
		# this is not a git repository
		echo "$1 is not part of a Git repsoity"
		echo "removing binary files..."
    itab
    for file in $(find -L ./ -type f -not -path "*/.git/*"); do
        # Check if the file is binary
        if perl -e 'exit -B $ARGV[0]' "$file"; then
            :  #echo "File is text."; file $file
        else
            if [ -s $file ]; then
                echo -e "${TAB}${BAD}${file##*./}${RESET} is binary"
            else
                echo -e "${TAB}${YELLOW}${file##*./}${RESET} is empty"
            fi
            itab
            echo -en "${TAB}"
            ls $file -l --color=always
            echo -en "${TAB}"
            rm -rv $file
            dtab
        fi
    done
    dtab
fi

set_exit
