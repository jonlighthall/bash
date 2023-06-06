#!/bin/bash
#
# update_repos.sh - push and pull a specified list of git repositories and print summaries
#
# JCL Apr 2022
#
# set tab
TAB=""

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
echo -e "${TAB}running ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
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
dir_examp="examp/"
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

# project
fname_project=${HOME}/${dir_script}bash/git/list_project_dir.txt
if [ -f ${fname_project} ]; then
    while IFS= read -r line
    do
	# evaluate each line to expand defined variable names
	eval line2=$line
	if [[ $line == $line2 ]]; then
	    list+=" ${line}"
	else
	    list+=" ${line2}"
	fi
    done < ${fname_project}
fi

script_ver=$(script --version | sed 's/[^0-9\.]//g')
script_ver_maj=$(echo $script_ver | awk -F. '{print $1}')
script_ver_min=$(echo $script_ver | awk -F. '{print $2}')
script_ver_pat=$(echo $script_ver | awk -F. '{print $3}')

git_ver=$(git --version | awk '{print $3}')
git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')

loc_fail=""
pull_fail=""
push_fail=""
mods=""

for repo in $list
do
    hline 70
    echo -e "locating ${PSDIR}$repo${NORMAL}... \c"
    if [ -e ${HOME}/$repo ]; then
	echo -e "${GOOD}OK${NORMAL}"
	cd ${HOME}/$repo
	echo -n "checking repository status... "
	git rev-parse --is-inside-work-tree &>/dev/null
	RETVAL=$?
	if [[ $RETVAL -eq 0 ]]; then
	    echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
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
	    echo "pulling... "
	    cmd="git pull -v --ff-only --all --tags --prune"
	    if [ $git_ver_maj -ge 2 ]; then
		cmd+=" -4"
	    fi
	    ${cmd}
	    RETVAL=$?
	    GIT_HIGHLIGHT='\x1b[100;37m'
	    echo -en "${GIT_HIGHLIGHT}pull status${NORMAL}: "
	    if [[ $RETVAL != 0 ]]; then
		echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
		pull_fail+="$repo "
	    else
		echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
	    fi
	    # push
	    echo "pushing... "
	    cmd="git push -v --progress"
	    if [ $git_ver_maj -ge 2 ]; then
		cmd+=" -4"
	    fi
	    ${cmd}
	    RETVAL=$?
	    echo -en "${GIT_HIGHLIGHT}push status${NORMAL}: "
	    if [[ $RETVAL != 0 ]]; then
		echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
		push_fail+="$repo "
	    else
		echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
	    fi

	    # check for modified files
	    if [[ ! -z $(git diff --name-only --diff-filter=M) ]]; then
		echo -e "modified: ${GRH}"
		git diff --name-only --diff-filter=M | sed "s/^/${TAB}/"
		echo -en "${NORMAL}"
		mods+="$repo "
	    fi
	else
	    echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
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
echo -e "\n$(date +"%a %b %d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
echo -e "\n$(date +"%a %b %d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
