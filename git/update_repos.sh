#!/bin/bash -u
#
# update_repos.sh - push and pull a specified list of git repositories and print summaries
#
# Apr 2022 JCL

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set tab
called_by=$(ps -o comm= $PPID)
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ] || [[ "${called_by}" == "Relay"* ]] ; then
	TAB=''
	: ${fTAB:='   '}
else
	TAB+=${TAB+${fTAB:='   '}}
fi

# set debug level
declare -i DEBUG=0

# load formatting and functions
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	set_traps
fi

decho "DEBUG = $DEBUG"

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
	RUN_TYPE="sourcing"
	set -T +e
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
if [ -z "${check_git:+dummy}" ]; then
	echo -n "${TAB}Checking Git... "
	if command -v git &>/dev/null; then
		echo -e "${GOOD}OK${NORMAL} Git is defined"
		# get Git version
		git --version | sed "s/^/${fTAB}/"
		git_ver=$(git --version | awk '{print $3}')
		git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
		git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
		git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')
		export check_git=false
	else
		echo -e "${BAD}FAIL${NORMAL} Git not defined"
		if (return 0 2>/dev/null); then
			return 1
		else
			exit 1
		fi
	fi
fi

# list repository paths, relative to home
# settings
list="config "
if [[ ! ("$(hostname -f)" == *"navy.mil")  ]]; then
	list+=" config/private "
fi

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

# declare counting variables
declare -i n_fetch=0
declare -i n_found=0
declare -i n_fpull=0
declare -i n_git=0
declare -i n_loops=0
declare -i n_match=0
declare -i n_pull=0
declare -i n_push=0

# reset SSH status list
export host_bad=''
export host_OK=''

# list failures
loc_fail=''
fetch_fail=''
pull_fail=''
push_fail=''

# list successes
loc_OK=''
git_OK=''
fetch_OK=''
pull_OK=''
push_OK=''

# list modifications
mod_repos=''
mod_files=''

# list stash
stash_list=''

# track push/pull times (ns)
t_fetch_max=0
t_pull_max=0
t_push_max=0

# track push/pull times (s)
fetch_max=0

# define timeout command
timeout_ver=$(timeout --version | head -1 | sed 's/^.*) //')
declare -ir timeout_ver_maj=$(echo $timeout_ver | awk -F. '{print $1}')
declare -ir timeout_ver_min=$(echo $timeout_ver | awk -F. '{print $2}')
to_base0="timeout"
if [[ $timeout_ver_min -gt 4 ]]; then
	to_base0+=" --foreground --preserve-status"
fi
to_base0+=" -s 9"
declare -r to_base="${to_base0}"

# beautify settings
GIT_HIGHLIGHT='\E[7m'
function set_color () {
	echo -ne "\e[38;5;11m"
}
function unset_color () {
	echo -ne "\e[0m"
}

function do_cmd () {
	cmd=$(echo $@)
	set_color
	$cmd 2>&1
	RETVAL=$?
	unset_color
	return $RETVAL
}

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
			remote_tracking_branch=$(git rev-parse --abbrev-ref @{upstream})
			if [ -z ${remote_tracking_branch+default} ]; then
				echo "${TAB}no remote tracking branch set for current branch"
				continue
			else
				upstream_repo=${remote_tracking_branch%%/*}
				if [ $git_ver_maj -lt 2 ]; then
					upstream_url=$(git remote -v | grep ${upstream_repo} | awk '{print $2}' | uniq)
				else
					upstream_url=$(git remote get-url ${upstream_repo})
				fi
				# add remote to list
				echo "${upstream_url}" >>${list_remote}
			fi

			# check against argument
			if [ $# -gt 0 ]; then
				echo -n "matching argument ""$1""... "
				if [[ $upstream_url =~ $1 ]]; then
					echo -e "${GOOD}OK${NORMAL}"
					((++n_match))
				else
					echo -e "${gray}SKIP${NORMAL}"
					continue
				fi
			fi

			# add to list
			if [ ! -z ${git_OK:+dummy} ]; then
				git_OK+=$'\n'
			fi
			git_OK+=${upstream_url}

			# check remotes
			if [ $DEBUG -ge 0 ]; then
				cbar "${BOLD}check remotes...${NORMAL}"
			fi
			source "${src_dir_phys}/check_repos.sh"

			# parse remote
			upstream_refspec=${remote_tracking_branch#*/}
			# print remote parsing
			if [ $DEBUG -ge 0 ]; then
				cbar "${BOLD}parse remote tracking branch...${NORMAL}"
				(
					echo -e "${TAB}remote tracking branch+ ${blue}${remote_tracking_branch}${NORMAL}"
					echo "${TAB}${fTAB}remote name+ $upstream_repo"
					echo "${TAB}${fTAB}remote refspec+ $upstream_refspec"
				) | column -t -s+ -o : -R 1

			fi

			# parse protocol
			upstream_pro=$(echo ${upstream_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
			if [[ "${upstream_pro}" == "git" ]]; then
				upstream_pro="SSH"
				upstream_host=$(echo ${upstream_url} | sed 's/\(^[^:]*\):.*$/\1/')
			else
				upstream_host=$(echo ${upstream_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
				if [[ ! "${upstream_pro}" == "http"* ]]; then
					upstream_pro="local"
				fi
			fi

			# check remote host name against list of checked hosts
			decho "checking $upstream_host against list of checked hosts"
			if [ ! -z ${host_OK:+dummy} ]; then
				for OK_host in ${host_OK}; do
					if [[ "$upstream_host" == "$OK_host" ]]; then
						decho "$upstream_host matches $OK_host"
						host_stat=$(echo -e "${GOOD}OK${NORMAL}")
						break
					fi
				done
			fi

			if [ ! -z ${host_bad:+dummy} ]; then
				for bad_host in ${host_bad}; do
					if [[ "$upstream_host" == "$bad_host" ]]; then
						decho "$upstream_host matches $bad_host"
						fetch_fail+="$repo ($upstream_repo)"
						host_stat=$(echo -e "${BAD}BAD{NORMAL}")
						break
					fi
				done
			fi

			# print host parsing
			if [ $DEBUG -ge 0 ]; then
				cbar "${BOLD}parse remote host...${NORMAL}"
				(
					echo "${TAB}upsream url+ ${upstream_url}"
					echo -e "${TAB}${fTAB} host+ $upstream_host ${host_stat}"
  					echo -e "${TAB}${fTAB}proto+ ${upstream_pro}"
				) | column -t -s+ -o : -R 1
			fi

			if [[ "$host_stat" =~ *"FAIL"* ]]; then
				decho "skipping fetch..."
				continue
			else
				decho "proceeding with fetch..."
			fi			

			#------------------------------------------------------
			# fetch
			#------------------------------------------------------
			decho "updating..."
			# specify number of seconds before kill
			nsec=3
			if [ $fetch_max -gt $nsec ]; then
				nsec=$fetch_max
			fi
			to="${to_base} ${nsec}s "
			# concat commands
			cmd_base="git fetch"
			if [ -z ${DEBUG:+dummy} ] || [ $DEBUG -gt 0 ]; then
				cmd_base+=" --verbose"
			fi
			cmd="${to}${cmd_base}"
			RETVAL=137
			n_loops=0
			while [ $n_loops -lt 5 ]; do
				((++n_loops))
				if [ $n_loops -gt 1 ]; then
					echo "${TAB}FETCH attempt $n_loops..."
				fi
				t_start=$(date +%s%N)
				do_cmd ${cmd}
				RETVAL=$?
				t_end=$(date +%s%N)
				dt_fetch=$((${t_end} - ${t_start}))
				echo -en "${GIT_HIGHLIGHT} fetch ${NORMAL} "
				if [[ $RETVAL == 0 ]]; then
					echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					((++n_fetch))
					break
				else
					echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					echo "failed to fetch remote"
					if [[ $RETVAL == 137 ]]; then
						if [ $nsec -gt $fetch_max ]; then
							fetch_max=$nsec
							echo "${TAB}increasing fetch_max to $fetch_max"
						fi
						nsec=$((nsec * 2))
						echo "${TAB}increasing fetch timeout to ${nsec}"
						to="${to_base} ${nsec}s "
						cmd="${to}${cmd_base} --verbose --all"
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
					declare time0=$(printf "$fmt" ${t_fetch_max})
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
				if [ $deci -gt $fetch_max ]; then
					fetch_max=$deci
				fi
				echo "     fetch_max: $fetch_max"
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
				to="${to_base} ${nsec}s "
				# concat commands
				cmd="${to}${cmd_base}"
				RETVAL=137
				n_loops=0
				while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
					((++n_loops))
					if [ $n_loops -gt 1 ]; then
						echo "${TAB}PULL attempt $n_loops..."
					fi
					set_color
					t_start=$(date +%s%N)
					${cmd}
					RETVAL=$?
					t_end=$(date +%s%N)
					unset_color
					dt_pull=$((${t_end} - ${t_start}))

					echo -en "${GIT_HIGHLIGHT} pull ${NORMAL} "
					if [[ $RETVAL != 0 ]]; then
						echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						# increase time
						if [[ $RETVAL == 137 ]]; then
							nsec=$((nsec * 2))
							echo "${TAB}increasing pull timeout to ${nsec}"
							to="${to_base} ${nsec}s "
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
						if [ ! -z ${pull_OK:+dummy} ]; then
							pull_OK+=$'\n'"$repo"
						else
							pull_OK+="$repo"
						fi

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
				to="${to_base} ${nsec}s "
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
					do_cmd ${cmd}
					RETVAL=$?
					t_end=$(date +%s%N)
					dt_push=$((${t_end} - ${t_start}))

					echo -en "${GIT_HIGHLIGHT} push ${NORMAL} "
					if [[ $RETVAL != 0 ]]; then
						echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						if [[ $RETVAL == 137 ]]; then
							nsec=$((nsec * 2))
							echo "${TAB}increasing push timeout to ${nsec}"
							to="${to_base} ${nsec}s "
							cmd="${to}${cmd_base}"
						fi
					else
						echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
						((++n_push))
						if [ ! -z ${push_OK:+dummy} ]; then
							push_OK+=$'\n'"$repo"
						else
							push_OK+="$repo"
						fi

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
				echo -e "modified: ${yellow}"
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

			# check for stash entries
			N_stash=$(git stash list | wc -l)
			if [ $N_stash -gt 0 ]; then
				echo -e "$repo has $N_stash entries in stash"
				if [ ! -z ${stash_list:+dummy} ]; then
					stash_list+=$'\n'
				fi
				stash_list+=$(printf '%2d %s' $N_stash $repo)
			fi
		else
			echo "${TAB}$repo not a Git repository"
			if [ ! -z ${loc_fail:+dummy} ]; then
				loc_fail+=$'\n'"$repo"
			else
				loc_fail+="$repo"
			fi
		fi
	else
		echo "not found"
		if [ ! -z ${loc_fail:+dummy} ]; then
			loc_fail+=$'\n'"$repo"
		else
			loc_fail+="$repo"
		fi
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
echo -n "   all remotes: "
head -n 1 ${list_remote}
list_indent='                '
tail -n +2 ${list_remote} | sed "s/^/${list_indent}/"
echo
echo -n " these remotes: "
if [ -z "$git_OK" ]; then
	echo "none"
else
	git_OK=$(echo ${git_OK} | sed 's/ /\n/g' | sort -n)
	echo "${git_OK}" | head -n 1
	echo "${git_OK}" | tail -n +2 | sed "s/^/${list_indent}/"
	echo
fi

# print good hosts
if [ $DEBUG -ge 0 ]; then
	echo -n "${TAB}    good hosts: "
	if [ -z "${host_OK:+dummy}" ]; then
		echo "none"
	else
		host_OK=$(echo "${host_OK}" | sort -n)
		echo -e "${GOOD}${host_OK}${NORMAL}" | head -n 1
		echo -e "${GOOD}${host_OK}${NORMAL}" | tail +2 | sed "s/^/${list_indent}/"
	fi

	# print bad hosts
	echo -ne "\n${TAB}     bad hosts: "
	if [ -z "$host_bad" ]; then
		echo "none"
	else
		host_bad=$(echo "${host_bad}" | sort -n)
		echo -e "${BAD}${host_bad}${NORMAL}" | head -n 1
		echo -e "${BAD}${host_bad}${NORMAL}" | tail -n +2 | sed "s/^/${list_indent}/"
	fi
fi

echo

# print push/pull summary
# all
echo "    dirs found: ${n_found}"
echo "   repos found: ${n_git}"
echo -n "     not found: "
if [ -z "$loc_fail" ]; then
	echo "none"
else
	echo -ne "${red}"
	echo "${loc_fail}" | head -n 1
	echo "${loc_fail}" | tail -n +2 | sed "s/^/${list_indent}/"
	echo -ne "${NORMAL}"
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

	echo -ne "${green}"
	echo "${pull_OK}" | sed "s/^/${list_indent}/"
	echo -ne "${NORMAL}"

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

	echo -ne "${green}"
	echo "${push_OK}" | sed "s/^/${list_indent}/"
	echo -ne "${NORMAL}"

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
	echo -e "${yellow}$mod_files${NORMAL}" | sed "s/^/${list_indent}/"
fi

# stash
echo -n " stash entries: "
if [ -z "$stash_list" ]; then
	echo "none"
else
	stash_list=$(echo "${stash_list}" | sort -n)
	echo "${stash_list}" | head -n 1
	echo "${stash_list}" | tail -n +2 | sed "s/^/${list_indent}/"
fi
