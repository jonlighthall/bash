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

check_arg1 "$@"
export in_file="$@"

# cd to repo root dir
if [[ ${PWD} -ef ${repo_dir} ]]; then
    echo "${TAB}already in top level directory"
else
    echo -e "${TAB}${PSDIR}$PWD${RESET} is part of a Git repository"
    echo -n "${TAB}moving to top level directory... " 
    start_dir="${PWD}"
    cd -L "$repo_dir"
    echo -e "${PSDIR}$PWD${RESET}"
    sub_dir=$(echo "${start_dir#$repo_dir}")
    #echo "$sub_dir"
    echo -en "redefining argument as... ${ARG}"
    echo -e "${sub_dir}/${in_file}${RESET}" | sed 's,^/,,'
    in_file=$(    echo "${sub_dir}/${in_file}" | sed 's,^/,,')
fi

#parse_remote_tracking_branch

first=true

function check_min() {
    if [ -z ${n_min+dummy} ]; then
        n_min=$tot
        hash_min=$hash
    fi

    if [ ${tot} -le ${n_min} ]; then
        if [[ "${first}" == true ]]; then
            :
        else
            echo
        fi
        echo -en "${TAB}${YELLOW}$hash${RESET}: "
        echo -n "$tot +/- changes, "
        if [ ${tot} -eq ${n_min} ]; then

            if [[ ! "${hash}" == ${hash_min} ]]; then
                hash_min+=( "$hash" )
            fi
            if [[ "${first}" == true ]]; then
                echo -n "first min"
                first=false
            else
                echo -n "same min"
            fi
        else
            hash_min=$hash
            echo -n "new min"
            itab
            git diff --no-pager --color=always --ignore-space-change --stat ${hash} ${in_file} | sed "s/^/$TAB/"
            dtab
        fi

        # update value of n_min
        n_min=$tot
    else
        echo -n "."
    fi
}

function sum_diff() {
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

    # exit loop of zero changes found
    if [ $tot -eq 0 ]; then
        break
    fi

    check_min
}

# check for log entries
cbar "${BOLD}parsing log...${RESET}"

N_log=$(git log --pretty=format:"%h" "${in_file}" | wc -l)

if ! [ $N_log -gt 0 ]; then
    echo "no log entries found"
    exit 1
fi

# read hashes into array
declare -a hash_list
readarray -t hash_list < <(git log --pretty=format:"%h" "${in_file}")
N_hash=${#hash_list[@]}
echo "${N_hash} entries in hash list"
itab
echo "${TAB}${hash_list[@]}"
dtab

echo
cbar "${BOLD}looping over log entries ...${RESET}"

itab
N_check=0
# loop over hashes
for ((n = 0; n < $N_hash ; n++)); do
    # select has from list
    hash="${hash_list[$n]}"

    # diff file with hash
    cmd="git --no-pager diff --ignore-space-change --numstat ${hash} ${in_file}"
    cmd_out=$(${cmd} 2>/dev/null)
    ((++N_check))
    # check if diff is empty
    if [ -z "${cmd_out}" ]; then
        # no diffs; stop loop
        echo -e "${TAB}${YELLOW}${hash}${RESET}: 0 changes"
        itab
        echo -e "${TAB}${GOOD} EMPTY: no diff${RESET}"
        dtab
        hash_min=${hash}
        #break
    else
        # sum diffs and check min
        sum_diff
    fi
done
dtab
echo
echo "${TAB}done"
echo "${N_check} hashes checked"

# print minimum difference
git --no-pager diff ${hash_min} -- "${in_file}"

echo
set_exit
