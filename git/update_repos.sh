#!/bin/bash -u
#
# update_repos.sh - push and pull a specified list of git repositories and print summaries
#
# Apr 2022 JCL

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set tab
called_by=$(ps -o comm= $PPID)
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
	TAB=''
	: ${fTAB:='   '}
else
	TAB+=${TAB+${fTAB:='   '}}
fi

declare -i DEBUG=0

# conditional debug echo
decho() {
	if [ -z ${DEBUG:+dummy} ] || [ $DEBUG -gt 0 ]; then
		# if DEBUG is (unset or null) or greater than 0
		echo "$@"
	fi
}

# load formatting and functions
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
	source $fpretty
fi

# define traps
function set_traps() {
	decho -e "${magenta}\E[7mset traps${NORMAL}"
	decho "setting shell options..."
	if (return 0 2>/dev/null); then
		decho -e "${magenta}\E[7mreturn flags${NORMAL}"
		#		set -TE +e
	else
		decho -e "${magenta}\E[7mexit flags${NORMAL}"
		set -e
	fi
	set -E
	decho "the following traps are saved"
	if [ -z "${save_traps}" ]; then
		decho "${fTAB}none"

		decho "setting traps..."
		trap 'print_error $LINENO $? $BASH_COMMAND' ERR
		trap print_exit EXIT
		trap 'echo -e "${yellow}RETURN${NORMAL}: ${0##*/} $LINENO $? $BASH_COMMAND"' RETURN

	else
		decho "${save_traps}" | sed "s/^/${fTAB}/"
		decho "setting saved traps..."
		eval $(echo "${save_traps}" | sed "s/$/;/g")

		#eval $(echo '${save_traps}')
	fi
	decho "on set trap retrun, the following traps are set"
	if [ -z "$(trap -p)" ]; then
		decho "${fTAB}none"
		exit
	else
		decho $(trap -p | sed "s/^/${fTAB}/")
	fi
}

function unset_traps() {
	decho -e "${cyan}\E[7mun-set traps${NORMAL}"
	decho "setting shell options..."
	#	set +eET
	set +eE

	decho "the current traps are set"

	if [ -z "$(trap -p)" ]; then
		decho "${fTAB}none"
	else
		decho $(trap -p | sed "s/^/${fTAB}/")
		# save traps
		save_traps=$(trap -p | sed 's/-- //g')

		if [ ! -z "${save_traps}" ]; then
			decho "the current traps are saved"
			decho "${save_traps}" | sed "s/^/${fTAB}/"
		fi

		trap - ERR
		trap - EXIT
		trap - RETURN

	fi

	decho "on unset trap retrun, the following traps are set"
	if [ -z $(trap -p) ]; then
		decho "${fTAB}none"
	else
		decho $(trap -p)
		exit
	fi
}

set_traps

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
	RUN_TYPE="sourcing"
	set -TE +e
else
	RUN_TYPE="executing"
	# exit on errors
	set -eE
	# print note
	echo "NB: ${BASH_SOURCE##*/} has not been sourced"
	echo "    user SSH config settings MAY not be loaded??"
fi

# print run type and source name
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
	echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# print source path
## physical
src_dir_phys=${src_name%/*}
echo -e "${TAB}${gray}phys -> $src_dir_phys${NORMAL}"
## logical
src_dir_logi=${BASH_SOURCE%/*}
echo -e "${TAB}${gray}logi -> $src_dir_logi${NORMAL}"

# save and print starting directory
start_dir=$PWD
echo "starting directory = ${start_dir}"

# check if Git is defined
echo -n "${TAB}Checking Git... "
if command -v git &>/dev/null; then
	echo -e "${GOOD}OK${NORMAL} Git is defined"
else
	echo -e "${BAD}FAIL${NORMAL} Git not defined"
	if (return 0 2>/dev/null); then
		return 1
	else
		exit 1
	fi
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

# get Git version
git_ver=$(git --version | awk '{print $3}')
git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')

# declare counting variables
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
fetch_fail=''
pull_fail=''
push_fail=''
mod_repos=''
mod_files=''
unset OK_list
host_OK=''
host_bad=''

# track push/pull times (ns)
t_fetch_max=0
t_pull_max=0
t_push_max=0

# track push/pull times (s)
fetch_max=0

for repo in $list; do
	start_new_line
	hline 70

	#------------------------------------------------------
	# find
	#------------------------------------------------------
	echo -e "locating ${PSDIR}$repo${NORMAL}... \c"
	if [ -e ${HOME}/$repo ]; then
		echo -e "${GOOD}OK${NORMAL}"
		((++n_found))
		cd ${HOME}/$repo
		echo -n "checking repository status... "
		unset_traps
		git rev-parse --is-inside-work-tree &>/dev/null
		RETVAL=$?
		set_traps
		if [[ $RETVAL -eq 0 ]]; then
			echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
			((++n_git))
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
					((++n_match))
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

			# push/pull setting
			GIT_HIGHLIGHT='\E[7m'

			# print remote parsing
			decho -e "${TAB}remote tracking branch is ${blue}${remote_tracking_branch}${NORMAL}"
			decho "${TAB}remote name is $remote_name"
			decho "  remote ${remote_url}"

			# parse protocol
			remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
			if [[ "${remote_pro}" == "git" ]]; then
				remote_pro="SSH"
				rhost=$(echo ${remote_url} | sed 's/\(^[^:]*\):.*$/\1/')
				decho "    host $rhost"

				# default to checking host
				do_check=true
				decho "do_check = $do_check"

				# check remote host name against list of checked hosts
				if [ ! -z ${host_OK:+dummy} ]; then
					decho "checking $rhost against list of checked hosts"
					for good_host in ${host_OK}; do
						if [[ $rhost =~ $good_host ]]; then
							decho "$rhost matches $good_host"
							do_check=false
							break
						else
							continue
						fi
					done
				else
					decho "list of checked hosts empty"
				fi

				decho "do_check = $do_check"

				if [ ${do_check} = 'true' ]; then
					# check connection before proceeding
					echo "checking SSH connection..."
					unset_traps
					ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 -T ${rhost}
					RETVAL=$?
					set_traps
					if [[ $RETVAL == 0 ]]; then
						echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						# add to list
						if [ ! -z ${host_OK:+dummy} ]; then
							host_OK+=$'\n'
						fi
						host_OK+=${rhost}
					else
						if [[ $RETVAL == 1 ]]; then
							echo -e "${yellow}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"

							if [[ $rhost =~ "github.com" ]]; then
								decho "host is github"
								# Github will return 1 if everything is working

								# add to list
								if [ ! -z ${host_OK:+dummy} ]; then
									host_OK+=$'\n'
								fi
								host_OK+=${rhost}
							else
								decho "host is not github"
							fi
						else
							echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						fi
					fi
				fi
			fi
			decho "protocol ${remote_pro}"

			# get number of remotes
			n_remotes=$(git remote | wc -l)
			if [ "${n_remotes}" -gt 1 ]; then
				decho "remotes found: ${n_remotes}"
			fi

			#------------------------------------------------------
			# fetch
			#------------------------------------------------------
			decho "updating..."
			# specify number of seconds before kill
			nsec=2
			if [ $fetch_max -gt $nsec ]; then
				nsec=$fetch_max
			fi
			to="timeout -s 9 ${nsec}s "
			# concat commands
			cmd_base="${to} git remote"
			if [ -z ${DEBUG:+dummy} ] || [ $DEBUG -gt 0 ]; then
				cmd_base+=" --verbose"
			fi
			cmd="${cmd_base} update"
			RETVAL=137
			n_loops=0
			while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
				((++n_loops))
				if [ $n_loops -gt 1 ]; then
					echo "${TAB}FETCH attempt $n_loops..."
				fi
				t_start=$(date +%s%N)
				${cmd}
				RETVAL=$?
				t_end=$(date +%s%N)
				dt_fetch=$((${t_end} - ${t_start}))
				echo -en "${GIT_HIGHLIGHT} fetch ${NORMAL} "
				if [[ $RETVAL == 0 ]]; then
					echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					((++n_fetch))
				else
					echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					echo "failed to fetch remote"
					if [[ $RETVAL == 137 ]]; then
						nsec=$((nsec * 2))
						echo "${TAB}increasing fetch timeout to ${nsec}"
						to="timeout -s 9 ${nsec}s "
						cmd="${to}${cmd_base}"
					fi
				fi
			done
			
			# update maximum fetch time
			if [[ ${dt_fetch} -gt ${t_fetch_max} ]]; then
				t_fetch_max=${dt_fetch}
				# print maximum fetch time (in ns)
				echo "${TAB}${fTAB}new maximum fetch time"
				echo "${TAB}${fTAB}   raw time: $t_fetch_max ns"
				declare -i nd=${#t_fetch_max}

				# define number of "decimals" for ns timestamp
				declare -i nd_max=9

				# pad timestamp with leading zeros
				if [ $nd -lt $nd_max ]; then
					fmt="%0${nd_max}d"				
					declare -i time0=$(printf "$fmt" ${t_fetch_max})
					echo "${TAB}${fTAB}zero-padded: $time0"
					declare -i nd=${#time0}
					if [ $nd -eq ${nd_max} ]; then
						echo "${TAB}${fTAB}change in length"
						echo "${TAB}${fTAB}${nd} numbers long"
					else
						echo "${TAB}${fTAB}no change"
						exit 1
					fi
				else
					declare -i time0=t_fetch_max
				fi

				# format timestamp in s
				if [ $nd -gt $nd_max ]; then
					ni=$(($nd-$nd_max))
					ddeci=${time0:0:$ni}.${time0:$ni}
				else
					ddeci="0.${time0}"
				fi
				echo "${TAB}${fTAB}decimalized: $ddeci "

				# round timestamp to nearest second
				fmt="%.0f"			
				deci=$(printf "$fmt" ${ddeci})
				echo "${TAB}${fTAB}integerized: $deci "
				fetch_max=$deci				
			fi
			if [ $RETVAL -ne 0 ]; then
				fetch_fail+="$repo "
				echo -e "\E[32m> \E[0mWSL may need to be restarted"
				echo -e "\e[7;33mPress Ctrl-C to cancel\e[0m"
				read -e -i "shutdown_wsl" -p $'\e[0;32m$\e[0m ' -t 10 && eval $REPLY
			fi

			#------------------------------------------------------
			# pull
			#------------------------------------------------------
			decho -n "leading remote commits: "
			N_remote=$(git rev-list HEAD..${remote_tracking_branch} | wc -l)
			if [ ${N_remote} -eq 0 ]; then
				decho "none"
			else
				decho "${N_remote}"

				echo "pulling... "
				cmd_base="git pull --all --progress --tags --verbose" #--prune"
				if [ $git_ver_maj -ge 2 ]; then
					cmd_base+=" --ff-only --ipv4"
				fi
				# specify number of seconds before kill
				nsec=4
				to="timeout -s 9 ${nsec}s "
				# concat commands
				cmd="${to}${cmd_base}"
				RETVAL=137
				n_loops=0
				while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
					((++n_loops))
					if [ $n_loops -gt 1 ]; then
						echo "${TAB}PULL attempt $n_loops..."
					fi
					t_start=$(date +%s%N)
					${cmd}
					RETVAL=$?
					t_end=$(date +%s%N)
					dt_pull=$((${t_end} - ${t_start}))

					echo -en "${GIT_HIGHLIGHT} pull ${NORMAL} "
					if [[ $RETVAL != 0 ]]; then
						echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						# increase time
						if [[ $RETVAL == 137 ]]; then
							nsec=$((nsec * 2))
							echo "${TAB}increasing pull timeout to ${nsec}"
							to="timeout -s 9 ${nsec}s "
							cmd="${to}${cmd_base}"
						fi
						# force pull
						if [[ $RETVAL == 128 ]]; then
							cbar "${TAB}${GRH}should I force pull!? ${NORMAL}"
							echo -e "${TAB}source directory = $src_dir_logi"
							prog=${src_dir_logi}/force_pull
							if [ -f ${prog} ]; then
								bash ${prog}
								RETVAL2=$?
								echo -en "${TAB}${GRH}force_pull${NORMAL}: "
								if [[ $RETVAL != 0 ]]; then
									echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL3${NORMAL}"
									exit || return
								else
									echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL2${NORMAL}"
									((++n_fpull))
								fi
							fi
						fi
					else
						echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						((++n_pull))
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
			decho -n "trailing local commits: "
			N_local=$(git rev-list ${remote_tracking_branch}..HEAD | wc -l)
			if [ ${N_local} -eq 0 ]; then
				decho "none"
			else
				decho "${N_local}"

				echo "pushing... "
				cmd_base="git push --progress --verbose"
				if [ $git_ver_maj -ge 2 ]; then
					cmd_base+=" --ipv4"
				fi
				# specify number of seconds before kill
				nsec=2
				to="timeout -s 9 ${nsec}s "
				# concat commands
				cmd="${to}${cmd_base}"
				RETVAL=137
				n_loops=0
				while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
					((++n_loops))
					if [ $n_loops -gt 1 ]; then
						echo "${TAB}PUSH attempt $n_loops..."
					fi
					t_start=$(date +%s%N)
					${cmd}
					RETVAL=$?
					t_end=$(date +%s%N)
					dt_push=$((${t_end} - ${t_start}))

					echo -en "${GIT_HIGHLIGHT} push ${NORMAL} "
					if [[ $RETVAL != 0 ]]; then
						echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						if [[ $RETVAL == 137 ]]; then
							nsec=$((nsec * 2))
							echo "${TAB}increasing push timeout to ${nsec}"
							to="timeout -s 9 ${nsec}s "
							cmd="${to}${cmd_base}"
						fi
					else
						echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						((++n_push))
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
			echo "${TAB}$repo not a Git repository"
			loc_fail+="$repo "
		fi
	else
		echo "not found"
		loc_fail+="$repo "
		unset_traps
		bash test_file ${HOME}/$repo
		set_traps
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
list_indent='                '
tail -n +2 ${list_remote} | sed "s/^/${list_indent}/"
echo
echo -n "these remotes: "
OK_list=$(echo ${OK_list} | sed 's/ /\n/g' | sort -n)
echo "${OK_list}" | head -n 1
echo "${OK_list}" | tail -n +2 | sed "s/^/${list_indent}/"
echo

# print push/pull summary
# all
echo "    dirs found: ${n_found}"
echo "   repos found: ${n_git}"
echo -n "     not found: "
if [ -z "$loc_fail" ]; then
	echo "none"
else
	echo -e "${yellow}$loc_fail${NORMAL}"
fi

# matched
if [ $n_match -gt 0 ]; then
	echo "       matched: ${n_match} ($1)"
fi

# fetched
echo -n "       fetched: "
if [ ${n_fetch} -eq 0 ]; then
	echo "none"
else
	echo "$n_fetch"
	echo -n "fetch max time: ${t_fetch_max} ns"
	if command -v bc &>/dev/null; then
		echo " or $(bc <<<"scale=3;$t_fetch_max/1000000000") sec"
	else
		echo
	fi	
fi
echo -n "fetch failures: "
if [ -z "$fetch_fail" ]; then
	echo "none"
else
	echo -e "${GRH}$fetch_fail${NORMAL}"
fi

# pull
echo -n "  repos pulled: "
if [ ${n_pull} -eq 0 ]; then
	echo "none"
else
	echo "${n_pull}"
	echo -n "pull max time: ${t_pull_max} ns"
	if command -v bc &>/dev/null; then
		echo " or $(bc <<<"scale=3;$t_pull_max/1000000000") sec"
	else
		echo
	fi
fi
echo -n " pull failures: "
if [ -z "$pull_fail" ]; then
	echo "none"
else
	echo -e "${GRH}$pull_fail${NORMAL}"
fi

echo -n "   force pulls: "
if [ $n_fpull -eq 0 ]; then
	echo "none"
else
	echo -e "${yellow}$n_fpull${NORMAL}"
fi

# push
echo -n "  repos pushed: "
if [ $n_push -eq 0 ]; then
	echo "none"
else
	echo "${n_push}"
	echo -n " push max time: ${t_push_max} ns"
	if command -v bc &>/dev/null; then
		echo " or $(bc <<<"scale=3;$t_push_max/1000000000") sec"
	else
		echo
	fi	
fi
echo -n " push failures: "
if [ -z "$push_fail" ]; then
	echo "none"
else
	echo -e "${GRH}$push_fail${NORMAL}"
fi

# modified
echo -n "      modified: "
if [ -z "$mod_repos" ]; then
	echo "none"
else
	echo "$mod_repos"
	echo -e "${GRH}$mod_files${NORMAL}" | sed "s/^/${list_indent}/"
fi
