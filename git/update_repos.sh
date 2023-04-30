#!/bin/bash
#
# update_repos.sh - push and pull a specified list of git repositories and print summaryories and print summary
#
# JCL Apr 2022
echo "${0##*/}"

fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

TAB="   "

# list repository paths, relative to home
# settings
list="config \
       home "

# scripting utilities
dir_script="utils/"
list+="${dir_script}bash \
       ${dir_script}batch \
       ${dir_script}powershell "
list_remote=${HOME}/${dir_script}bash/git/list_remote_url.txt

# programming utilities
dir_prog="utils/"
list+="${dir_prog}fortran_utilities "

# tutorial examples
dir_examp="examples/"
list+="${dir_examp}cpp \
       ${dir_examp}hello \
       ${dir_examp}fortran \
       ${dir_examp}nrf \
       ${dir_examp}nrf77 \
       ${dir_examp}python "

# matlab
dir_matlab="matlab/"
list+="${dir_matlab} \
       ${dir_matlab}macros "

# private
fname_private=${HOME}/${dir_script}bash/git/list_private_dir.txt
if [ -f ${fname_private} ]; then
    while IFS= read -r line
    do
	# evaluate each line to expand defined variable names
	eval line2=$line
	if [[ $line == $line2 ]]; then
	    list+=" ${line}"
	else
	    list+=" ${line2}"
	fi
    done < ${fname_private}
fi

loc_fail=""
pull_fail=""
push_fail=""
mods=""
for repo in $list
do
    hline 70
    echo -e "locating $repo... \c"
    if [ -e ${HOME}/$repo ]; then
	echo -e "${GOOD}OK${NORMAL}"
	cd ${HOME}/$repo
	echo -n "checking repsoitory status... "
	git rev-parse --is-inside-work-tree >/dev/null 2>&1
	RETVAL=$?
	if [[ $RETVAL -eq 0 ]]; then
	    echo -e "${GOOD}OK${NORMAL}"
	    # add remotes to list
	    git remote -v | awk -F " " '{print $2}' | uniq >> ${list_remote}
	    if [ $# -gt 0 ]; then
		echo "matching argument $1..."
		url=$(git remote -v | head -n 1 | awk '{print $2}')
		if [[ $url =~ $1 ]]; then
		    echo "$repo url $url matches $1"
		else
		    echo "skipping..."
		    continue
		fi
	    fi

	    # pull
	    echo "pulling..."
	    git pull --all --tags --prune 2> >(sed $"s/.*/\x1b[1;31m&\x1b[m/;s/^/${TAB}/">&2) | sed "s/^/${TAB}/"
	    if [[ $? != 0 ]]; then
		echo "pull: $?"
		pull_fail+="$repo "
	    fi

	    # push
	    echo "pushing..."
	    git push --all 2> >(sed $"s/.*/\x1b[1;32m&\x1b[m/;s/^/${TAB}/">&2) | sed "s/^/hello${TAB}/"
	    if [[ $? != 0 ]]; then
		echo "push: $?"
		push_fail+="$repo "
	    fi

	    # check for modified files
	    if [[ ! -z $(git diff --name-only --diff-filter=M) ]]; then
		echo "modified:"
		git diff --name-only --diff-filter=M | sed "s/^/${TAB}/"
		mods+="$repo "
	    fi
	else
	    echo -e "${BAD}FAIL${NORMAL}"
	    echo "${TAB}return value = $RETVAL"
	    echo "${TAB}$repo not a Git repository"
	    loc_fail+="$repo "
	fi
    else
	echo "not found"
	loc_fail+="$repo "
	test_file ${HOME}/$repo
    fi
    hline 70
    echo
done

# sort and uniquify remotes list
sort -u ${list_remote} -o ${list_remote}

# print list of remotes
echo -n "      remotes: "
head -n 1 ${list_remote}
tail -n +2 ${list_remote} | sed 's/^/               /'
echo

# print push/pull summary
echo -n "    not found: "
if [ -z "$loc_fail" ]; then
    echo "none"
else
    echo "$loc_fail"
fi
echo -n "push failures: "
if [ -z "$push_fail" ]; then
    echo "none"
else
    echo "$push_fail"
fi
echo -n "pull failures: "
if [ -z "$pull_fail" ]; then
    echo "none"
else
    echo "$pull_fail"
fi
echo -n "     modified: "
if [ -z "$mods" ]; then
    echo "none"
else
    echo "$mods"
fi

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
