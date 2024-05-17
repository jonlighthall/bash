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

		    if git rev-parse --git-dir &>/dev/null; then
			      # This is a valid git repository
			      echo "$1 is part of a Git repository"
			      GITDIR=$(git rev-parse --git-dir)
			      echo "the .git folder is $GITDIR"

			      # first, remove tracked files from the repository
			      echo "removing tracked binary files from the repository..."
			      find ./ -type f -not -path "*$GITDIR/*" -not -path "*/.git/*" | perl -lne 'print if -B' | xargs -r rm -v

            for bad in bat bin cmd csh exe gz js ksh osx out prf ps ps1; do

                for fname in $(find $1 -name "*.${bad}"); do
                    echo -n "echo $fname... "
                    if [ -z $(git diff $fname) ]; then
                        echo "unmodified: delte"
                        rm -v $fname
                    else
                        echo "modified: move"
                        mv -nv "$fname" "$(echo $fname | sed "s/\.$bad/$sep$bad/")" 
                    fi                    
                done
            done            
		    else
			      # this is not a git repository
			      echo "$1 is not part of a Git repsoity"
		    fi
	  else
		    echo "$1 is not found"
		    exit 1
	  fi
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
