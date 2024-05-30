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

trap 'echo "${TAB}exiting ${BASH_SOURCE[0]##*/}..."' EXIT

# check argument
if [ $# -eq 0 ]; then
	  echo "Please provide a target directory"
	  exit 1
fi

# find input directory
if [[ "$1" == "." ]]; then
    in_dir=$(readlink -f "$PWD/$1")
else
    in_dir=$(readlink -f $1)
fi
echo -n "target directory $in_dir..."
if [ ! -d "${in_dir}" ]; then
		echo "not found"
		exit 1
fi
echo "found "
cd "${in_dir}"

itab
# check if PWD is a git repository
if ! git rev-parse --git-dir &>/dev/null; then
		# this is not a git repository
		echo "${TAB}${in_dir} is not part of a Git repsoity"
    dtab
    exit 1
fi

# This is a valid git repository
echo "${TAB}$PWD is part of a Git repository"
GITDIR=$(git rev-parse --git-dir)
echo "${TAB}the .git folder is $GITDIR"

# get repo name
repo_dir=$(git rev-parse --show-toplevel)
echo -e "repository directory is ${PSDIR}${repo_dir}${RESET}"
repo=${repo_dir##*/}
echo "repository name is $repo"
if [[ ${PWD} -ef ${repo_dir} ]]; then
    echo "already in top level directory"
else
    echo "$PWD is part of a Git repository"
    echo "moving to top level directory..."
    cd -L $repo_dir
    echo "$PWD"
fi

dtab

if [ -f makefile ]; then
    echo "${TAB}makefile found"
    echo "${TAB}executing make clean..."
    do_cmd make clean
fi

declare -i count_found=0
declare -i count_rm=0
declare -i count_mv=0
declare -i count_mv_fail=0

# first, remove tracked files from the repository
echo -n "${TAB}removing tracked binary files from the repository... "
itab
for fname in $(find ./ -not -path "*$GITDIR/*" -not -path "*/.git/*" -type f ); do

    # Check if the file is binary
    if perl -e 'exit -B $ARGV[0]' "$fname"; then
        :  #echo "File is text."; file $file
    else
        start_new_line
        echo -en "${TAB}${fname##*./}... "
        if [ ! -s $fname ]; then
            echo -en "${YELLOW}empty: ${RESET}"
            rm -v "$fname"
            ((++count_rm))
            continue
        else
            echo -e "${BAD}binary: ${RESET}"
        fi
      
        # check if the file is tracked
        git ls-files --error-unmatch $fname &>/dev/null
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo -n "tracked: "
            # check if the file is modified
            if [ -z "$(git diff $fname)" ]; then
                echo -n "unmodified: "
                rm -v "$fname"
                ((++count_rm))
            else
                echo "modified"
            fi
        else
            echo "untracked"
            rm -v "$fname"
            ((++count_rm))
        fi
    fi
done
echo "done"
dtab

# look for bad extensions
echo -n "${TAB}checking for files with bad extensions... "
itab
for bad in bat bin cmd csh exe gz js ksh osx out prf ps ps1; do

    name_list=$(find ./ -name "*.${bad}")

    if [ -z "${name_list}" ]; then
        continue
    fi

    start_new_line
    echo -n "${TAB}.${bad}... "
    itab

    n_files=$(echo "$name_list" | wc -l)
    echo "$n_files files found"

    for fname in $(find ./ -name "*.${bad}"); do
        ((++count_found))
        echo -n "${TAB}${count_found}) $fname... "

        # check if the file is tracked
        git ls-files --error-unmatch "$fname" &>/dev/null
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo -n "tracked: "

            # check if the file is modified
            if [ -z "$(git diff $fname)" ]; then
                echo -n "unmodified: "
                rm -v "$fname"
                ((++count_rm))
            else
                echo -n "modified: "
                mv -nv "$fname" "$(echo "$fname" | sed "s/\.$bad/$sep$bad/")"
                if [ -f "$fname" ];then
                    echo "rename $fname FAILED"
                    ((++count_mv_fail))
                else
                    ((++count_mv))
                fi
            fi
        else
            echo -n "untracked: "

            git check-ignore "${fname}" &>/dev/null
            RETVAL=$?
            if [ $RETVAL -eq 0 ]; then
                echo -n "ignored: "

                rm -v "$fname"
                ((++count_rm))

            else
                echo -n "not ignored: "

                fname_out=$(echo "$fname" | sed "s/\.$bad/$sep$bad/")
                echo
                itab
                decho "${TAB}fname: $fname"
                decho "${TAB}fname out: $fname_out"
                decho "${TAB}mv -nv $fname ${fname_out}"
                echo -n "${TAB}"
                dtab
                mv -nv "$fname" "${fname_out}"
                if [ -f "$fname" ];then
                    echo "rename $fname FAILED"
                    ((++count_mv_fail))
                else
                    ((++count_mv))
                fi
            fi
        fi

    done
    dtab
done
dtab
echo "done"

echo

echo -e "${UL}Files found: $count_found${NORMAL}"
echo "Files deleted: $count_rm"
echo "Files renamed: $count_mv"
echo "Files not renamed: $count_mv_fail"
echo
