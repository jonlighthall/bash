#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# Nov 2021 JCL

declare -i start_time=$(date +%s%N)

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
		    echo "found $1"

		    cd $1
		    echo $PWD

		    if git rev-parse --git-dir &>/dev/null; then
			      # This is a valid git repository
			      echo "$1 is part of a Git repository"
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
			      #find ./ -type f -not -path "*/.git/*" | perl -lne 'print if -B' | xargs -r rm -v

            itab

            for file in $(find ./ -type f -not -path "*/.git/*"); do

                # Check if the file is binary
                if perl -e 'exit -B $ARGV[0]' "$file"; then
                    :  #echo "File is text."
                    file $file
                else
                    if [ -s $file ]; then
                        echo -e "${TAB}${BAD}${file}${RESET} is binary"
                    else
                        echo -e "${TAB}${YELLOW}${file}${RESET} is empty"
                    fi
                fi
                continue

            done
            dtab

            #      find ./ -type f -not -path "*/.git/*" | perl -lne 'print if -B' | xargs -r rm -v
		    fi
	  else
		    echo "$1 is not found"
		    exit 1
	  fi
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
