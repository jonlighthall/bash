#!/bin/bash -eu
# -----------------------------------------------------------------------------------------------
#
# git/diff_stash.sh
#
# PURPOSE:
#
# METHOD:
#
# USAGE:
#
# Feb 2024 JCL
#
# -----------------------------------------------------------------------------------------------

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
else
    # ignore undefined variables
    set +u
    # do not exit on errors
    set +e
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

cbar "${BOLD}check directory...${RESET}"
if ! check_repo 1 ; then
    echo -e "${DIR}$PWD${RESET} is not a Git repository"
    exit 1
fi

# get root dir
repo_dir=$(git rev-parse --show-toplevel)
echo -e "${TAB}repository directory is ${PSDIR}${repo_dir}${RESET}"
# get repo name
repo=${repo_dir##*/}
echo "${TAB}repository name is $repo"
# get git dir
GITDIR=$(readlink -f "$(git rev-parse --git-dir)")
echo -e "${TAB}the git-dir folder is ${PSDIR}${GITDIR##*/}${RESET}"
# cd to repo root dir
if [[ ${PWD} -ef ${repo_dir} ]]; then
    echo "${TAB}already in top level directory"
else
    echo "${TAB}$PWD is part of a Git repository"
    echo "${TAB}moving to top level directory..."
    cd -L "$repo_dir"
    echo "${TAB}$PWD"
fi

parse_remote_tracking_branch

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
            hash_min=
            hash_min=$hash
            echo "new min"
            itab
            git diff --color=always --ignore-space-change --stat ${hash} ${in_file} | sed "s/^/$TAB/"
            dtab
        fi

        # print current list of hashes with number of changes equal to n_min
        [ $i_count -gt 0 ] && echo -n "${TAB}"

        # update value of n_min
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

    fi
}

function loop_hash() {
    echo "${TAB}${cmd}"

    i_count=0

    # git diff --ignore-space-change --stat ${hash} ${stash} -- $fname
    add=$(${cmd} | awk '{print $1}' )
    sub=$(${cmd} | awk '{print $2}' )

    if [ -z "$add" ]; then
        add=0
    fi

    if [ -z "$sub" ]; then
        sub=0
    fi

    # get total number of changes
    declare -i tot=$(($add+$sub))
    echo $tot

    # exit loop of zero changes found
    if [ $tot -eq 0 ]; then
        break
    fi

    check_min

    echo
}

check_arg1 "$@"
export in_file="$@"

# check for stash entries
cbar "${BOLD}parsing log...${RESET}"

N_log=$(git log --pretty=format:"%h" "${in_file}" | wc -l)

if ! [ $N_log -gt 0 ]; then
    echo "no log entries found"
    exit 1
fi
echo -e "${TAB}repo has $N_log entries in stash"

declare -a hash_list
readarray -t hash_list < <(git log --pretty=format:"%h" "${in_file}")

N_hash=${#hash_list[@]}

echo "${N_hash} entries in hash list"

echo "first: ${hash_list[1]}"

for ((n = 0; n < $N_hash ; n++)); do
    echo "hash $n = ${hash_list[$n]}"
done

echo
cbar "${BOLD}checking log entries ...${RESET}"

# loop over stash entries
for ((n = 0; n < $N_hash ; n++)); do

    hash="${hash_list[$n]}"
    echo "${TAB}${hash}"
    itab

    # get names of stashed files
    cmd="git diff --ignore-space-change --numstat ${hash} ${in_file}"
    echo "${TAB}$cmd"
    do_cmd_in $cmd

    if [ -z "$(${cmd})" ]; then
        # check if diff is empty
        echo -e "${TAB}${GOOD}EMPTY: no diff${RESET}"
        echo -e "${TAB}${YELLOW}${hash}${RESET} has no diff"
        break
    else
        loop_hash
    fi
    dtab
   
done # stash entreis
dtab
echo "${TAB}donexxx"
echo
set_exit
