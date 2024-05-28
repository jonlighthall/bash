#!/bin/bash -u
#
# Used to delete binary files from directory. Tracked binary files found in a
# Git repository will be removed from the repository. The .git directory will
# not be searched.
#
# May 2024 JCL

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# define replacement seperator
sep=_._

if [ $# -eq 0 ]; then
	  echo "Please provide a target directory"
	  exit 1
fi

if [[ "$1" == "." ]]; then
    in_dir=$(readlink -f $PWD/$1)
else
    in_dir=$(readlink -f $1)
fi
echo -n "target directory $in_dir..."

if [ ! -d ${in_dir} ]; then
		echo "not found"
		exit 1
fi

echo "found "
cd ${in_dir}
itab
# check if PWD is a git repository
if git rev-parse --git-dir &>/dev/null; then
		# This is a valid git repository
		echo "${TAB}$PWD is part of a Git repository"
		GITDIR=$(git rev-parse --git-dir)
		echo "${TAB}the .git folder is $GITDIR"
    dtab

    if [ -f makefile ]; then
        make clean
    fi

    declare -i count_found=0
    declare -i count_rm=0
    declare -i count_mv=0
    declare -i count_mv_fail=0

		# first, remove tracked files from the repository
		echo "${TAB}removing tracked binary files from the repository..."
    itab
    for fname in $(find ./ -not -path "*$GITDIR/*" -not -path "*/.git/*" -type f | perl -lne 'print if -B' ); do
        ((++count_found))
        echo -n "${TAB}$fname... "
        # check if the file is tracked
        git ls-files --error-unmatch $fname &>/dev/null
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo -n "tracked: "
            # check if the file is modified
            if [ -z "$(git diff $fname)" ]; then
                echo -n "unmodified: "
                rm -v $fname
                ((++count_rm))
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
            ((++count_found))
            # check if the file is tracked
            git ls-files --error-unmatch $fname &>/dev/null
            RETVAL=$?
            if [ $RETVAL -eq 0 ]; then
                echo -n "tracked: "

                # check if the file is modified
                if [ -z "$(git diff $fname)" ]; then
                    echo -n "unmodified: "
                    rm -v $fname
                    ((++count_rm))
                else
                    echo -n "modified: "
                    mv -nv "$fname" "$(echo $fname | sed "s/\.$bad/$sep$bad/")"
                    if [ -f "$fname" ];then
                        echo "rename $fname FAILED"
                        ((++count_mv_fail))
                    else
                        ((++count_mv))
                    fi
                fi
            else
                echo -n "untracked: "
                mv -nv "$fname" "$(echo $fname | sed "s/\.$bad/$sep$bad/")"
                if [ -f "$fname" ];then
                    echo "rename $fname FAILED"
                    ((++count_mv_fail))
                else
                    ((++count_mv))
                fi
            fi

        done
        dtab
    done
    dtab

    echo "Files found: $count_found"
    echo "Files deleted: $count_mv"
    echo "Files renamed: $count_mv"
    echo "Files not renamed: $count_mv_fail"

else
		# this is not a git repository
		echo "$1 is not part of a Git repsoity"
fi
