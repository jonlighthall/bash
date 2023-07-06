#!/bin/bash
#
# find_matching.sh - Reads an input list of files name patterns. Any files matching the
# individual patterns are saved to a new list of file names. handling is included to backup any
# duplicated input/output file names.
#
# Adapted from find_missing_and_empty.sh
#
# Apr 2023 JCL

TAB="   "
# set file names
file_in=$1

# check for input
if [ $# -eq 0 ]; then
    echo "Please provide an input file"
    exit 1
else
    if [ $# -ge 2 ]; then
	dir_mv=$2
    else
	dir_mv=./archives/
    fi

# check if output exists
    echo -n "output directory ${dir_mv}... "
    if [ -d ${dir_mv} ]; then
        echo "exists"
    else
	mkdir -pv ${dir_mv}
	echo "OK"
    fi

    # read input file
    while read line; do
        fname=$line
        ((k++))
	echo -n "$k looking for ${fname}... "
	if [ -f "${fname}" ]; then
	    echo "found"
	    base="${fname##*/}"
	    ver=$(echo "${base}" | sed  's$.*/$/$g' | sed 's/[^0-9]//g')
	    echo "${TAB}$base is v$ver"
	    maj_ver="${ver:0:1}"
	    min_ver="${ver:1:1}"
	    pat_ver="${ver:2}"

	    big_ver="${ver:0:2}"
	    echo "expected version is ${maj_ver}.${min_ver}.${pat_ver} or ${big_ver}"
	    dir_ver=${dir_mv%/*}/${big_ver}
	    mkdir -pv ${dir_ver}
	    	    echo -n "${TAB}checking output ${dir_ver}/${base}... "
	    if [ -f "${dir_ver}/${base}" ]; then
		echo "${base} already copied"
		echo "${TAB}----------- here ------------"
		ls "${dir_ver}/${base}"*
		nf=$(ls "${dir_ver}/${base}"* | wc -l)
		echo "${nf}"
		nn=$((nf + 1))
		echo "${nn}"
		cp -pvu "${fname}" ${dir_ver}/${base}.$nn | sed 's/^/   /'
		echo "${TAB}----------- here ------------"
	    else
		echo "${TAB}not found. copying... "
		cp -pvu "${fname}" ${dir_ver} | sed 's/^/   /'
	    fi
	    echo "${fname}" >> ${dir_ver}/source.txt
	else
	    echo "not found"
	fi
    done < $file_in
    echo
    echo $k "filenames checked"
    echo $(ls ${dir_mv} | wc -l) "files found"
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"