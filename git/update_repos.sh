#!/bin/bash
#
# update_repos.sh - push and pull a specified list of git repositories and print summaries
#
# JCL Apr 2022

# print source at start
echo "${0##*/}"

fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# list repository paths, relative to home
# settings
list="config \
      config/private "

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
    echo -e "locating ${PSDIR}${UL}$repo${NORMAL}... \c"
    if [ -e ${HOME}/$repo ]; then
	echo -e "${GOOD}OK${NORMAL}"
	cd ${HOME}/$repo
	echo -n "checking repository status... "
	git rev-parse --is-inside-work-tree &>/dev/null
	RETVAL=$?
	if [[ $RETVAL -eq 0 ]]; then
	    echo -e "${GOOD}OK${NORMAL} (RETVAL = $RETVAL)"
	    # add remotes to list
	    git remote -v | awk -F " " '{print $2}' | uniq >> ${list_remote}
	    # check against argument
	    if [ $# -gt 0 ]; then
		echo -n "matching argument ""$1""... "
		url=$(git remote -v | head -n 1 | awk '{print $2}')
		if [[ $url =~ $1 ]]; then
		    echo -e "${GOOD}OK${NORMAL}"
		else
		    echo "skipping..."
		    continue
		fi
	    fi

	    # pull
	    echo "pulling..."
	    script -qef /dev/null -c "git pull -4 --all --tags --prune" | sed 's/$//g' | sed "s//${TAB}/g" | sed 's/\x1B\[K//g' | sed "s/^/${TAB}/" >&1
	    RETVAL=$?
	    if [[ $RETVAL != 0 ]]; then
		echo -e "${TAB}${BAD}FAIL${NORMAL} (RETVAL = $RETVAL)"
		pull_fail+="$repo "
	    else
		echo -e "${TAB}${GOOD}OK${NORMAL} (RETVAL = $RETVAL)"
	    fi

	    # push
	    echo "pushing... " 
	    script -qef /dev/null -c "git push -4 --all" | sed 's/$//g' | sed "s//${TAB}/g" | sed 's/\x1B\[K//g' | sed "s/^/${TAB}/" >&1
	    RETVAL=$?
	    if [[ $RETVAL != 0 ]]; then
		echo -e "${TAB}${BAD}FAIL${NORMAL} (RETVAL = $RETVAL)"
		push_fail+="$repo "
	    else
		echo -e "${TAB}${GOOD}OK${NORMAL} (RETVAL = $RETVAL)"
	    fi

	    # check for modified files
	    if [[ ! -z $(git diff --name-only --diff-filter=M) ]]; then
		echo -e "modified: ${GRH}"
		git diff --name-only --diff-filter=M | sed "s/^/${TAB}/"
		echo -en "${NORMAL}"
		mods+="$repo "
	    fi

	else
	    echo -e "${BAD}FAIL${NORMAL} (RETVAL = $RETVAL)"
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
