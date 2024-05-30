#!/bin/bash -u
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

# set debug level
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

# check for input
check_arg1 $@

if [ $# -eq 2 ]; then
    declare  -n out_name=$2
    echo "${TAB}argument 2: $2"
    dtab
fi

dtab
echo "${TAB}getting modifcation date..."
declare out_file
get_mod_date $1 out_file

# now copy file
echo "${TAB}copying file..."
itab
echo -n "${TAB}"
if [ -L "${in_file}" ]; then
    cp -nPpv "${in_file}" "${out_file}"
else

    cp -npv "${in_file}" "${out_file}"
fi
dtab 2
if [ $# -eq 2 ]; then
    out_name=${out_file}
    echo "${!out_name} = ${out_name}"
fi

trap 'print_exit' EXIT
