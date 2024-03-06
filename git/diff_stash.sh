#!/bin/bash -u

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
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

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

echo -n "checking repository status... "
git rev-parse --is-inside-work-tree &>/dev/null
RETVAL=$?
if [[ $RETVAL -eq 0 ]]; then
    echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
else
    echo "${TAB}$repo not a Git repository"
    exit 1
fi

# get repo name
repo_dir=$(git rev-parse --show-toplevel)
echo "repository directory is ${repo_dir}"
repo=${repo_dir##*/}
echo "repository name is $repo"

# parse remote
echo
cbar "${BOLD}parse remote tracking branch...${NORMAL}"
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
    # parse branches
    branch_remote=${remote_tracking_branch#*/}
    echo "${TAB}remote branch: $branch_remote"

    branch_local=$(git branch | grep \* | sed 's/^\* //')
    echo -e "${TAB} local branch: ${green}${branch_local}${NORMAL}"
    echo
fi

# check remotes
cbar "${BOLD}parsing remotes...${NORMAL}"
r_names=$(git remote)
if [ "${n_remotes}" -gt 1 ]; then
    echo "remotes found: ${n_remotes}"
else
    echo -n "remote: "
fi
for remote_name in ${r_names}; do
    echo
    echo "${TAB}$remote_name"
    remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
    echo "${fTAB}url: ${remote_url}"
    remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
    if [[ "${remote_pro}" == "git" ]]; then
        remote_pro="SSH"
        rhost=$(echo ${remote_url} | sed 's/\(^[^:]*\):.*$/\1/')
    else
        rhost=$(echo ${remote_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
        if [[ "${remote_pro}" == "http"* ]]; then
            remote_pro=${GRH}${remote_pro}${NORMAL}
            remote_repo=$(echo ${remote_url} | sed 's,^[a-z]*://[^/]*/\(.*\),\1,')
            echo "  repo: ${remote_repo}"
            remote_ssh="git@${rhost}:${remote_repo}"
            echo " change URL to ${remote_ssh}..."
            echo " ${fTAB}git remote set-url ${remote_name} ${remote_ssh}"
            git remote set-url ${remote_name} ${remote_ssh}
        else
            remote_pro="local"
        fi
    fi
    echo "  host: $rhost"
    echo -e " proto: ${remote_pro}"
done

# check for stash entries
echo
cbar "${BOLD}parsing stash...${NORMAL}"
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo -e "$repo has $N_stash entries in stash"

    for ((n = 0; n < $N_stash; n++)); do
        echo
        stash="stash@{$n}"
        echo "${stash}"
        git log -1 ${stash}

        unset n_min
        unset hash_min

        for hash in $(git rev-list HEAD); do
            echo -n "$hash: "
            n_diff=$(git diff $hash $stash | wc -l)
            if [ -z $n_diff ]; then
                echo $n_diff
            fi
        done
    done
fi

echo
