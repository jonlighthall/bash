#!/bin/bash -eu
# -----------------------------------------------------------------------------------------------
#
# cp_date.sh
#
# Purpose : Create a copy of input file to include modification date.
#
# Adapted from mv_date.sh
#
# Mar 2024 JCL
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
check_arg1 $@

if [ $# -eq 2 ]; then
    declare  -n out_name=$2
    echo "${TAB}argument 2: $2"
fi

echo "${TAB}generate unique file name..."
declare out_file
get_unique_name $1 out_file
[ $? -eq 1 ] && exit

# now copy file
echo "${TAB}copying file..."
itab
echo -n "${TAB}"
if [ -L "${in_file}" ]; then
    # do not follow links, copy the link itself
    cp -nPpv "${in_file}" "${out_file}"
else
    if [ -d "${in_file}" ]; then
        # recursive copy
        cp -nprv "${in_file}" "${out_file}"
    else
        # no-clobber and preserve
        cp -npv "${in_file}" "${out_file}"
    fi
fi
dtab 2
if [ $# -eq 2 ]; then
    out_name=${out_file}
    echo "${!out_name} = ${out_name}"
fi
