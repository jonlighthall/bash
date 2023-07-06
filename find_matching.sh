#!/bin/bash
#
# find_matching.sh - Reads an input list of files name patterns. Any files matching the
# individual patterns are saved to a new list of file names. Handling is included to backup any
# duplicated input/output file names.
#
# Adapted from find_missing_and_empty.sh
#
# The first argument is the list file of patterns.
#
# Second argument is the search directory or file
#
#
# Use example:
# find_matching list_of_patterns.txt search_dir
#
# the command will locate the files matching the pattern and write the matches to file. For
# example below, the search pattern (first line) matches the file name (second line) found by
# running the command.
#
# file_name_???
# dir/new_file_name123.bin
#
# Apr 2023 JCL

TAB="   "

# initialize counters
k=0 # files in list

# check for input
if [ $# -eq 0 ]; then
    echo "Please provide an input file"
    exit 1
else
    echo "number of arguments = $#"

    # set file names
    file_in=$(readlink -f $1)
    echo "argument 1: $1"
    echo "input file: ${file_in}"

    # set default output file name to match input
    dir1=$(dirname $file_in)
    echo "input dir = $dir1"
    fname1=$(basename $file_in)
    echo "input file = $fname1"
    base1="${fname1%.*}"
    echo "base name = $base1"
    if [[ $fname1 == *"."* ]]; then
	echo "fname contains dots"
	ext="${fname1##*.}"
    else
	echo "fname does not contains dots, using default"
	ext="txt"
    fi
    base="${base1}_found"

    file_spec="${dir1}/${base}.${ext}"
    echo "file specification = $file_spec"

    file_out=${file_spec}
    echo $file_out

    # check if input and output are the same file
    echo -n " input file ${file_in} is... "
    while [ ${file_in} -ef ${file_out} ]; do
        echo "the same file as ${file_out}"
        echo -n "${TAB}renaming output... "
	file_out=${dir1}/${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
	echo ${file_out}
    done
    echo "uniquely named"

    # check if output exists
    echo -n "output file ${file_out}... "
    while [ -f ${file_out} ]; do
        echo "exists"
        echo -n "${TAB}renaming output... "
	file_out=${dir1}/${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
	echo ${file_out}
    done
    echo "${TAB}unique file name found"

    # read input file
    j=$(cat ${file_in} | wc -l)
    echo " input file ${file_in} has $j entries"

    # parse arguments
    if [ $# -lt 2 ]; then
	echo "no search location given"
	echo "defaulting to PWD"
	search_dir=$(readlink -f $PWD)
    else
	search_dir=$(readlink -f $2)
    fi
    # check for search directory
    echo -n "search directory ${search_dir}... "
    if [ -d $search_dir ];then
	echo "OK"
    else
	echo "not found"
	exit 1
    fi

    # set print frequency
    if [ $j -lt 10 ]; then
	nprint=1
    else
	nprint=$((j/10))
    fi
    echo "${TAB}printing one results for every $nprint lines"

    while read line; do
        fname=$line
        ((k++))
	if [ $(( k % $nprint)) -eq 0 ]; then
	    echo -ne "\n$k/$j looking for ${fname}... "
	else
	    echo -n ","
	fi
	find $search_dir -type f -name *${fname}* >> ${file_out}
	if [ $(( k % $nprint)) -eq 0 ]; then
	    echo "done"
	else
	    echo -n "."
	fi
    done < $file_in
    echo
    echo $k "file names checked"
    echo "$((j-k)) files not searched for"
    l=$(cat ${file_out} | wc -l)
    echo "$l files found"
    echo "$((j-l)) files not found"
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
