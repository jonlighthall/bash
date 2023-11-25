#!/bin/bash -u
#
# git/force_pull.sh - this script was developed to synchronize the local repository with the
# remote repository after a force push; hence the name. It assumes that---in the case of a force
# push---that the two repsoitories have common commit times, if not common hashes; this would be
# the case the history has been rewritten to update author names, for example. It is also useful
# for synchonizing diverged repsoitories without explicitly merging.
#
# METHOD - 
#
# USAGE - the remote name and branch can be optionally specified by the first and second
# arguments, respectively. The default remote branch is the current tracking branch.
#
# Apr 2023 JCL

# start timer
start_time=$(date +%s%N)

# set tab
TAB=''
fTAB='   '

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
    # exit on errors
    set -eE
    trap 'echo -e "${BAD}ERROR${NORMAL}: exiting ${BASH_SOURCE##*/}..."' ERR
    trap 'echo -e "${yellow}EXIT${NORMAL}: exiting ${BASH_SOURCE##*/}..."' EXIT
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# parse remote
cbar "${BOLD}parse remote...${NORMAL}"
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "${TAB}no remote tracking branch set for current branch"
else
    remote_tracking_branch=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "${TAB}remote tracking branch: ${blue}${remote_tracking_branch}${NORMAL}"
    remote_name=${remote_tracking_branch%%/*}
    echo "${TAB}remote name: .......... $remote_name"
    remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
    echo "${TAB}remote url: ${remote_url}"
    remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
    echo "protocol:   ${remote_pro}"
    n_remotes=$(git remote | wc -l)
    if [ "${n_remotes}" -gt 1 ]; then
        echo "${n_remotes} remotes found"
    fi

    # parse branches
    branch_remote=${remote_tracking_branch#*/}
    echo "${TAB}remote branch: $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e "${TAB} local branch: ${green}${branch_local}${NORMAL}"

# parse arguments
cbar "${BOLD}parse arguments...${NORMAL}"
if [ $# -ge 1 ]; then
    remote_name=$1
else
    echo "${TAB}no remote specified"
    echo "${TAB}${fTAB}using $remote_name"
fi
if [ $# -ge 2 ]; then
    branch_remote=$2
else
    echo "${TAB}no remote branch specified"
    echo "${TAB}${fTAB}using $branch_remote"
fi
branch_pull=${remote_name}/${branch_remote}
if [ -z ${remote_name} ] || [ -z ${branch_remote} ]; then
    echo -e "${TAB}${BROKEN}ERROR: no remote tracking branch specified${NORMAL}"
    echo "${TAB} HELP: specify remote tracking branch with"
    echo "${TAB}       ${TAB}${BASH_SOURCE##*/} <repository> <refspec>"
    exit 1
else
    cbar "${BOLD}comparing local branch ${green}$branch_local${NORMAL} with remote branch ${blue}$branch_pull${NORMAL}"
fi

echo -n "${TAB}target branch and remote tracking branch... "
if [ "$branch_pull" == "$remote_tracking_branch" ]; then
    echo "match"
else
    echo "do not match"
fi

# before starting, fetch remote
echo "${TAB}fetching ${remote_name}..."
git fetch --verbose ${remote_name} ${branch_remote}

echo "comparing repositories based on commit hash..."
echo -n "${fTAB}leading remote commits: "
N_remote=$(git rev-list HEAD..${remote_tracking_branch} | wc -l)
echo "${N_remote}"

echo -n "${fTAB}trailing local commits: "
N_local=$(git rev-list ${remote_tracking_branch}..HEAD | wc -l)
echo "${N_local}"

if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    echo -e "${yellow}repsoitories have diverged{NORMAL}"
fi

echo "comparing repositories based on commit time..."
# determine latest common local commit, based on commit time
iHEAD=${branch_pull}

if [ ${N_remote} -gt 0 ]; then
    # print local and remote times
    echo " local time is $(git log ${branch_local} --format="%ad" -1)"
    echo "remote time is $(git log ${remote_tracking_branch} --format="%ad" -1)"

    # get local commit time
    T_local=$(git log ${branch_local} --format="%at" -1)

    echo "remote commits not found locally:"
    git rev-list ${remote_tracking_branch} --after=${T_local} | sed "s/^/${fTAB}/"

    echo -ne "number of commits:\n${fTAB}"
    git rev-list ${remote_tracking_branch} --after=${T_local} | wc -l

    echo "list of commits: "
    git log ${remote_tracking_branch} --after=${T_local}

    echo -ne "start by checking commit:\n${fTAB}"
    git rev-list ${remote_tracking_branch} --after=${T_local} | tail -1

    iHEAD=$(git rev-list ${remote_tracking_branch} --after=${T_local} | tail -1)
fi

hash_local=''
while [ -z ${hash_local} ]; do
    echo "${TAB}checking ${iHEAD}..."
    hash_remote=$(git log ${iHEAD} --format=%H  -n 1)
    subj_remote=$(git log ${iHEAD} --format=%s  -n 1)
    time_remote=$(git log ${iHEAD} --format=%at -n 1)
    TAB+=${fTAB:='   '}
    echo "${TAB}remote commit subject: $subj_remote"
    echo "${TAB}remote commit time: .. $time_remote or $(date -d @${time_remote} +"%a %b %-d %Y at %-l:%M %p %Z")"

    hash_local_s=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')
    hash_local=$(git log --format="%at %H " | grep "$time_remote" | awk '{print $2}')

    echo -n "${TAB}subject and time hashes... "
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
        hash_start=$(git rev-list $hash_local..HEAD | tail -n 1)
        if [ ! -z ${hash_start} ]; then
            echo
            git rev-list $hash_local..HEAD | sed "s/^/${TAB}/"
            N_local=$(git rev-list $hash_local..HEAD | wc -l)
            if [ $N_local -gt 1 ]; then
                echo -ne "${TAB}\033[3Dor ${hash_start}^.."
                hash_end=$(git rev-list $hash_local..HEAD | head -n 1)
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
hash_remote=$(git log ${branch_pull} | grep -B4 "${subj_remote}" | head -n 1 | awk '{print $2}')
echo -n "${TAB}corresponding remote commit hash: "
echo $hash_remote
TAB+=${fTAB:='   '}
echo -n "${TAB}common commit has... "
if [ $hash_local == $hash_remote ]; then
    echo "the same hash"
    echo -n "${TAB}merge base: .................. "
    git merge-base ${branch_local} ${branch_pull}
    hash_merge=$(git merge-base ${branch_local} ${branch_pull})
    echo -n "${TAB}common hash is... "
    if [ $hash_local == $hash_merge ]; then
        echo "the same as merge base"
    else
        echo "not the same as merge base"
    fi
else
    echo "a different hash (diverged)"
    echo " local: $hash_local"
    echo "remote: $hash_remote"
fi

# determine remote commits not found locally
echo -n "${TAB}leading remote commits: "
hash_start_remote=$(git rev-list $hash_remote..${branch_pull} | tail -n 1)
if [ ! -z ${hash_start_remote} ]; then
    echo
    git rev-list $hash_remote..${branch_pull} | sed "s/^/${TAB}/"
    N_remote=$(git rev-list $hash_remote..${branch_pull} | wc -l)
    if [ $N_remote -gt 1 ]; then
        echo -ne "${TAB}\033[3Dor ${hash_start_remote}^.."
        hash_end_remote=$(git rev-list $hash_remote..${branch_pull} | head -n 1)
        echo ${hash_end_remote}
    else
        hash_end_remote=$hash_start_remote
    fi
    echo -e "${TAB}${yellow}remote branch is $N_remote commits ahead of local${NORMAL}"
else
    echo -e "${green}none${NORMAL}"
    N_remote=0
fi
TAB=${TAB%$fTAB}
TAB=${TAB%$fTAB}

# get Git version
git_ver=$(git --version | awk '{print $3}')
git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')

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
cbar "${BOLD}copying local commits to new branch...${NORMAL}"
if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    echo -e "${yellow}repsoitories have diverged{NORMAL}"
    branch_temp=${branch_local}.temp
    echo "generating temporary branch..."
    i=0
    set +e
    while [[ ! -z $(git branch -va | sed 's/^.\{2\}//;s/ .*$//' | grep ${branch_temp}) ]]; do
        echo "${TAB}${fTAB}${branch_temp}"
        ((i++))
        branch_temp=${branch_local}.temp${i}
        echo "${TAB}${fTAB}checking ${branch_temp}"
    done
    echo "${TAB}${fTAB}found unused branch name ${branch_temp}"
    if (! return 0 2>/dev/null); then
        echo "${TAB}${fTAB}resetting exit on error"
        set -eE
    fi
    git checkout -b ${branch_temp}
    git checkout ${branch_local}
else
    echo -e "${TAB}${fTAB}no local commits to copy"
fi

# initiate HEAD
if [ $N_remote -gt 0 ]; then
    echo "resetting HEAD to $hash_remote..."
    git reset --hard $hash_remote | sed "s/^/${TAB}/"
fi

# pull remote commits
cbar "${BOLD}pulling remote changes...${NORMAL}"
if [ $N_remote -gt 0 ]; then
    echo -e "${TAB}${yellow}remote branch is $N_remote commits ahead of local${NORMAL}"
    git pull
else
    echo -e "${TAB}${fTAB}no need to pull"
fi

# push local commits
cbar "${BOLD}merging local changes...${NORMAL}"
if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
    echo -e "${yellow}repsoitories have diverged{NORMAL}"
    N_temp=$(git rev-list ${branch_temp}..${branch_local} | wc -l)
    echo -e "${TAB}${yellow}  temp branch is ${N_temp} commits ahead of ${branch_local}${NORMAL}"
    echo "${TAB}rebase..."
    git checkout ${branch_temp}
    git rebase ${branch_local}
    git checkout ${branch_local}
    echo "${TAB}merge..."
    git merge ${branch_temp}
    git branch -d ${branch_temp}
else
    echo -e "${TAB}${fTAB}no need to merge"
fi
cbar "${BOLD}pushing local changes...${NORMAL}"
if [ $N_local -gt 0 ]; then
    echo -e "${TAB}${fTAB}${yellow}local branch is $N_local commits ahead of remote${NORMAL}"
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
	set +e
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
cbar "${BOLD}you're done!${NORMAL}"

# print time at exit
echo -en "${BASH_SOURCE##*/} "
end_time=$(date +%s%N)
elap_time=$((${end_time} - ${start_time}))
dT_sec=$(bc <<<"scale=3;$elap_time/1000000000")
if command -v sec2elap &>/dev/null; then
    bash sec2elap $dT_sec | tr -d '\n'
else
    echo -n "elapsed time is ${white}${dT_sec} sec${NORMAL}"
fi
echo " on $(date +"%a %b %-d at %-l:%M %p %Z")"
