#!/bin/bash -u
# -----------------------------------------------------------------------------------------------
#
# git/force_pull.sh
#
# PURPOSE: This script was developed to synchronize the local repository with the remote
#   repository after a force push; hence the name. It assumes that---in the case of a force
#   push---that the two repsoitories have common commit times, if not common hashes; this would
#   be the case the history has been rewritten to update author names, for example. It is also
#   useful for synchonizing diverged repsoitories without explicitly merging.
#
# METHOD:
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
# USAGE: The remote name and branch can be optionally specified by the first and second
#   arguments, respectively. The default remote branch is the current tracking branch.
#
# Apr 2023 JCL
#
# -----------------------------------------------------------------------------------------------

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set debug level
declare -i DEBUG=0

# load formatting and functions
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
    set +e
else
    RUN_TYPE="executing"
    # exit on errors
    set -e
    set_traps
fi

print_source

# save and print starting directory
start_dir=$PWD
echo "starting directory = ${start_dir}"

# reset SSH status list
export host_bad=''
export host_OK=''

# load git utils
fgit="${src_dir_phys}/lib_git.sh"
if [ -e "$fgit" ]; then
    source "$fgit"
fi

# check remotes
cbar "${BOLD}check remotes...${RESET}"
check_remotes

# parse remote tracking branch and local branch
cbar "${BOLD}parse current settings...${RESET}"
# parse local
local_branch=$(git branch | grep \* | sed 's/^\* //')
# parse remote
echo -n "${TAB}checking remote tracking branch... "
# set shell options
if [[ "$-" == *e* ]]; then
    # exit on errors must be turned off; otherwise shell will exit no remote branch found
    old_opts=$(echo "$-")
    set +e
fi
unset_traps
git rev-parse --abbrev-ref @{upstream} &>/dev/null
RETVAL=$?
reset_shell ${old_opts-''}
if [[ $RETVAL -ne 0 ]]; then
    echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
    do_cmd git rev-parse --abbrev-ref @{upstream}
    set_traps
    echo "${TAB}no remote tracking branch set for current branch"
else
    set_traps
    remote_tracking_branch=$(git rev-parse --abbrev-ref @{upstream})
    upstream_repo=${remote_tracking_branch%%/*}
    # parse branches
    upstream_refspec=${remote_tracking_branch#*/}
    echo
    (
        echo -e "remote tracking branch+${BLUE}${remote_tracking_branch}${RESET}"
        echo "remote name+$upstream_repo"
        echo "remote refspec+$upstream_refspec"
        echo -e "local branch+${GREEN}${local_branch}${RESET}"
    ) | column -t -s+ -o ": " -R1 | sed "s/^//"
fi
dtab 

# parse arguments
cbar "${BOLD}parse arguments...${RESET}"
if [ $# -ge 1 ]; then
    echo "${TAB}remote specified"
    unset remote_name
    pull_repo=$1
    echo -n "${TAB}${fTAB}remote name: ....... $pull_repo "
    git remote | grep $pull_repo &>/dev/null
    RETVAL=$?
    if [[ $RETVAL == 0 ]]; then
        echo -e "${GOOD}OK${RESET}"
    else
        echo -e "${BAD}FAIL${RESET}"
        echo "$pull_repo not found"
        exit 1
    fi
else
    echo "${TAB}no remote specified"
    if [ -z ${upstream_repo+dummy} ]; then
        echo "${TAB}no remote tracking branch set for current branch"
        echo "${TAB}exiting..."
        exit
    else
        echo "${TAB}${fTAB}using $upstream_repo"
        pull_repo=${upstream_repo}
    fi
fi
if [ $# -ge 2 ]; then
    echo "${TAB}reference specified"
    unset remote_branch
    pull_refspec=$2
    echo -n "${TAB}${fTAB}remote refspec: .... $pull_refspec "
    git branch -va | grep "$pull_repo/${pull_refspec}" &>/dev/null
    RETVAL=$?
    if [[ $RETVAL == 0 ]]; then
        echo -e "${GOOD}OK${RESET}"
    else
        echo -e "${BAD}FAIL${RESET}"
        echo "$pull_refspec not found"
        exit 1
    fi
else
    echo "${TAB}no reference specified"
    echo "${TAB}${fTAB}using $upstream_refspec"
    pull_refspec=${upstream_refspec}
fi

if [ -z ${pull_repo} ] || [ -z ${pull_refspec} ]; then
    echo -e "${TAB}${BROKEN}ERROR: no remote tracking branch specified${RESET}"
    echo "${TAB} HELP: specify remote tracking branch with"
    echo "${TAB}       ${TAB}${BASH_SOURCE##*/} <repository> <refspec>"
    exit 1
fi

pull_branch=${pull_repo}/${pull_refspec}
echo -e "${TAB}pulling from: ......... ${BLUE}${pull_branch}${RESET}"

cbar "${BOLD}checking remote host...${RESET}"

# print remote parsing
pull_url=$(git remote get-url ${pull_repo})

# parse protocol
pull_pro=$(echo ${pull_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
if [[ "${pull_pro}" == "git" ]]; then
    pull_pro="SSH"
    pull_host=$(echo ${pull_url} | sed 's/\(^[^:]*\):.*$/\1/')
else
    pull_host=$(echo ${pull_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
    if [[ "${pull_pro}" == "http"* ]]; then
        echo "  repo: ${pull_repo}"
    else
        pull_pro="local"
    fi
fi
(
    echo "remote url+ ${pull_url}"
    echo "host+ $pull_host"
    echo -e "proto+ ${pull_pro}"
) | column -t -s+ -o ":" -R1 | sed "s/^/${TAB}/"

# check remote host name against list of checked hosts
if [ ! -z ${host_bad:+dummy} ]; then
    echo "checking $pull_host against list of checked hosts"
    # bad hosts
    echo -n "bad hosts: "
    if [ -z "$host_bad" ]; then
        echo "none"
    else
        host_bad=$(echo "${host_bad}" | sort -n)
        echo
        echo -e "${BAD}${host_bad}${RESET}" | sed "s/^/${fTAB}/"
    fi
    for bad_host in ${host_bad}; do
        if [[ "$pull_host" == "$bad_host" ]]; then
            echo "$pull_host matches $bad_host"
            echo "skipping fetch..."
            fetch_fail+="$repo ($pull_repo)"
            continue 2
        fi
    done
else
    decho "list of bad hosts empty"
fi

cbar "${BOLD}comparing branches...${RESET}"
if [ ! -z ${remote_tracking_branch} ]; then
    echo -n "${TAB}remote tracking branches... "

    if [ "$pull_branch" == "$remote_tracking_branch" ]; then
        echo "match"
        echo -e "${TAB}${fTAB}${BLUE}${pull_branch}${RESET}"
    else
        echo "do not match"
        echo "${TAB}${fTAB}${pull_branch}"
        echo "${TAB}${fTAB}${remote_tracking_branch}"
        echo "setting upstream remote tracking branch..."
        do_cmd git branch -u ${pull_branch}

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
    echo -e "${TAB}${fTAB}${GREEN}${local_branch}${RESET}"
else
    echo "do not match"
    echo "${TAB}${fTAB}${local_branch}"
    echo "${TAB}${fTAB}${pull_refspec}"
fi

cbar "${BOLD}comparing local branch ${GREEN}$local_branch${RESET} with remote branch ${BLUE}$pull_branch${RESET}"

# before starting, fetch remote
echo "${TAB}fetching ${pull_repo}..."
do_cmd git fetch --verbose ${pull_repo} ${pull_refspec}

echo "comparing repositories based on commit hash..."
echo -n "${fTAB}leading remote commits: "
N_remote=$(git rev-list HEAD..${pull_branch} | wc -l)
echo "${N_remote}"

echo -n "${fTAB}trailing local commits: "
N_local=$(git rev-list ${pull_branch}..HEAD | wc -l)
echo "${N_local}"

if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    echo -e "${fTAB}${YELLOW}local '${local_branch}' and remote '${pull_branch}' have diverged${RESET}"
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
            cbar "${BOLD}looping through remote commits...${RESET}"
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
        echo -e "${GOOD}match${RESET}"
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
            echo -e "${TAB}${YELLOW}local branch is $N_local commits ahead of remote${RESET}"
        else
            echo -e "${GREEN}none${RESET}"
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
    echo -e "${TAB}${YELLOW}remote branch is $N_remote commits ahead of local${RESET}"
else
    echo -e "none"
    N_remote=0
fi
TAB=${TAB%$fTAB}
TAB=${TAB%$fTAB}

# stash local changes
cbar "${BOLD}stashing local changes...${RESET}"
if [ -z "$(git diff)" ]; then
    echo -e "${TAB}${fTAB}no differences to stash"
    b_stash=false
else
    echo "resetting HEAD..."
    do_cmd git reset HEAD
    echo "status:"
    do_cmd git status
    echo "stashing..."
    if [ $git_ver_maj -lt 2 ]; then
        # old command
        do_cmd git stash
    else
        # modern command
        do_cmd git stash -u
    fi
    b_stash=true
fi

# copy leading commits to new branch
cbar "${BOLD}copying local commits to temporary branch...${RESET}"
echo "${TAB}before reset:"
git branch -v --color=always | sed '/^*/!d'
echo -e "${fTAB} local:  ${YELLOW}ahead $N_local${RESET}"
echo -e "${fTAB}remote: ${YELLOW}behind $N_remote${RESET}"

if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    branch_temp=${local_branch}.temp
    echo "generating temporary branch..."
    i=0
    # set shell options
    if [[ "$-" == *e* ]]; then
        # exit on errors must be turned off; otherwise shell will exit no remote branch found
        old_opts=$(echo "$-")
        set +e
    fi
    while [[ ! -z $(git branch -va | sed 's/^.\{2\}//;s/ .*$//' | grep ${branch_temp}) ]]; do
        echo "${TAB}${fTAB}${branch_temp} exists"
        ((++i))
        branch_temp=${local_branch}.temp${i}
    done
    echo "${TAB}${fTAB}found unused branch name ${branch_temp}"
    if (! return 0 2>/dev/null); then
        reset_shell ${old_opts-''}
    fi
    do_cmd git branch ${branch_temp}
else
    echo -e "${TAB}${fTAB}no local commits to copy"
fi

# initiate HEAD
if [ $N_remote -gt 0 ]; then
    cbar "${BOLD}reseting HEAD to match remote...${RESET}"
    if [ $N_local -eq 0 ]; then
        echo "${TAB}${fTAB}no need to reset"
    else
        echo "${TAB}resetting HEAD to $hash_remote..."
        do_cmd git reset --hard $hash_remote
        N_remote_old=$N_remote
        N_remote=$(git rev-list HEAD..${pull_branch} | wc -l)
        if [ $N_remote -ne $N_remote_old ]; then
            echo "${TAB}after reset:"
            git branch -v --color=always | sed '/^*/!d'
            echo -e "${fTAB}remote: ${YELLOW}behind $N_remote${RESET}"
        fi
    fi
fi

# pull remote commits
cbar "${BOLD}pulling remote changes...${RESET}"
if [ $N_remote -gt 0 ]; then
    echo -e "${TAB}${fTAB}${YELLOW}remote branch is $N_remote commits ahead of local${RESET}"
    do_cmd git pull --ff-only ${pull_repo} ${pull_refspec}
else
    echo -e "${TAB}${fTAB}no need to pull"
fi

# rebase and merge oustanding local commits
cbar "${BOLD}rebasing temporary branch...${RESET}"

if [ -z ${branch_temp+default} ]; then
    N_temp=0
else
    echo "${TAB}before rebase:"
    N_temp=$(git rev-list ${local_branch}..${branch_temp} | wc -l)
fi
if [ $N_temp -gt 0 ]; then
    echo -e "${TAB}${fTAB}${YELLOW}branch '${branch_temp}' is ${N_temp} commits ahead of '${local_branch}'${RESET}"

    # rebase
    trap 'set_color
echo "${bin_name} TODO: git checkout ${branch_temp}"
echo "${bin_name} TODO: git rebase ${local_branch}"
echo "${bin_name} TODO: git checkout ${local_branch}"
echo "${bin_name} TODO: git merge ${branch_temp}"
echo "${bin_name} TODO: git branch -d ${branch_temp}"
echo "${bin_name} TODO: git push --set-upstream ${pull_repo} ${pull_refspec}"
echo "${bin_name} TODO: git stash pop"
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT

    do_cmd git checkout ${branch_temp}
    trap 'set_color
echo "${bin_name} TODO: git rebase ${local_branch}"
echo "${bin_name} TODO: git checkout ${local_branch}"
echo "${bin_name} TODO: git merge ${branch_temp}"
echo "${bin_name} TODO: git branch -d ${branch_temp}"
echo "${bin_name} TODO: git push --set-upstream ${pull_repo} ${pull_refspec}"
echo "${bin_name} TODO: git stash pop"
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT

    do_cmd git rebase ${local_branch}
    echo "${TAB}after rebase:"
    N_temp=$(git rev-list ${local_branch}..${branch_temp} | wc -l)
    echo -e "${TAB}${fTAB}${YELLOW}branch '${branch_temp}' is ${N_temp} commits ahead of '${local_branch}'${RESET}"

    # merge
    cbar "${BOLD}merging local changes...${RESET}"
    trap 'set_color
echo "${bin_name} TODO: git checkout ${local_branch}"
echo "${bin_name} TODO: git merge ${branch_temp}"
echo "${bin_name} TODO: git branch -d ${branch_temp}"
echo "${bin_name} TODO: git push --set-upstream ${pull_repo} ${pull_refspec}"
echo "${bin_name} TODO: git stash pop"
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    do_cmd git checkout ${local_branch}
    trap 'set_color
echo "${bin_name} TODO: git merge ${branch_temp}"
echo "${bin_name} TODO: git branch -d ${branch_temp}"
echo "${bin_name} TODO: git push --set-upstream ${pull_repo} ${pull_refspec}"
echo "${bin_name} TODO: git stash pop"
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT    
    do_cmd git merge ${branch_temp}
    trap 'set_color
echo "${bin_name} TODO: git branch -d ${branch_temp}"
echo "${bin_name} TODO: git push --set-upstream ${pull_repo} ${pull_refspec}"
echo "${bin_name} TODO: git stash pop"
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    do_cmd git branch -d ${branch_temp}
else
    echo -e "${TAB}${fTAB}no need to merge"
fi

# push local commits
cbar "${BOLD}pushing local changes...${RESET}"
N_local=$(git rev-list ${pull_branch}..HEAD | wc -l)
if [ $N_local -gt 0 ]; then
    echo -e "${TAB}${YELLOW}local branch is $N_local commits ahead of remote${RESET}"
    echo "${TAB}${fTAB}list of commits: "
    itab
    git --no-pager log ${pull_branch}..HEAD | sed "s/^/${TAB}/"
    dtab
    trap 'set_color
echo "${bin_name} TODO: git push --set-upstream ${pull_repo} ${pull_refspec}"
echo "${bin_name} TODO: git stash pop"
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    echo "pushing..."
    do_cmd git push --set-upstream ${pull_repo} ${pull_refspec}
else
    echo -e "${TAB}${fTAB}no need to push"
fi

# get back to where you were....
cbar "${BOLD}applying stash...${RESET}"
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo "there are $N_stash entries in stash"
    if $b_stash; then
        trap 'set_color
echo "${bin_name} TODO: git stash pop"
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
        if [[ "$-" == *e* ]]; then
            # exit on errors must be turned off; otherwise shell will exit no remote branch found
            old_opts=$(echo "$-")
            set +e
        fi
        unset_traps
        do_cmd git stash pop
        set_traps
        reset_shell ${old_opts-''}
        echo -ne "stash made... "
        if [ -z "$(git diff)" ]; then
            echo -e "${GREEN}no changes${RESET}"
        else
            echo -e "${YELLOW}changes!${RESET}"
            dtab
            trap 'set_color
echo "${bin_name} TODO: git reset HEAD"
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
            do_cmd git reset HEAD
        fi
    else
        echo "${fTAB}...but none are from this operation"
    fi
else
    echo "${fTAB}no stash entries"
fi
if [ ! -z ${remote_tracking_branch} ]; then
    echo "resetting upstream remote tracking branch..."
    trap 'set_color
echo "${bin_name} TODO: git branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    if [ $git_ver_maj -lt 2 ]; then
        # old command       
        git branch --set-upstream "${remote_tracking_branch}"
    else
        # modern command
        do_cmd git branch -u ${remote_tracking_branch}
    fi
fi
cbar "${BOLD}you're done!${RESET}"
clear_traps
set_traps
# add exit code for parent script
exit 0
