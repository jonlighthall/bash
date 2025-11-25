#!/bin/bash -u
# -----------------------------------------------------------------------------------------------
#
# mv_date.sh
#
# Purpose: Rename input file to include modification date.
#
# Adapted from grep_matching.sh
#
# Apr 2023 JCL
#
# -----------------------------------------------------------------------------------------------

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set debug level
# substitute default value if DEBUG is unset or null
declare -i DEBUG=${DEBUG:-0}

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi
print_source

# load date library
for library in date; do
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

trap 'print_exit' EXIT

# check for input
check_arg1 "$@"

if [ $# -eq 2 ]; then
    declare -n out_name="$2"
    echo "${TAB}argument 2: $2"
fi

declare out_file
get_unique_name "$1" out_file
[ $? -eq 1 ] && exit

# now move file
echo "${TAB}moving file..."
itab
echo -n "${TAB}"
# no-clobber
mv -nv "${in_file}" "${out_file}"
dtab 2
if [ $# -eq 2 ]; then
    out_name=${out_file}
    echo "${!out_name} = ${out_name}"
fi
