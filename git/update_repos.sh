#!/bin/bash -u
#
# update_repos.sh - push and pull a specified list of git repositories and print summaries
#
# Apr 2022 JCL

# start timer
start_time=$(date +%s%N)

# set tab
called_by=$(ps -o comm= $PPID)
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
	TAB=''
	: ${fTAB:='	'}
else
	TAB+=${TAB+${fTAB:='	'}}
fi

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
	source $fpretty
fi

function timestamp() {
	echo "$(date +"%a %b %-d at %-l:%M %p %Z")"
}

function print_elap() {
	end_time=$(date +%s%N)
	elap_time=$((${end_time} - ${start_time}))
	if command -v bc &>/dev/null; then
		dT_sec=$(bc <<<"scale=3;$elap_time/1000000000")
	else
		dT_sec=${elap_time::-9}
	fi
	if command -v sec2elap &>/dev/null; then
		bash sec2elap $dT_sec | tr -d "\n"
	else
		echo -n "elapsed time is ${white}${dT_sec} sec${NORMAL}"
	fi
}

function print_exit() {
	echo -e "${yellow}EXIT${NORMAL}: ${BASH_SOURCE##*/}"
	print_elap
	echo -n " on "
	timestamp
}

function print_error() {
	# expected arguments are $LINENO $? $BASH_COMMAND

	# parse arguments
	ERR_LINENO=$1
	shift
	ERR_RETVAL=$1
	shift
	ERR_CMD="$@"

	# print arguments
	echo "line:   $ERR_LINENO"
	echo "retval: $ERR_RETVAL"
	echo "cmd:    ${ERR_CMD}"

	# print summary
	spc='       '
	echo -e "${BAD}ERROR${NORMAL}: ${BASH_SOURCE##*/}"
	echo -e "${spc}on line $ERR_LINENO"
	echo -ne "line contents: "
	sed -n "${ERR_LINENO}p" $src_name | sed "s/^\s*/${spc}${GRL}/"
	echo -ne "evaluates to : "
	eval echo $ERR_CMD
	echo -ne "with return value: "
	echo -e "${spc}${gray}RETVAL=${ERR_RETVAL}${NORMAL}"
}

# print source name at start
if (return 0 2>/dev/null); then
	RUN_TYPE="sourcing"
	set -TE +e
	trap 'echo -en "${yellow}RETURN${NORMAL}: ${BASH_SOURCE##*/} "' RETURN
else
	RUN_TYPE="executing"
	# exit on errors
	set -eE
	trap 'print_error $LINENO $? $BASH_COMMAND' ERR
	# print time at exit
	trap print_exit EXIT
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
	echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi
src_dir=${src_name%/*}
echo -e "${TAB}${gray}path =  $src_dir${NORMAL}"

src_dir=${BASH_SOURCE%/*}
echo -e "${TAB}${gray}path = $src_dir${NORMAL}"

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
	while IFS= read -r line; do
		# evaluate each line to expand defined variable names
		eval line2=$line
		if [[ $line == $line2 ]]; then
			list+=" ${line}"
		else
			list+=" ${line2}"
		fi
	done <${fname_private}
fi

# project
fname_project=${HOME}/${dir_script}bash/git/list_project_dir.txt
if [ -f ${fname_project} ]; then
	while IFS= read -r line; do
		# evaluate each line to expand defined variable names
		eval line2=$line
		if [[ $line == $line2 ]]; then
			list+=" ${line}"
		else
			list+=" ${line2}"
		fi
	done <${fname_project}
fi

script_ver=$(script --version | sed 's/[^0-9\.]//g')
script_ver_maj=$(echo $script_ver | awk -F. '{print $1}')
script_ver_min=$(echo $script_ver | awk -F. '{print $2}')
script_ver_pat=$(echo $script_ver | awk -F. '{print $3}')

# check if Git is defined
echo -n "${TAB}Checking Git... "
if command -v git &>/dev/null; then
	echo -e "${GOOD}OK${NORMAL} Git is defined"
else
	echo -e "${BAD}FAIL${NORMAL} Git not defined"
	if (return 0 2>/dev/null); then
		return
	else
		exit 1
	fi
fi

# get Git version
git_ver=$(git --version | awk '{print $3}')
git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')

# decleare counting variables
declare -i n_fetch=0
declare -i n_found=0
declare -i n_fpull=0
declare -i n_git=0
declare -i n_loops=0
declare -i n_match=0
declare -i n_pull=0
declare -i n_push=0

# list failures and modifications
loc_fail=''
pull_fail=''
push_fail=''
mod_repos=''
mod_files=''
unset OK_list

# track push/pull times
t_pull_max=0
t_push_max=0

for repo in $list; do
	hline 70

	#------------------------------------------------------
	# find
	#------------------------------------------------------
	echo -e "locating ${PSDIR}$repo${NORMAL}... \c"
	if [ -e ${HOME}/$repo ]; then
		echo -e "${GOOD}OK${NORMAL}"
		: $((n_found++))
		cd ${HOME}/$repo
		echo -n "checking repository status... "
		set +e
		git rev-parse --is-inside-work-tree &>/dev/null
		if ! (return 0 2>/dev/null); then
			set -e
		fi
		RETVAL=$?
		if [[ $RETVAL -eq 0 ]]; then
			echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
			: $((n_git++))
			# parse remote
			if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
				echo "${TAB}no remote tracking branch set for current branch"
				continue
			else
				remote_tracking_branch=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
				remote_name=${remote_tracking_branch%%/*}
				remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
				# add remote to list
				echo "${remote_url}" >>${list_remote}
			fi

			# check against argument
			if [ $# -gt 0 ]; then
				echo -n "matching argument ""$1""... "
				if [[ $remote_url =~ $1 ]]; then
					echo -e "${GOOD}OK${NORMAL}"
					: $((n_match++))
				else
					echo -e "${gray}SKIP${NORMAL}"
					continue
				fi
			fi

			# add to list
			if [ ! -z ${OK_list:+dummy} ]; then
				OK_list+=$'\n'
			fi
			OK_list+=${remote_url}

			# print remote parsing
			echo -e "${TAB}remote tracking branch is ${blue}${remote_tracking_branch}${NORMAL}"
			echo "${TAB}remote name is $remote_name"
			echo "  remote ${remote_url}"

			remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
			if [[ "${remote_pro}" == "git" ]]; then
				remote_pro="SSH"
			fi
			echo "protocol ${remote_pro}"

			# get number of remotes
			n_remotes=$(git remote | wc -l)
			if [ "${n_remotes}" -gt 1 ]; then
				echo "remotes found: ${n_remotes}"
			fi

			# push/pull setting
			GIT_HIGHLIGHT='\x1b[100;37m'

			#------------------------------------------------------
			# fetch
			#------------------------------------------------------
			echo "updating..."
			git remote --verbose update

			RETVAL=$?
			if [[ $RETVAL == 0 ]]; then
				echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
				: $((n_fetch++))
			else
				echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
				echo "failed to fetch remote"
				echo "WSL may need to be restarted"
				echo "Press Ctrl-C to cancle"
				read -e -i "shutdown_wsl" && eval "$REPLY"
			fi

			#------------------------------------------------------
			# pull
			#------------------------------------------------------
			echo -n "leading remote commits: "
			N_remote=$(git rev-list HEAD..${remote_tracking_branch} | wc -l)
			if [ ${N_remote} -eq 0 ]; then
				echo "none"
			else
				echo "${N_remote}"

				echo "pulling... "
				cmd_base="git pull --all --progress --tags --verbose" #--prune"
				if [ $git_ver_maj -ge 2 ]; then
					cmd_base+=" --ff-only --ipv4"
				fi
				# secify number of seconds before kill
				nsec=4
				to="timeout -s 9 ${nsec}s "
				# concat commands
				cmd="${to}${cmd_base}"
				RETVAL=137
				n_loops=0
				while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
					: $((n_loops++))
					if [ $n_loops -gt 1 ]; then
						echo "${TAB}PULL attempt $n_loops..."
					fi
					t_start=$(date +%s%N)
					${cmd}
					RETVAL=$?
					t_end=$(date +%s%N)
					dt_pull=$((${t_end} - ${t_start}))

					echo -en "${GIT_HIGHLIGHT}pull${NORMAL}: "
					if [[ $RETVAL != 0 ]]; then
						echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						# increase time
						if [[ $RETVAL == 137 ]]; then
							nsec=$((nsec * 2))
							echo "${TAB}increasing timeout to ${nsec}"
							to="timeout -s 9 ${nsec}s "
							cmd="${to}${cmd_base}"
						fi
						# force pull
						if [[ $RETVAL == 128 ]]; then
							cbar "${TAB}${GRH}should I force pull!? ${NORMAL}"
							echo -e "${TAB}source directory = $src_dir"
							prog=${src_dir}/force_pull
							if [ -f ${prog} ]; then
								bash ${prog}
								RETVAL2=$?
								echo -en "${TAB}${GRH}force_pull${NORMAL}: "
								if [[ $RETVAL != 0 ]]; then
									echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL3${NORMAL}"
									exit || return
								else
									echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL2${NORMAL}"
									: $((n_fpull++))
								fi
							fi
						fi
					else
						echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						: $((n_pull++))
					fi
				done
				if [[ ${dt_pull} -gt ${t_pull_max} ]]; then
					t_pull_max=${dt_pull}
				fi
				if [[ $RETVAL != 0 ]]; then
					# add to failure list
					pull_fail+="$repo "
				else
					# update links after pull
					prog=make_links.sh
					if [ -f ${prog} ]; then
						if [[ ! (("$(hostname -f)" == *"navy.mil") && ($repo =~ "private")) ]]; then
							bash ${prog}
						fi
					fi
				fi
			fi

			#------------------------------------------------------
			# push
			#------------------------------------------------------
			echo -n "trailing local commits: "
			N_local=$(git rev-list ${remote_tracking_branch}..HEAD | wc -l)
			if [ ${N_local} -eq 0 ]; then
				echo "none"
			else
				echo "${N_local}"

				echo "pushing... "
				cmd_base="git push --progress --verbose"
				if [ $git_ver_maj -ge 2 ]; then
					cmd_base+=" --ipv4"
				fi
				# secify number of seconds before kill
				nsec=2
				to="timeout -s 9 ${nsec}s "
				# concat commands
				cmd="${to}${cmd_base}"
				RETVAL=137
				n_loops=0
				while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
					: $((n_loops++))
					if [ $n_loops -gt 1 ]; then
						echo "${TAB}PUSH attempt $n_loops..."
					fi
					t_start=$(date +%s%N)
					${cmd}
					RETVAL=$?
					t_end=$(date +%s%N)
					dt_push=$((${t_end} - ${t_start}))

					echo -en "${GIT_HIGHLIGHT}push${NORMAL}: "
					if [[ $RETVAL != 0 ]]; then
						echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						if [[ $RETVAL == 137 ]]; then
							nsec=$((nsec * 2))
							echo "${TAB}increasing timeout to ${nsec}"
							to="timeout -s 9 ${nsec}s "
							cmd="${to}${cmd_base}"
						fi
					else
						echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						: $((n_push++))
					fi
				done
				if [[ ${dt_push} -gt ${t_push_max} ]]; then
					t_push_max=${dt_push}
				fi
				if [[ $RETVAL != 0 ]]; then
					# add to failure list
					push_fail+="$repo "
				fi
			fi

			# check for modified files
			unset list_mod
			list_mod=$(git diff --name-only --diff-filter=M)
			if [[ ! -z "${list_mod}" ]]; then
				# print file list
				echo -e "modified: ${GRH}"
				echo "${list_mod}" | sed "s/^/${fTAB}/"
				echo -en "${NORMAL}"
				# add repo to list
				mod_repos+="$repo "
				# add to files to list
				if [ ! -z ${mod_files:+dummy} ]; then
					mod_files+=$'\n'
				fi
				mod_files+=$(echo "${list_mod}" | sed "s;^;${repo}/;")
			fi
		else
			echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
			echo "${TAB}$repo not a Git repository"
			loc_fail+="$repo "
		fi
	else
		echo "not found"
		loc_fail+="$repo "
		set +e
		bash test_file ${HOME}/$repo
		if ! (return 0 2>/dev/null); then
			set -e
		fi
	fi
done

cbar "done updating repositories"
echo "returning to starting directory ${start_dir}..."
cd ${start_dir}

# sort and uniquify remotes list
sort -u ${list_remote} -o ${list_remote}

# print list of remotes
echo -n "  all remotes: "
head -n 1 ${list_remote}
list_indent='               '
tail -n +2 ${list_remote} | sed "s/^/${list_indent}/"
echo
echo -n "these remotes: "
OK_list=$(echo ${OK_list} | sed 's/ /\n/g' | sort -n)
echo "${OK_list}" | head -n 1
echo "${OK_list}" | tail -n +2 | sed "s/^/${list_indent}/"
echo

# print push/pull summary
# all
echo "   dirs found: ${n_found}"
echo "  repos found: ${n_git}"
echo -n "    not found: "
if [ -z "$loc_fail" ]; then
	echo "none"
else
	echo "$loc_fail"
fi

# matched
if [ $n_match -gt 0 ]; then
	echo "      matched: ${n_match} ($1)"
fi

# fetched
echo -n "      fetched: "
if [ ${n_fetch} -eq 0 ]; then
	echo "none"
else
	echo "$n_fetch"
fi

# pull
echo -n " repos pulled: "
if [ ${n_pull} -eq 0 ]; then
	echo "none"
else
	echo "${n_pull}"
	echo -n "pull failures: "
	if [ -z "$pull_fail" ]; then
		echo "none"
	else
		echo -e "${GRH}$pull_fail${NORMAL}"
	fi	
	echo "pull max time: ${t_pull_max} ns or $(bc <<<"scale=3;$t_pull_max/1000000000") sec"
fi
echo -n "  force pulls: "
if [ $n_fpull -eq 0 ]; then
	echo "none"
else
	echo -e "${yellow}$n_fpull${NORMAL}"
fi

# push
echo -n " repos pushed: "
if [ $n_push -eq 0 ]; then
	echo "none"
else
	echo "${n_push}"
	echo -n "push failures: "
	if [ -z "$push_fail" ]; then
		echo "none"
	else
		echo -e "${GRH}$push_fail${NORMAL}"
	fi
	echo "push max time: ${t_push_max} ns or $(bc <<<"scale=3;$t_push_max/1000000000") sec"
fi

# modified
echo -n "     modified: "
if [ -z "$mod_repos" ]; then
	echo "none"
else
	echo "$mod_repos"
	echo -e "${GRH}$mod_files${NORMAL}" | sed "s/^/${list_indent}/"
fi
