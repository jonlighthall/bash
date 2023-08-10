#!/bin/bash
#
# update_repos.sh - push and pull a specified list of git repositories and print summaries
#
# Apr 2022 JCL

# set tab
called_by=$(ps -o comm= $PPID)
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
    TAB=''
else
    TAB+=${TAB+${fTAB:='   '}}
fi

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

if ! (return 0 2>/dev/null); then
    echo "NB: ${BASH_SOURCE##*/} has not been sourced"
    echo "    user SSH config settings MAY not be loaded??"
fi

start_dir=$PWD
echo "starting directory = ${start_dir}"

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

# track failures and modifications
loc_fail=''
pull_fail=''
push_fail=''
mods=''
unset OK_list

# track push/pull times
t_pull_max=0
t_push_max=0
n=0
loop_counter=0

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
	    this_remote=$(git remote -v | awk -F " " '{print $2}' | uniq)
	    echo "  remote: ${this_remote}"
	    echo "${this_remote}" >> ${list_remote}
	    proto=$(echo ${this_remote} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
	    echo "protocol: ${proto}"

	    n_remotes=$(echo ${this_remote} | wc -l)

	    if [ "${n_remotes}" -gt 1 ]; then
		echo "${n_remotes} remotes found"
	    fi

	    # check against argument
	    if [ $# -gt 0 ]; then
		echo -n "matching argument ""$1""... "
		url=$(git remote -v | head -n 1 | awk '{print $2}')
		if [[ $url =~ $1 ]]; then
		    echo -e "${GOOD}OK${NORMAL}"
		    # add to list
		    if [ ! -z ${OK_list:+dummy} ]; then
			OK_list+=$'\n'
		    fi
		    OK_list+=${this_remote}
		else
		    echo "skipping..."
		    continue
		fi
	    else
		# add to list
		if [ ! -z ${OK_list:+dummy} ]; then
		    OK_list+=$'\n'
		fi
		OK_list+=${this_remote}
	    fi

            # push/pull setting
	    GIT_HIGHLIGHT='\x1b[100;37m'
	    nsec=4
	    to="timeout -s 9 ${nsec}s "

	    #------------------------------------------------------
	    # pull
	    #------------------------------------------------------
	    echo "pulling... "
	    cmd="${to}git pull -v --ff-only" # --all --tags --prune"
	    if [ $git_ver_maj -ge 2 ]; then
		cmd+=" -4"
	    fi
	    RETVAL=137
	    loop_counter=0
	    while [ $RETVAL -eq 137 ] && [ $loop_counter -lt 5 ]; do
		((loop_counter++))
		if [ $loop_counter -gt 1 ]; then
		    echo "${TAB}PULL attempt $loop_counter..."
		fi
		t_start=$(date +%s%N)
		${cmd}
		RETVAL=$?
		t_end=$(date +%s%N)
		dt_pull=$(( ${t_end} - ${t_start} ))

		echo -en "${GIT_HIGHLIGHT}pull${NORMAL}: "
		if [[ $RETVAL != 0 ]]; then
		    echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
		    #pull_fail+="$repo "
		else
		    echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
		    ((n++))
		fi
	    done
	    if [[ ${dt_pull} -gt ${t_pull_max} ]]; then
		t_pull_max=${dt_pull}
	    fi
	    if [[ $RETVAL != 0 ]]; then
		pull_fail+="$repo "
	    else
		prog=make_links.sh
		if [ -f ${prog} ]; then
		   : #./${prog}
		fi
	    fi

	    # secify number of seconds before kill
	    nsec=2
            #------------------------------------------------------
	    # push
	    #------------------------------------------------------
	    echo "pushing... "
	    to="timeout -s 9 ${nsec}s "
	    cmd="${to}git push -v --progress"
	    if [ $git_ver_maj -ge 2 ]; then
		cmd+=" -4"
	    fi
	    RETVAL=137
	    loop_counter=0
	    while [ $RETVAL -eq 137 ] && [ $loop_counter -lt 5 ]; do
		((loop_counter++))
		if [ $loop_counter -gt 1 ]; then
		    echo "${TAB}PUSH attempt $loop_counter..."
		fi
		t_start=$(date +%s%N)
		${cmd}
		RETVAL=$?
		t_end=$(date +%s%N)
		dt_push=$(( ${t_end} - ${t_start} ))
		echo -en "${GIT_HIGHLIGHT}push${NORMAL}: "
		if [[ $RETVAL != 0 ]]; then
		    echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
		    #push_fail+="$repo "
		else
		    echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
		fi
		((nsec++))
		if [ $loop_counter -gt 1 ]; then
		    echo "${TAB}increasing timeout to ${nsec}"
		fi
	    done
	    if [[ ${dt_push} -gt ${t_push_max} ]]; then
		t_push_max=${dt_push}
	    fi
	    if [[ $RETVAL != 0 ]]; then
		push_fail+="$repo "
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
#    hline 70
 #   echo
done

echo "done updating repositories"
echo "returning to starting directory..."
cd ${starting_dir}

# sort and uniquify remotes list
sort -u ${list_remote} -o ${list_remote}

# print list of remotes
echo -n "      remotes: "
head -n 1 ${list_remote}
tail -n +2 ${list_remote} | sed 's/^/               /'
echo
echo "${OK_list}"
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

echo "max times (N=$n)"
echo "${TAB}pull: ${t_pull_max} ns or $(bc <<< "scale=3;$t_pull_max/1000000000") sec"
echo "${TAB}push: ${t_push_max} ns or $(bc <<< "scale=3;$t_push_max/1000000000") sec"

# print time at exit
echo -en "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} "
if command -v sec2elap &>/dev/null; then
    sec2elap ${SECONDS}
else
    echo "elapsed time is ${SECONDS} sec"
fi
