#!/bin/bash -u

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# load formatting and functions
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "${fpretty}" ]; then
    source "${fpretty}"
else
    # ignore undefined variables
    set +u 
    # do not exit on errors
    set +e
fi

# set debug level
# substitue default value if DEBUG is unset or null
DEBUG=${DEBUG:-0}
print_debug

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
    set +e
    trap 'echo -en "${YELLOW}RETURN${RESET}: ${BASH_SOURCE##*/} "' RETURN
else
    RUN_TYPE="executing"
    # exit on errors
    set -e
    trap 'print_error $LINENO $? $BASH_COMMAND' ERR
    # print time at exit
    trap print_exit EXIT
fi
print_source

# load git utils
for library in git cmd; do
    # use the canonical (physical) source directory for reference; this is important if sourcing
    # this file directly from shell
    fname="${src_dir_phys}/lib_${library}.sh"
    if [ -e "${fname}" ]; then
        if [[ "$-" == *i* ]] && [ ${DEBUG:-0} -gt 0 ]; then
            echo "${TAB}loading $(basename ${fname})"
        fi
        source "${fname}"
    else
        echo "${fname} not found"
    fi
done

check_repo

# get repo name
repo_dir=$(git rev-parse --show-toplevel)
echo "repository directory is ${repo_dir}"
repo=${repo_dir##*/}
echo "repository name is $repo"

# parse remote
echo
cbar "${BOLD}parse remote tracking branch...${RESET}"
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "${TAB}no remote tracking branch set for current branch"
else
    remote_tracking_branch=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "${TAB}remote tracking branch: ${BLUE}${remote_tracking_branch}${RESET}"
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
    echo -e "${TAB} local branch: ${GREEN}${branch_local}${RESET}"
fi

#check_remotes

# check for stash entries
echo
cbar "${BOLD}parsing stash...${RESET}"
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo -e "$repo has $N_stash entries in stash"

    for ((n = 0; n < $N_stash; n++)); do
        echo
        stash="stash@{$n}"
        echo "${stash}"
        git log -1 ${stash}
        #continue

        stash_files="$(git diff --name-only ${stash}^ ${stash})"

        if [ -z "${stash_files}" ]; then
            echo "stash@{$n} has no diff"
            git stash drop stash@{$n}
            continue
            
        fi
        

        echo "stashed files: "
        echo "${stash_files}" | sed "s/^/   /"

        for fname in $stash_files; do

            echo "$fname"

            unset n_min
            unset hash_min
            declare -i i_count=0

            for hash in $(git rev-list ${stash}^); do
                echo -n "$hash: "

                #                git diff --stat ${hash} ${stash} -- $fname

                #               git diff --numstat ${hash} ${stash} -- $fname
                add=$(git diff --numstat ${hash} ${stash} -- $fname | awk '{print $1}' )
                sub=$(git diff --numstat ${hash} ${stash} -- $fname | awk '{print $2}' )

                declare -i tot=$(($add+$sub))
                
                echo $tot

                if [ $tot -eq 0 ]; then
                    break
                fi

                if [ -z ${n_min+dummy} ]; then
                    n_min=$tot
                    hash_min=$hash
                    continue
                fi

                if [ ${tot} -lt ${n_min} ]; then
                    n_min=$tot
                    hash_min=$hash
                    echo "new min"
                else
                    ((++i_count))
                    if [ $i_count -gt 5 ]; then
                        break
                    fi

                fi

            done

            echo

            
        done

        
    done
else
    echo "no stash entries found"
fi

echo
