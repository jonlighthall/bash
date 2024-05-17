#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# May 2024 JCL

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# define replacement seperator
sep=_._

if [ $# -eq 0 ]; then
	  echo "Please provide a target directory"
	  exit 1
else
	  if [[ -d $1 ]]; then
		    echo -n "found "
		    cd $1
		    echo $PWD
        itab
        # check if PWD is a git repository
		    if git rev-parse --git-dir &>/dev/null; then
			      # This is a valid git repository
			      echo "${TAB}$PWD is part of a Git repository"
			      GITDIR=$(git rev-parse --git-dir)
			      echo "${TAB}the .git folder is $GITDIR"
            dtab

			      # first, remove tracked files from the repository
			      echo "${TAB}removing tracked binary files from the repository..."
            itab            
            for fname in $(find ./ -not -path "*$GITDIR/*" -not -path "*/.git/*" -type f | perl -lne 'print if -B' ); do
                echo -n "${TAB}$fname... "
                # check if the file is tracked
                git ls-files --error-unmatch $fname 2>/dev/null
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    echo "tracked: "
                    # check if the file is modified
                    if [ -z "$(git diff $fname)" ]; then
                        echo -n "unmodified: "
                        rm -v $fname
                    else
                        echo "modified"
                    fi
                else
                    echo "untracked"
                fi
            done
            dtab

            # look for bad extensions
            echo "${TAB}checking for files with bad extensions..."
            itab
            for bad in bat bin cmd csh exe gz js ksh osx out prf ps ps1; do
                echo "${TAB}.${bad}..."
                itab

                for fname in $(find $1 -name "*.${bad}"); do
                    echo -n "${TAB}$fname... "
                    
                    # check if the file is tracked
                    git ls-files --error-unmatch $fname 2>/dev/null
                    RETVAL=$?
                    if [ $RETVAL -eq 0 ]; then
                        echo "tracked: "
                        
                        # check if the file is modified                    
                        if [ -z "$(git diff $fname)" ]; then
                            echo -n "unmodified: "
                            rm -v $fname
                        else
                            echo -n "modified: "
                            mv -nv "$fname" "$(echo $fname | sed "s/\.$bad/$sep$bad/")" 
                        fi                    
                    else
                        echo -n "untracked: "
                        mv -nv "$fname" "$(echo $fname | sed "s/\.$bad/$sep$bad/")" 
                    fi

                done
                dtab
            done
            dtab
		    else
			      # this is not a git repository
			      echo "$1 is not part of a Git repsoity"
		    fi
	  else
		    echo "$1 is not found"
		    exit 1
	  fi
fi
