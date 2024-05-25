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
for library in git; do
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

cbar "${BOLD}check directory...${RESET}"
check_repo

# get repo name
repo_dir=$(git rev-parse --show-toplevel)
echo -e "repository directory is ${PSDIR}${repo_dir}${RESET}"
repo=${repo_dir##*/}
echo "repository name is $repo"

GITDIR=$(readlink -f $(git rev-parse --git-dir))
echo "the .git folder is $GITDIR"
if [[ ${PWD} -ef ${repo_dir} ]]; then
    echo "already in top level directory"
else
    echo "$PWD is part of a Git repository"
    echo "moving to top level directory..."
    cd -L $repo_dir
    echo "$PWD"
fi

# parse remote
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

function check_min() {
    if [ -z ${n_min+dummy} ]; then
        n_min=$tot
        hash_min=$hash
    fi

    if [ ${tot} -le ${n_min} ]; then
        [ $i_count -gt 0 ] && echo
        echo -n "${TAB}$hash: "
        echo -n "$tot +/- changes "
        if [ ${tot} -eq ${n_min} ]; then

            if [[ ! "${hash}" == ${hash_min} ]]; then
                hash_min+=( "$hash" )
            fi
            echo "same min"
        else
            unset hash_min
            hash_min=$hash
            echo "new min"

            git diff --ignore-space-change --stat ${hash} ${stash} -- $fname
        fi
        echo "${TAB}${hash_min[@]}"
        [ $i_count -gt 0 ] && echo -n "${TAB}"
        n_min=$tot
    else
        [ $i_count -eq 0 ] && echo -n "${TAB}"
        ((++i_count))
        if [ $((i_count % 10)) -eq 0 ]; then
            echo ". $i_count"
            echo -n "${TAB}"
        else
            echo -n "."
        fi
        if [ $i_count -gt 500 ]; then
            break
        fi
    fi
}

#check_remotes

# check for stash entries
cbar "${BOLD}parsing stash...${RESET}"
N_stash=$(git stash list | wc -l)

if [ $N_stash -gt 0 ]; then
    echo -e "$repo has $N_stash entries in stash"
    do_cmd_stdbuf git stash list
    cbar "${BOLD}looking for duplicate stashes...${RESET}"
    
    # loop over stash entries
    loop_lim=$(($N_stash-1))
    for ((n = 0; n < loop_lim; n++)); do
        echo "n = $n (start)"
        # check entries
        N_stash_in=$(git stash list | wc -l)

        if [ $N_stash_in = $N_stash ]; then
            echo "no change in number of stash entries ($N_stash_in)"
        else
            echo "number of stash entries has changed"
            echo "$repo now has $N_stash_in entries in stash"

            # check limit
            echo "old loop limit = $loop_lim"
            new_lim=$((N_stash_in-1))
            echo "new limit should be $new_lim"
            if [ $n -ge $new_lim ]; then
                echo "new limit exceeded"
                echo "breaking..."
                break
            fi
        fi

        stash="stash@{$n}"
        next="stash@{$(($n+1))}"
        cmd="git diff --ignore-space-change --stat $stash $next"
        echo $cmd
        $cmd
        # check if empty
        if [ -z "$(git diff --ignore-space-change --stat $stash $next 2>&1)" ]; then
            # print commit
            echo "${stash} $next"
            git log -1 ${stash}
            echo
            echo -e "${BAD}EMPTY: no diff"
            
            # remove duplicate stash
            git stash drop ${stash}
            echo -en "${RESET}"

            # drecrement counter
            ((--n))
        fi
        echo "n = $n (end)"
    done
fi

# update stash list
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo -e "$repo has $N_stash entries in stash"

    if [ -z "$@" ]; then
        n_start=0;
    else
        n_start=$1;
    fi

    if [ $n_start -ge $N_stash ]; then
        echo "cannot diff stash $1"
        echo "stash only has $N_stash entries"
        exit 1
    fi

    echo
    cbar "${BOLD}checking stash entry ${n_start}...${RESET}"

    # loop over stash entries
    for ((n = $n_start; n < ((n_start + 1 )); n++)); do
        stash="stash@{$n}"
        echo "${stash}"
        git log -1 ${stash}
        echo

        # get names of stashed files
        cmd="git diff --ignore-space-change --name-only ${stash}^ ${stash}"
        echo $cmd
        $cmd 


        if [ -z $(${cmd}) ]; then
            # check if stash is empty
            echo -e "${BAD}EMPTY: no diff"
            echo "stash@{$n} has no diff"
            git stash drop stash@{$n}
            echo -en "${RESET}"
            continue
        else
            for fil in $($cmd); do
                stash_files+=( "$fil" )
            done
        fi

        # list stashed files
        echo "stashed files: "
        itab
        n_stash_files=${#stash_files[@]}
        echo "${TAB}$n_stash_files files found"
        echo "${stash_files[@]}" | sed "s/ /\n/g" | sed "s/^/${TAB}/"
        dtab

        cbar "${BOLD}looping over files in stash@{$n}...${RESET}"

        # loop over stashed files
        for fname in ${stash_files[@]}; do
            echo -e "${TAB}${YELLOW}$fname${RESET}..."
            itab
            # define counters
            unset n_min
            unset hash_min
            declare -i i_count=0

            # get list of hashes before stash that contain file
            cmd="git rev-list ${stash}^ -- $fname"
            echo "${TAB}${cmd}"

            n_rev=$($cmd | wc -l)
            echo "${TAB}$n_rev revisions found"

            for hash in $($cmd); do
                # git diff --stat ${hash} ${stash} -- $fname
                # git diff --numstat ${hash} ${stash} -- $fname
                add=$(git diff --ignore-space-change --numstat ${hash} ${stash} -- $fname | awk '{print $1}' )
                sub=$(git diff --ignore-space-change --numstat ${hash} ${stash} -- $fname | awk '{print $2}' )

                if [ -z "$add" ]; then
                    add=0
                fi

                if [ -z "$sub" ]; then
                    sub=0
                fi

                # get total number of changes
                declare -i tot=$(( $add + $sub))

                # exit loop of zero changes found
                if [ $tot -eq 0 ]; then
                    break
                fi

                check_min

            done

            echo
            # get list of hashes after stash, up to HEAD, that contain file
            cmd="git rev-list ${stash}^..HEAD -- $fname"
            echo "${TAB}${cmd}"
            n_rev=$($cmd | wc -l)
            echo "${TAB}$n_rev revisions found"
            i_count=0

            for hash in $($cmd); do
                # git diff --stat ${hash} ${stash} -- $fname
                # git diff --numstat ${hash} ${stash} -- $fname
                add=$(git diff --ignore-space-change --numstat ${hash} ${stash} -- $fname | awk '{print $1}' )
                sub=$(git diff --ignore-space-change --numstat ${hash} ${stash} -- $fname | awk '{print $2}' )

                if [ -z "$add" ]; then
                    add=0
                fi

                if [ -z "$sub" ]; then
                    sub=0
                fi

                # get total number of changes
                declare -i tot=$(($add+$sub))

                # exit loop of zero changes found
                if [ $tot -eq 0 ]; then
                    break
                fi
                check_min
            done
            echo
            echo "${TAB}minimum diff:"
            itab
            echo "${TAB}$n_min +/- changes"
            echo "${hash_min[@]} " | sed "s/ /\n/g" | sed "s/^/${TAB}/"
            dtab

            cmd="git --no-pager diff --color-moved=blocks --ignore-space-change ${hash_min} ${stash} -- $fname"
            echo "${TAB}$cmd"

            do_cmd_script $cmd
            dtab

        done # files
        echo "use git stash drop stash@{$n} to delete"
    done # stash entreis
else
    echo "no stash entries found"
fi
echo
