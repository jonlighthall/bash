#!/bin/bash -eu
# ------------------------------------------------------------------------------
#
# git/force_pull.sh
#
# PURPOSE: This script was developed to synchronize the local repository with
#   the remote repository after a force push; hence the name. It assumes
#   that---in the case of a force push---that the two repsoitories have common
#   commit times, if not common hashes; this would be the case the history has
#   been rewritten to update author names, for example. It is also useful for
#   synchonizing diverged repsoitories without explicitly merging.
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
# USAGE: The remote name and branch can be optionally specified by the first and
#   second arguments, respectively. The default remote branch is the current
#   tracking branch.
#
# Apr 2023 JCL
#
# -----------------------------------------------------------------------------

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set debug level
# substitue default value if DEBUG is unset or null
declare -i DEBUG=${DEBUG:-0}

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "${fpretty}" ]; then
    source "${fpretty}"
    print_debug
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    set +e
else
    # exit on errors
    set -e
    set_traps
fi
print_source

# save and print starting directory
start_dir=$PWD
echo "${TAB}starting directory = ${start_dir}"

# load git utils
for library in git; do
    # use the canonical (physical) source directory for reference; this is important if sourcing
    # this file directly from shell
    fname="${src_dir_phys}/lib_${library}.sh"
    if [ -e "${fname}" ]; then
        if [[ "$-" == *i* ]] && [ ${DEBUG:-0} -gt 0 ]; then
            echo "${TAB}loading $(basename "${fname}")"
        fi
        source "${fname}"
    else
        echo "${fname} not found"
    fi
done

# reset SSH status list
export host_bad=''
export host_OK=''

# check remotes
cbar "${BOLD}check remotes...${RESET}"
check_remotes

parse_remote_tracking_branch

# parse arguments
cbar "${BOLD}parse arguments...${RESET}"
if [ $# -ge 1 ]; then
    echo "${TAB}remote specified"
    unset remote_name
    pull_repo=$1
    echo -n "${TAB}${fTAB}remote name: ....... $pull_repo "
    git remote | grep "$pull_repo" &>/dev/null
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
        pull_repo="${upstream_repo}"
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
    pull_refspec="${upstream_refspec}"
fi

if [ -z "${pull_repo}" ] || [ -z "${pull_refspec}" ]; then
    echo -e "${TAB}${BAD}FAIL: no remote tracking branch specified${RESET}"
    echo "${TAB} HELP: specify remote tracking branch with"
    echo "${TAB}       ${TAB}${BASH_SOURCE##*/} <repository> <refspec>"
    exit 1
fi

pull_branch="${pull_repo}/${pull_refspec}"
echo -e "${TAB}pulling from: ......... ${BLUE}${pull_branch}${RESET}"

cbar "${BOLD}checking remote host...${RESET}"

# print remote parsing
pull_url=$(git remote get-url "${pull_repo}")

# parse protocol
pull_pro=$(echo "${pull_url}" | sed 's/\(^[^:@]*\)[:@].*$/\1/')
if [[ "${pull_pro}" == "git" ]]; then
    pull_pro="SSH"
    pull_host=$(echo "${pull_url}" | sed 's/\(^[^:]*\):.*$/\1/')
else
    pull_host=$(echo "${pull_url}" | sed 's,^[a-z]*://\([^/]*\).*,\1,')
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
if [ -n "${host_bad:+dummy}" ]; then
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
if [ -n "${remote_tracking_branch:+dummy}" ]; then
    echo -n "${TAB}remote tracking branches... "

    if [ "$pull_branch" == "$remote_tracking_branch" ]; then
        echo "match"
        echo -e "${TAB}${fTAB}${BLUE}${pull_branch}${RESET}"
    else
        echo "do not match"
        echo "${TAB}${fTAB}${pull_branch}"
        echo "${TAB}${fTAB}${remote_tracking_branch}"
        echo "setting upstream remote tracking branch..."
        do_cmd git branch -u "${pull_branch}"

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

echo -n "local branch and remote branch names... "
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
echo -n "${TAB}fetching ${pull_repo}..."
do_cmd_stdbuf git fetch --verbose "${pull_repo}" "${pull_refspec}"

echo "comparing repositories based on commit hash..."
N_local=$(git rev-list "${pull_branch}..HEAD" | wc -l)
echo -e "${fTAB} local:  ${YELLOW}ahead $N_local${RESET}"
N_remote=$(git rev-list "HEAD..${pull_branch}" | wc -l)
echo -e "${fTAB}remote: ${YELLOW}behind $N_remote${RESET}"

if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    echo -e "${fTAB}${YELLOW}local branch '${local_branch}' and remote branch '${pull_branch}' have diverged${RESET}"
    git update-ref -m "${BASH_SOURCE##*/} (start):" HEAD HEAD
fi

# -----------------
# set display limit
hash_limit=5
# -----------------

if [ $N_local -eq 0 ] && [ $N_remote -eq 0 ]; then
    hash_local=$(git rev-parse HEAD)
    hash_remote=$(git rev-parse "${pull_branch}")
else
    iHEAD="${pull_branch}"
    if [ ${N_remote} -gt 0 ]; then
        # determine latest common local commit, based on commit time
        echo "${TAB}comparing repositories based on commit time..."

        # get local commit time
        T_local=$(git log "${local_branch}" --format="%at" -1)

        # print local and remote times
        itab
        (
            echo "local timestamp+ ${T_local}"
            echo "local time+ $(git log "${local_branch}" --format="%ad" -1)"
            echo "remote time+ $(git log "${pull_branch}" --format="%ad" -1)"
        ) | column -t -s+ -o ":" -R1 | sed "s/^/${TAB}/"

        echo -n "${TAB}remote commits commited after local HEAD:"
        dtab
        cond_after="${pull_branch} --after=${T_local}"
        N_after=$(git rev-list ${cond_after} | wc -l)
        if [ $N_after -eq 0 ]; then
            echo " none"
        else
            echo
            itab
            git rev-list ${cond_after} -n $hash_limit  | sed "s/^/${TAB}/"

            if [ $N_after -gt $hash_limit ]; then
                N_skip=$(( $N_after - $hash_limit))
                N_tail=$(($hash_limit/2))
                if [ $N_skip -lt $N_tail ]; then
                    N_tail=$N_skip
                else
                    echo "${TAB}..."
                fi
                git rev-list ${cond_after} | tail -${N_tail} | sed "s/^/${TAB}/"
                echo -e "${TAB}${YELLOW}$(($N_skip-$N_tail)) commits not displayed${RESET}"
            fi
            dtab
            echo -e "${TAB}number of commits:\n${TAB}${fTAB}${N_after}"

            echo "${TAB}list of commits: "
            itab
            git --no-pager log ${cond_after} -n $hash_limit --color=always | sed "s/^/${TAB}/"
            echo
            if [ $N_after -gt $hash_limit ]; then
                echo -e "${TAB}${YELLOW}$N_skip commits not displayed${RESET}"
            fi
            dtab

            echo -e "${TAB}start by checking commit:"
            itab
            git --no-pager log ${cond_after} -n 1 --color=always | sed "s/^/${TAB}/"
            dtab

            # define initial HEAD location
            iHEAD=$(git rev-list ${cond_after} | tail -1)
        fi
    fi
    hash_local=''
fi

if [ -z "${hash_local}" ]; then
    cbar "${BOLD}looping through remote commits...${RESET}"
fi

declare -i head_count
head_count=0
HEAD0="${iHEAD}"

while [ -z "${hash_local}" ]; do
    echo -e "${TAB}checking ${YELLOW}${iHEAD} (${HEAD0}~${head_count})${RESET}..."
    hash_remote=$(git rev-parse "${iHEAD}")
    subj_remote=$(git log "${iHEAD}" --format=%s -n 1)
    time_remote=$(git log "${iHEAD}" --format=%at -n 1)
    TAB+=${fTAB:='   '}
    echo "${TAB}remote commit subject: $subj_remote"
    echo "${TAB}remote commit time: .. $time_remote or $(date -d @${time_remote} +"%a %b %-d %Y at %-l:%M %p %Z")"

    # find corresponding local commit based on the remote commit subject
    echo "${TAB}finding corresponding local commit based on the remote commit subject..."
    # display the corresponding commits
    itab
    if false; then
        git log --color=always | grep -B4 "$subj_remote" | sed "s/^/${TAB}/"
        echo
    fi
    subj_pat=" ${subj_remote}$"
    git log --format="%C(auto)%h%d %at %ai %s" --color=always | grep --color=always "${subj_pat}" | sed "s/^/${TAB}/"

    # get the has of the corresponding commit
    hash_local_s=$(git log --format="%H %s" | grep "${subj_pat}" | awk '{print $1}')
    # check the number of corresponding commits
    N_hash_local_s=$(git log --format="%h %s" | grep "${subj_pat}" | awk '{print $1}' | wc -l)
    if [ $N_hash_local_s -gt 1 ]; then
        echo -e "${TAB}${YELLOW}multiple matching entries found!${RESET}"
    else
        echo -n "${TAB}local subject hash: ......... "
        if [ -z "$hash_local_s" ]; then
            echo "none"
        else
            echo "$hash_local_s"
        fi
    fi
    dtab

    # find corresponding local commit based on the remote commit time
    echo "${TAB}finding corresponding local commit based on the remote commit time..."

    # get the has of the corresponding commit
    hash_local=$(git log --format="%H %at" | grep "$time_remote" | awk '{print $1}')
    N_hash_local=$(git log --format="%H %at" | grep "$time_remote" | awk '{print $1}' | wc -l)

    itab
    # display the corresponding commits
    git log --format="%C(auto)%h %d %at %ai %<|(-1,trunc)%s" --color=always | grep "${time_remote}" --color=always | sed "s/^/${TAB}/"

    if [ $N_hash_local -gt 1 ]; then
        echo -e "${TAB}${YELLOW}multiple matching entries found!${RESET}"
    else
        echo -n "${TAB}local time hash: ............ "
        if [ -z "$hash_local" ]; then
            echo "none"
        else
            echo "$hash_local"
        fi

    fi
    dtab

    echo -n "${TAB}local subject and time hashes... "
    if [ "$hash_local" == "$hash_local_s" ]; then
        echo -e "${GOOD}match${RESET}"

        if [ $N_hash_local -gt 1 ]; then
            itab
            echo -e "${TAB}${YELLOW}multiple matching entries found:${RESET}"
            echo "${TAB}subject"
            echo "$hash_local_s" | sed "s/^/${TAB}${fTAB}/"
            echo "${TAB}time"
            echo "$hash_local" | sed "s/^/${TAB}${fTAB}/"
            # select a function to choose the hash: head or tail
            # tail will select an older head and lead to a greater difference
            # head will select the newer hash and lead to a smaller difference
            func=head
            echo -e "${TAB}selecting with ${ARG}$func${RESET}"
            hash_local=$(echo "$hash_local" | ${func} -n 1)
            echo "$hash_local" | sed "s/^/${TAB}${fTAB}/"
            dtab
        fi
    else
        echo "do not match"
        itab
        echo "${TAB}subj = $hash_local_s" | sed "1! s/^/${TAB}       /"
        echo -n "${TAB}time = "
        if [ ! -z "${hash_local}" ]; then
            echo "$hash_local"
            decho "${TAB} the time-based commited is selected by default" # is there a reason for this?
            echo "${TAB} using $hash_local"
        else
            echo -e "${YELLOW}not found${RESET}"
        fi
        dtab
    fi

    echo "${TAB}remote commit hash: ............ ${hash_remote}"
    echo -n "${TAB}corresponding local commit hash: "
    if [ ! -z "${hash_local}" ]; then
        echo "$hash_local"
        # determine local commits not found on remote
        echo -en "${TAB}${YELLOW}local branch is "
        cond_local="$hash_remote..HEAD"
        hash_start=$(git rev-list "$cond_local" | tail -n 1)
        if [ ! -z "${hash_start}" ]; then
            N_local=$(git rev-list "$cond_local" | wc -l)
            echo -en "${N_local} commit"
            if [ $N_local -ne 1 ]; then
                echo -en "s"
            fi
            echo -e " ahead of remote${RESET}"
            itab
            echo "${TAB}leading local commits: "
            itab
            git rev-list "$cond_local" -n $hash_limit | sed "s/^/${TAB}/"
            if [ $N_local -gt $hash_limit ]; then
                N_skip=$(( $N_local - $hash_limit))
                N_tail=$(($hash_limit/2))
                if [ $N_skip -lt $N_tail ]; then
                    N_tail=$N_skip
                else
                    if [ $N_skip -gt 0 ]; then
                        echo "${TAB}..."
                    fi
                fi
                git rev-list "${cond_local}" | tail -${N_tail} | sed "s/^/${TAB}/"
                if [ $N_skip -gt 0 ]; then
                    echo -e "${TAB}${YELLOW}$(($N_skip-$N_tail)) commits not displayed${RESET}"
                fi
            fi

            if [ $N_local -gt 1 ]; then
                echo -ne "${TAB}\E[3Dor ${hash_start}^.."
                hash_end=$(git rev-list "$cond_local" | head -n 1)
                echo "${hash_end}"
            else
                hash_end="$hash_start"
            fi
            dtab 2
        else
            N_local=0
            echo -e "${N_remote} commits behind local branch${RESET}"
            dtab
        fi
    else
        echo -e "${YELLOW}not found${RESET}"
        dtab 2
    fi

    # check if next revision exists
    HEAD_next="${iHEAD}~"

    git rev-parse "${HEAD_next}"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        iHEAD="${HEAD_next}"
        ((++head_count))
    else
        hash_local="${iHEAD}"
    fi
done

dtab
echo -e "${TAB}${GOOD}remote commit found${RESET}"
# compare local commit to remote commit
itab
echo -n "${TAB}corresponding remote commit: ... "
echo "$hash_remote"
itab
echo -n "${TAB}local commit has... "
if [ "$hash_local" == "$hash_remote" ]; then
    echo "the same hash"
    dtab
    echo -n "${TAB}merge base: .................... "
    git merge-base "${local_branch}" "${pull_branch}"
    hash_merge=$(git merge-base "${local_branch}" "${pull_branch}")
    itab
    echo -n "${TAB}local commit has... "
    if [ "$hash_local" == "$hash_merge" ]; then
        echo "the same hash"
    else
        echo "a different hash"
    fi
else
    echo "a different hash (diverged)"
    echo "${TAB} local: $hash_local"
    echo "${TAB}remote: $hash_remote"
    git log "$hash_local" -1 --color=always | sed "s/^/${TAB}/"
    git log "$hash_remote" -1 --color=always | sed "s/^/${TAB}/"
    echo
fi

# determine remote commits not found locally
dtab
echo -en "${TAB}${YELLOW}remote branch is "
cond_remote="$hash_local..${pull_branch}"
hash_start_remote=$(git rev-list "$cond_remote" | tail -n 1)
if [ -n "${hash_start_remote}" ]; then
    N_remote=$(git rev-list "$cond_remote" | wc -l)
    echo -en "${N_remote} commit"
    if [ $N_remote -ne 1 ]; then
        echo -en "s"
    fi
    echo -e " behind local branch${RESET}"
    itab
    echo -e "${TAB}trailing remote commits:"
    itab
    git rev-list "$cond_remote" -n $hash_limit | sed "s/^/${TAB}/"

    if [ $N_remote -gt $hash_limit ]; then
        N_skip=$(( $N_remote - $hash_limit))
        N_tail=$(($hash_limit/2))
        if [ $N_skip -lt $N_tail ]; then
            N_tail=$N_skip
        else
            echo "${TAB}..."
        fi
        git rev-list "${cond_remote}" | tail -${N_tail} | sed "s/^/${TAB}/"
        echo -e "${TAB}${YELLOW}$(($N_skip-$N_tail)) commits not displayed${RESET}"
    fi

    if [ $N_remote -gt 1 ]; then
        echo -ne "${TAB}\E[3Dor ${hash_start_remote}^.."
        hash_end_remote=$(git rev-list "$cond_remote" | head -n 1)
        echo "${hash_end_remote}"
    else
        hash_end_remote="$hash_start_remote"
    fi
    dtab 2
else
    dtab
    N_remote=0
    echo -e "${N_remote} commits behind local branch${RESET}"
fi
dtab 2

# stash local changes
cbar "${BOLD}stashing local changes...${RESET}"
if [ -z "$(git diff)" ] && [ -z "$(git ls-files -o)" ]; then
    echo -e "${TAB}${fTAB}no differences to stash"
    b_stash=false
else
    echo "resetting HEAD..."
    do_cmd git reset HEAD
    echo "status:"
    do_cmd git status
    echo "stashing..."
    if [ $git_ver_maj -lt 2 ]; then
        if [ -z "$(git ls-files -o)" ]; then
            # old command
            do_cmd git stash
        else
            echo -e "${TAB}${BAD}FAIL: cannot stash untracked files! Update Git or update ${BASH_SOURCE##*/}\!${RESET}"
            exit 1
        fi
    else
        # modern command
        do_cmd git stash -u
    fi
    b_stash=true
fi

# copy trailing commits to new branch
cbar "${BOLD}copying local commits to temporary branch...${RESET}"

if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    branch_temp="${local_branch}.temp"
    echo "generating temporary branch..."
    i=0
    # set shell options
    if [[ "$-" == *e* ]]; then
        # exit on errors must be turned off; otherwise shell will exit no remote branch found
        old_opts=$(echo "$-")
        set +e
    fi
    unset_traps
    while git branch -va | sed 's/^.\{2\}//;s/ .*$//' | grep -q "${branch_temp}"; do
        echo "${TAB}${fTAB}${branch_temp} exists"
        ((++i))
        branch_temp="${local_branch}.temp${i}"
    done
    echo "${TAB}${fTAB}found unused branch name ${branch_temp}"
    if (! return 0 2>/dev/null); then
        reset_shell "${old_opts-''}"
    fi
    reset_traps
    do_cmd git branch "${branch_temp}"
else
    echo -e "${TAB}${fTAB}no need for temporary branch"
fi

# initiate HEAD
if [ $N_remote -gt 0 ]; then
    cbar "${BOLD}resetting HEAD to match remote...${RESET}"
    if [ $N_local -eq 0 ]; then
        echo "${TAB}${fTAB}no need to reset"
    else
        echo "${TAB}before reset:"
        git branch -v --color=always | sed '/^*/!d'
        echo -e "${fTAB} local:  ${YELLOW}ahead $N_local${RESET}"
        echo -e "${fTAB}remote: ${YELLOW}behind $N_remote${RESET}"

        echo "${TAB}resetting HEAD to $hash_remote..."
        do_cmd git reset --hard "$hash_remote"
        RETVAL=$?
        if [[ $RETVAL -ne 0 ]]; then
            echo -e "${TAB}${BAD}FAIL: git reset --hard failed with code $RETVAL${RESET}"
            exit $RETVAL
        fi
        N_remote_old=$N_remote
        N_remote=$(git rev-list "HEAD..${pull_branch}" | wc -l)
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
    echo -en "${TAB}${fTAB}${YELLOW}remote branch is $N_remote commit"
    if [ $N_remote -ne 1 ]; then
        echo -en "s"
    fi
    echo -e " behind local branch${RESET}"
    do_cmd git pull --ff-only "${pull_repo}" "${pull_refspec}"
    RETVAL=$?
    if [[ $RETVAL -ne 0 ]]; then
        echo -e "${TAB}pull ${BAD}FAIL${RESET}"
        exit 1
    fi
else
    echo -e "${TAB}${fTAB}no need to pull"
fi

# rebase and merge oustanding local commits
cbar "${BOLD}rebasing temporary branch...${RESET}"

if [ -z "${branch_temp+default}" ]; then
    N_temp=0
else
    echo "${TAB}before rebase:"
    N_temp=$(git rev-list "${local_branch}..${branch_temp}" | wc -l)
    git config advice.skippedCherryPicks false
fi

# define name for traps
bin_name=${BASH_SOURCE##*/}
itab
trap_head="${TAB}${DIM}${bin_name}${NORMAL} TODO: git "
dtab

# exit on errors to trigger exit traps
set -e

# check if the temporary branch is ahead of the local branch
if [ $N_temp -gt 0 ]; then
    echo -en "${TAB}${fTAB}${YELLOW}branch '${branch_temp:-<temp>}' is ${N_temp} commit"
    if [ $N_local -ne 1 ]; then
        echo -en "s"
    fi
    echo -e " ahead of '${local_branch}'${RESET}"
    # rebase
    trap 'set_color;
echo -e "${trap_head}checkout ${branch_temp:-<temp>}"
echo -e "${trap_head}rebase ${local_branch}"
echo -e "${trap_head}checkout ${local_branch}"
echo -e "${trap_head}merge ${branch_temp:-<temp>}"
echo -e "${trap_head}branch -d ${branch_temp-<temp>}"
echo -e "${trap_head}push --set-upstream ${pull_repo} ${pull_refspec}"
echo -e "${trap_head}stash pop"
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT

    do_cmd git checkout "${branch_temp}"
    trap 'set_color;
echo -e "${trap_head}rebase ${local_branch}"
echo -e "${trap_head}checkout ${local_branch}"
echo -e "${trap_head}merge ${branch_temp}"
echo -e "${trap_head}branch -d ${branch_temp}"
echo -e "${trap_head}push --set-upstream ${pull_repo} ${pull_refspec}"
echo -e "${trap_head}stash pop"
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    do_cmd git rebase --empty=drop --no-keep-empty "${local_branch}" -X ours
    echo -e "${TAB}after rebase:"
    N_temp=$(git rev-list "${local_branch}..${branch_temp}" | wc -l)
    echo -en "${TAB}${fTAB}${YELLOW}branch '${branch_temp}' is ${N_temp} commit"
    if [ $N_local -ne 1 ]; then
        echo -en "s"
    fi
    echo -e " ahead of '${local_branch}'${RESET}"

    # merge
    cbar "${BOLD}merging local changes...${RESET}"
    trap 'set_color;
echo -e "${trap_head}checkout ${local_branch}"
echo -e "${trap_head}merge ${branch_temp}"
echo -e "${trap_head}branch -d ${branch_temp}"
echo -e "${trap_head}push --set-upstream ${pull_repo} ${pull_refspec}"
echo -e "${trap_head}stash pop"
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    do_cmd git checkout "${local_branch}"
    trap 'set_color;
echo -e "${trap_head}merge ${branch_temp}"
echo -e "${trap_head}branch -d ${branch_temp}"
echo -e "${trap_head}push --set-upstream ${pull_repo} ${pull_refspec}"
echo -e "${trap_head}stash pop"
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    do_cmd git merge --ff-only "${branch_temp}"
    trap 'set_color;
echo -e "${trap_head}branch -d ${branch_temp}"
echo -e "${trap_head}push --set-upstream ${pull_repo} ${pull_refspec}"
echo -e "${trap_head}stash pop"
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    do_cmd git branch -d "${branch_temp}"
else
    echo -e "${TAB}${fTAB}no need to merge"
fi

# push local commits
cbar "${BOLD}pushing local changes...${RESET}"
N_local=$(git rev-list "${pull_branch}..HEAD" | wc -l)
if [ $N_local -gt 0 ]; then
    echo -en "${TAB}${YELLOW}local branch is $N_local commit"
    if [ $N_local -ne 1 ]; then
        echo -en "s"
    fi
    echo -e " ahead of remote${RESET}"
    echo -e "${TAB}list of commits: "
    itab
    git --no-pager log --stat "${pull_branch}..HEAD" -n ${hash_limit} --color=always | sed "s/^/${TAB}/"
    echo
    if [ $N_local -gt $hash_limit ]; then
        N_skip=$(( $N_local - $hash_limit))
        echo -e "${TAB}${YELLOW}$N_skip commits not displayed${RESET}"
    fi

    dtab
    trap 'set_color
echo -e "${trap_head}push --set-upstream ${pull_repo} ${pull_refspec}"
echo -e "${trap_head}stash pop"
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    echo -en "Ready to push ${YELLOW}$N_local local commit"
    if [ $N_local -ne 1 ]; then
        echo -en "s"
    fi
    echo -e "${RESET} to remote ${PSBR}${pull_url}${RESET}"
    itab
    unset_traps
    read -p ${TAB}$'\E[32m>\E[0m Proceed with push? (y/n) ' -n 1 -r
    reset_traps
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo -e "${TAB}pushing ${GREEN}$local_branch${RESET} to ${BLUE}$pull_branch${RESET}... "
        if [ "${local_branch}" == "${pull_refspec}" ]; then
            do_cmd_stdbuf git push --verbose --set-upstream "${pull_repo}" "${pull_refspec}"
        else
            do_cmd_stdbuf git push --verbose "$pull_repo" "HEAD:$pull_refspec"
        fi
        RETVAL=$?
        echo -ne "${TAB}${INVERT} push ${RESET} "
        if [[ $RETVAL == 0 ]]; then
            echo -e "${GOOD}OK${RESET}"
        else
            echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
            exit
        fi
    else
        echo
        echo "${TAB}skipping push"
        echo -e "${TAB}${YELLOW}$N_local commits not pushed${RESET}"
    fi
    dtab
else
    echo -e "${TAB}${fTAB}no need to push"
fi

# get back to where you were....
cbar "${BOLD}applying stash...${RESET}"
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo -e "${TAB}there are $N_stash entries in stash"
    if $b_stash; then
        trap 'set_color;
echo -e "${trap_head}stash pop"
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
        if [[ "$-" == *e* ]]; then
            # exit on errors must be turned off; otherwise shell will exit no remote branch found
            old_opts=$(echo "$-")
            set +e
        fi
        unset_traps
        do_cmd git stash pop
        reset_traps
        reset_shell "${old_opts-''}"
        echo -ne "stash made... "
        if [ -z "$(git diff)" ]; then
            echo -e "${GREEN}no changes${RESET}"
        else
            echo -e "${YELLOW}changes!${RESET}"
            dtab
            trap 'set_color;
echo -e "${trap_head}reset HEAD"
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
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

cbar "${BOLD}resetting...${RESET}"
if [ -n "${remote_tracking_branch:+dummy}" ]; then
    echo "resetting upstream remote tracking branch..."
    trap 'set_color
echo -e "${trap_head}branch -u ${remote_tracking_branch}"
unset_color
print_exit $?' EXIT
    if [ $git_ver_maj -lt 2 ]; then
        # old command
        git branch --set-upstream "${remote_tracking_branch}"
    else
        # modern command
        do_cmd git branch -u "${remote_tracking_branch}"
    fi
fi
cbar "${BOLD}you're done!${RESET}"
clear_traps
decho "exiting ${BASH_SOURCE##*/} with code zero... "
trap 'print_exit $?' EXIT
# add exit code for parent script
exit 0
