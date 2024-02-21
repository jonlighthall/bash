#!/bin/bash -u
#
# git/force_pull.sh - this script was developed to synchronize the local repository with the
# remote repository after a force push; hence the name. It assumes that---in the case of a force
# push---that the two repsoitories have common commit times, if not common hashes; this would be
# the case the history has been rewritten to update author names, for example. It is also useful
# for synchonizing diverged repsoitories without explicitly merging.
#
# METHOD -
#   STASH  save uncommited local changes
#   BRANCH copy local commits to temporary branch
#   RESET  reset local branch to common remote commit
#   PULL   fast-forward local branch to remote HEAD
#   REBASE rebase temporary branch
#   MERGE  fast-forward local branch to rebased temporary branch
#   PUSH   sync local changes with remote
#   STASH  restore uncommited changes
#   RESET  unstage uncommited changes
#
# USAGE - the remote name and branch can be optionally specified by the first and second
# arguments, respectively. The default remote branch is the current tracking branch.
#
# Apr 2023 JCL

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

# set debug level
declare -i DEBUG=0

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
	if [ -z "${save_traps+default}" ]; then
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
	# get Git version
	git --version | sed "s/^/${fTAB}/"
	git_ver=$(git --version | awk '{print $3}')
	git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
	git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
	git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')
else
	echo -e "${BAD}FAIL${NORMAL} Git not defined"
	if (return 0 2>/dev/null); then
		return 1
	else
		exit 1
	fi
fi

# list SSH status
host_OK=''
host_bad=''

# get number of remotes
cbar "${BOLD}parse remotes...${NORMAL}"
n_remotes=$(git remote | wc -l)
r_names=$(git remote)
if [ "${n_remotes}" -gt 1 ]; then
	echo "remotes found: ${n_remotes}"
else
	echo -n "remote: "
fi
declare -i i=0
for remote_name in ${r_names}; do
	if [ "${n_remotes}" -gt 1 ]; then
		((++i))
		echo -n "${TAB}${fTAB}$i) "
		TAB+=${fTAB:='   '}
	fi
	echo "$remote_name"
	remote_url=$(git remote get-url ${remote_name})
	echo "${TAB}${fTAB}  url: ${remote_url}"
	# parse protocol
	remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
	if [[ "${remote_pro}" == "git" ]]; then
		remote_pro="SSH"
		remote_host=$(echo ${remote_url} | sed 's/\(^[^:]*\):.*$/\1/')
	else
		remote_host=$(echo ${remote_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
		if [[ ! "${remote_pro}" == "http"* ]]; then
			remote_pro="local"
		fi							
	fi	
	echo "${TAB}${fTAB} host: $remote_host"
  	echo -e "${TAB}${fTAB}proto: ${remote_pro}"
	if [[ "${remote_pro}" == "SSH" ]]; then
		# default to checking host
		do_check=true
		decho "do_check = $do_check"

		# check remote host name against list of checked hosts
		if [ ! -z ${host_OK:+dummy} ]; then
			decho "checking $remote_host against list of checked hosts"
			for good_host in ${host_OK}; do
				if [[ $remote_host =~ $good_host ]]; then
					decho "$remote_host matches $good_host"
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

		# check connection before proceeding
		if [ ${do_check} = 'true' ]; then
			echo -n "${TAB}${fTAB}checking connection... "
			unset_traps
			ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 -T ${remote_host}
			RETVAL=$?
			set_traps
			if [[ $RETVAL == 0 ]]; then
				echo -e "${fTAB}${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
				# add to list
				if [ ! -z ${host_OK:+dummy} ]; then
					host_OK+=$'\n'
				fi
				host_OK+=${remote_host}
			else
				if [[ $RETVAL == 1 ]]; then
					echo -e "${fTAB}${yellow}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					if [[ $remote_host =~ "github.com" ]]; then
						decho "host is github"
						# Github will return 1 if everything is working
						# add to list
						if [ ! -z ${host_OK:+dummy} ]; then
							host_OK+=$'\n'
						fi
						host_OK+=${remote_host}
					else
						decho "host is not github"
						# add to list
						if [ ! -z ${host_bad:+dummy} ]; then
							host_bad+=$'\n'
						fi
						host_bad+=${remote_host}
					fi
				else
					echo -e "${fTAB}${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					# add to list
					if [ ! -z ${host_bad:+dummy} ]; then
						host_bad+=$'\n'
					fi
					host_bad+=${remote_host}
				fi
			fi
		fi
	fi
	if [ "${n_remotes}" -gt 1 ]; then
		TAB=${TAB%$fTAB}
	fi
done
unset remote_url
unset remote_pro
unset remote_host

# parse remote tracking branch and local branch
cbar "${BOLD}parse current settings...${NORMAL}"
remote_tracking_branch=$(git rev-parse --abbrev-ref @{upstream})
if [ -z ${remote_tracking_branch+default} ]; then
    echo "${TAB}no remote tracking branch set for current branch"
else
    echo -e "${TAB}remote tracking branch: ${blue}${remote_tracking_branch}${NORMAL}"
    upstream_repo=${remote_tracking_branch%%/*}
    echo "${TAB}${fTAB}remote name: ....... $upstream_repo"

	# parse branches
    upstream_refspec=${remote_tracking_branch#*/}
    echo "${TAB}${fTAB}remote refspec: .... $upstream_refspec"
fi
local_branch=$(git branch | grep \* | sed 's/^\* //')
echo -e "${TAB}${fTAB}local branch: ...... ${green}${local_branch}${NORMAL}"

# parse arguments
cbar "${BOLD}parse arguments...${NORMAL}"
if [ $# -ge 1 ]; then
	echo "${TAB}remote specified"
	unset remote_name
    pull_repo=$1
	echo -n "${TAB}${fTAB}remote name: ....... $pull_repo "	
	git remote | grep $pull_repo &>/dev/null
	RETVAL=$?
	if [[ $RETVAL == 0 ]]; then
		echo -e "${GOOD}OK${NORMAL}"
	else
		echo -e "${BAD}FAIL${NORMAL}"
		echo "$pull_repo not found"
		exit 1
	fi	
else
    echo "${TAB}no remote specified"
    echo "${TAB}${fTAB}using $upstream_repo"
	pull_repo=${upstream_repo}
fi
if [ $# -ge 2 ]; then
	echo "${TAB}reference specified"
	unset remote_branch
    pull_refspec=$2
    echo -n "${TAB}${fTAB}remote refspec: .... $pull_refspec "
	git branch -va | grep "$pull_repo/${pull_refspec}" &>/dev/null
	RETVAL=$?
	if [[ $RETVAL == 0 ]]; then
		echo -e "${GOOD}OK${NORMAL}"
	else
		echo -e "${BAD}FAIL${NORMAL}"
		echo "$pull_refspec not found"
		exit 1
	fi	
else
    echo "${TAB}no reference specified"
    echo "${TAB}${fTAB}using $upstream_refspec"
	pull_refspec=${upstream_refspec}
fi

if [ -z ${pull_repo} ] || [ -z ${pull_refspec} ]; then
    echo -e "${TAB}${BROKEN}ERROR: no remote tracking branch specified${NORMAL}"
    echo "${TAB} HELP: specify remote tracking branch with"
    echo "${TAB}       ${TAB}${BASH_SOURCE##*/} <repository> <refspec>"
    exit 1
fi

pull_branch=${pull_repo}/${pull_refspec}
echo -e "${TAB}pulling from: ......... ${blue}${pull_branch}${NORMAL}"

cbar "${BOLD}checking branches...${NORMAL}"
if [ ! -z ${remote_tracking_branch} ]; then
	echo -n "${TAB}remote tracking branches... "

	if [ "$pull_branch" == "$remote_tracking_branch" ]; then
		echo "match"
		echo "${TAB}${fTAB}${pull_branch}"
	else
		echo "do not match"
		echo "${TAB}${fTAB}${pull_branch}"
		echo "${TAB}${fTAB}${remote_tracking_branch}"
		echo "setting upstream remote tracking branch..."
		git branch -u ${pull_branch}

		echo -n "remotes... "
		if [ "$pull_repo" == "$upstream_repo" ]; then
			echo "match"
			echo "${TAB}${fTAB}${pull_repo}"
		else
			echo "do not match"
			echo "${TAB}${fTAB}${pull_repo}"
			echo "${TAB}${fTAB}${upstream_repo}"
		fi		
		echo -n "remote refspecs... "
		if [ "$pull_refspec" == "$upstream_refspec" ]; then
			echo "match"
			echo "${TAB}${fTAB}${pull_refspec}"
		else
			echo "do not match"
			echo "${TAB}${fTAB}${pull_refspec}"
			echo "${TAB}${fTAB}${upstream_refspec}"
		fi
	fi
fi

echo -n "local branch and remote branch name... "
if [ "$local_branch" == "$pull_refspec" ]; then
    echo "match"
	echo "${TAB}${fTAB}${local_branch}"
else
    echo "do not match"
	echo "${TAB}${fTAB}${local_branch}"
	echo "${TAB}${fTAB}${pull_refspec}"
fi

cbar "${BOLD}comparing local branch ${green}$local_branch${NORMAL} with remote branch ${blue}$pull_branch${NORMAL}"

# before starting, fetch remote
echo "${TAB}fetching ${pull_repo}..."
git fetch --verbose ${pull_repo} ${pull_refspec}

echo "comparing repositories based on commit hash..."
echo -n "${fTAB}leading remote commits: "
N_remote=$(git rev-list HEAD..${pull_branch} | wc -l)
echo "${N_remote}"

echo -n "${fTAB}trailing local commits: "
N_local=$(git rev-list ${pull_branch}..HEAD | wc -l)
echo "${N_local}"

if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    echo -e "${fTAB}${yellow}local '${local_branch}' and remote '${pull_branch}' have diverged${NORMAL}"
fi

if [ $N_local -eq 0 ] && [ $N_remote -eq 0 ]; then
    hash_local=$(git rev-parse HEAD)
    hash_remote=$(git rev-parse ${pull_branch})
else
    echo "comparing repositories based on commit time..."
    # determine latest common local commit, based on commit time
    iHEAD=${pull_branch}
    if [ ${N_remote} -gt 0 ]; then
        # print local and remote times
        echo "${fTAB} local time is $(git log ${local_branch} --format="%ad" -1)"
        echo "${fTAB}remote time is $(git log ${pull_branch} --format="%ad" -1)"

        # get local commit time
        T_local=$(git log ${local_branch} --format="%at" -1)

        echo -n "remote commits commited after local HEAD:"
        N_after=$(git rev-list ${pull_branch} --after=${T_local} | wc -l)
        if [ $N_after -eq 0 ]; then
            echo " none"
        else
            echo
            git rev-list ${pull_branch} --after=${T_local} | sed "s/^/${fTAB}/"
            echo -e "number of commits:\n${fTAB}${N_after}"

            echo "list of commits: "
            git --no-pager log ${pull_branch} --after=${T_local}

            echo -ne "start by checking commit:\n${fTAB}"
            git rev-list ${pull_branch} --after=${T_local} | tail -1

            iHEAD=$(git rev-list ${pull_branch} --after=${T_local} | tail -1)
            cbar "${BOLD}looping through remote commits...${NORMAL}"
        fi
    fi
    hash_local=''
fi
while [ -z ${hash_local} ]; do
    echo "${TAB}checking ${iHEAD}..."
    hash_remote=$(git rev-parse ${iHEAD})
    subj_remote=$(git log ${iHEAD} --format=%s -n 1)
    time_remote=$(git log ${iHEAD} --format=%at -n 1)
    TAB+=${fTAB:='   '}
    echo "${TAB}remote commit subject: $subj_remote"
    echo "${TAB}remote commit time: .. $time_remote or $(date -d @${time_remote} +"%a %b %-d %Y at %-l:%M %p %Z")"

    hash_local_s=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')
    hash_local=$(git log --format="%at %H " | grep "$time_remote" | awk '{print $2}')

    echo -n "${TAB}local subject and time hashes... "
    if [ "$hash_local" == "$hash_local_s" ]; then
        echo "match"
    else
        echo "do not match"
        echo "${TAB}subj = $hash_local_s"
        echo "${TAB}time = $hash_local"
    fi
    echo "${TAB}remote commit hash: ............. ${hash_remote}"
    echo -n "${TAB}corresponding local commit hash:  "
    if [ ! -z ${hash_local} ]; then
        TAB+=${fTAB:='   '}
        echo "$hash_local"
        # determine local commits not found on remote
        echo -n "${TAB}trailing local commits: "
        hash_start=$(git rev-list $hash_remote..HEAD | tail -n 1)
        if [ ! -z ${hash_start} ]; then
            echo
            git rev-list $hash_remote..HEAD | sed "s/^/${TAB}/"
            N_local=$(git rev-list $hash_remote..HEAD | wc -l)
            if [ $N_local -gt 1 ]; then
                echo -ne "${TAB}\E[3Dor ${hash_start}^.."
                hash_end=$(git rev-list $hash_remote..HEAD | head -n 1)
                echo ${hash_end}
            else
                hash_end=$hash_start
            fi
            echo -e "${TAB}${yellow}local branch is $N_local commits ahead of remote${NORMAL}"
        else
            echo -e "${green}none${NORMAL}"
            N_local=0
        fi
    else
        echo "not found"
    fi
    TAB=${TAB%$fTAB}
    iHEAD="${iHEAD}~"
done

# compare local commit to remote commit
echo -n "${TAB}corresponding remote commit: .... "
echo $hash_remote
TAB+=${fTAB:='   '}
echo -n "${TAB}local commit has... "
if [ "$hash_local" == "$hash_remote" ]; then
    echo "the same hash"
    echo -n "${TAB}merge base: ............. "
    git merge-base ${local_branch} ${pull_branch}
    hash_merge=$(git merge-base ${local_branch} ${pull_branch})
    echo -n "${TAB}local commit has... "
    if [ $hash_local == $hash_merge ]; then
        echo "the same hash"
    else
        echo "a different hash"
    fi
else
    echo "a different hash (diverged)"
    echo " local: $hash_local"
    echo "remote: $hash_remote"
    git log $hash_local -1
    git log $hash_remote -1
fi

# determine remote commits not found locally
echo -n "${TAB}leading remote commits: "
hash_start_remote=$(git rev-list $hash_local..${pull_branch} | tail -n 1)
if [ ! -z ${hash_start_remote} ]; then
    echo
    git rev-list $hash_local..${pull_branch} | sed "s/^/${TAB}/"
    N_remote=$(git rev-list $hash_local..${pull_branch} | wc -l)
    if [ $N_remote -gt 1 ]; then
        echo -ne "${TAB}\E[3Dor ${hash_start_remote}^.."
        hash_end_remote=$(git rev-list $hash_local..${pull_branch} | head -n 1)
        echo ${hash_end_remote}
    else
        hash_end_remote=$hash_start_remote
    fi
    echo -e "${TAB}${yellow}remote branch is $N_remote commits ahead of local${NORMAL}"
else
    echo -e "none"
    N_remote=0
fi
TAB=${TAB%$fTAB}
TAB=${TAB%$fTAB}

# stash local changes
cbar "${BOLD}stashing local changes...${NORMAL}"
if [ -z "$(git diff)" ]; then
    echo -e "${TAB}${fTAB}no differences to stash"
    b_stash=false
else
    echo "prepare to stash..."
    git reset HEAD
    git status
    echo "stashing..."
    if [ $git_ver_maj -lt 2 ]; then
        # old command
        git stash
    else
        # modern command
        git stash -u
    fi
    b_stash=true
fi

# copy leading commits to new branch
cbar "${BOLD}copying local commits to temporary branch...${NORMAL}"
echo "${TAB}before reset:"
git branch -v --color=always | sed '/^*/!d'
echo -e "${fTAB} local:  ${yellow}ahead $N_local${NORMAL}"
echo -e "${fTAB}remote: ${yellow}behind $N_remote${NORMAL}"

if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    branch_temp=${local_branch}.temp
    echo "generating temporary branch..."
    i=0
    set +e
    while [[ ! -z $(git branch -va | sed 's/^.\{2\}//;s/ .*$//' | grep ${branch_temp}) ]]; do
        echo "${TAB}${fTAB}${branch_temp} exists" 
        ((++i))
        branch_temp=${local_branch}.temp${i}
    done
    echo "${TAB}${fTAB}found unused branch name ${branch_temp}"
    if (! return 0 2>/dev/null); then
        echo "${TAB}${fTAB}resetting exit on error"
        set -eE
    fi
    git branch ${branch_temp}
else
    echo -e "${TAB}${fTAB}no local commits to copy"
fi

# initiate HEAD
if [ $N_remote -gt 0 ]; then
    cbar "${BOLD}reseting HEAD to match remote...${NORMAL}"
    if [ $N_local -eq 0 ]; then
        echo "${TAB}${fTAB}no need to reset"
    else
        echo "${TAB}resetting HEAD to $hash_remote..."
        git reset --hard $hash_remote | sed "s/^/${TAB}/"
		N_remote_old=$N_remote
		N_remote=$(git rev-list HEAD..${pull_branch} | wc -l)
		if [ $N_remote -ne $N_remote_old ]; then
			echo "${TAB}after reset:"
			git branch -v --color=always | sed '/^*/!d'
			echo -e "${fTAB}remote: ${yellow}behind $N_remote${NORMAL}"
		fi
    fi
fi

# pull remote commits
cbar "${BOLD}pulling remote changes...${NORMAL}"
if [ $N_remote -gt 0 ]; then
    echo -e "${TAB}${fTAB}${yellow}remote branch is $N_remote commits ahead of local${NORMAL}"
    git pull --ff-only
else
    echo -e "${TAB}${fTAB}no need to pull"
fi

# rebase and merge oustanding local commits
cbar "${BOLD}rebasing temporary branch...${NORMAL}"
if [ -z ${branch_temp+default} ]; then
	N_temp=0
else
	echo "${TAB}before rebase:"
	N_temp=$(git rev-list ${local_branch}..${branch_temp} | wc -l)
fi
if [ $N_temp -gt 0 ]; then
    echo -e "${TAB}${fTAB}${yellow}branch '${branch_temp}' is ${N_temp} commits ahead of '${local_branch}'${NORMAL}"

	# rebase
    git checkout ${branch_temp}
    git rebase ${local_branch}
	echo "${TAB}after rebase:"
	N_temp=$(git rev-list ${local_branch}..${branch_temp} | wc -l)
	echo -e "${TAB}${fTAB}${yellow}branch '${branch_temp}' is ${N_temp} commits ahead of '${local_branch}'${NORMAL}"
	
	# merge
	cbar "${BOLD}merging local changes...${NORMAL}"
    git checkout ${local_branch}
    git merge ${branch_temp}
    git branch -d ${branch_temp}
else
    echo -e "${TAB}${fTAB}no need to merge"
fi

# push local commits
cbar "${BOLD}pushing local changes...${NORMAL}"
N_local=$(git rev-list ${pull_branch}..HEAD | wc -l)
if [ $N_local -gt 0 ]; then
    echo -e "${TAB}${fTAB}${yellow}local branch is $N_local commits ahead of remote${NORMAL}"
    echo "${TAB}${fTAB}list of commits: "
    git --no-pager log ${pull_branch}..HEAD
    git push
else
    echo -e "${TAB}${fTAB}no need to push"
fi

# get back to where you were....
cbar "${BOLD}applying stash...${NORMAL}"
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo "there are $N_stash entries in stash"
    if $b_stash; then
        set +eE
        git stash pop
        echo "${TAB}${fTAB}resetting exit on error"
        set -eE
        echo -ne "stash made... "
        if [ -z "$(git diff)" ]; then
            echo "${green}no changes${NORMAL}"
        else
            echo -e "${yellow}changes!${NORMAL}"
            git reset HEAD
        fi
    else
        echo "${fTAB}...but none are from this operation"
    fi
else
    echo "${fTAB}no stash entries"
fi
echo "resetting upstream remote tracking branch..."
git branch -u "${remote_tracking_branch}"

cbar "${BOLD}you're done!${NORMAL}"

# add exit code for parent script
exit 0
