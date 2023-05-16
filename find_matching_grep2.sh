#!/bin/bash
#
# find_matching.sh - Reads an input list of files name patterns. Any files matching the
# individual patterns are saved to a new list of file names. Handling is included to backup any
# duplicated input/output file names.
#
# Adapted from find_missing_and_empty.sh
#
# First argument is the list file of patterns
#
# Second argument search directory or file
#
#
# Use example:
# find_matching list_of_patterns.txt output.txt
#
# the command will locate the files matching the pattern and write the matches to file. For
# example below, the search pattern (first line) matches the file name (second line) found by
# running the command.
#
# file_name_???
# dir/new_file_name123.bin
#
#JCL Apr 2023

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
    echo "$1"
    echo "${file_in}"


    # set default output file name to match input
    dir1=$(dirname $file_in)
    echo "dir = $dir1"
    fname1=$(basename $file_in)
    echo "input file = $fname1"
    base="${fname1%.*}"
    echo "base name = $base"
    if [[ $fname1 == *"."* ]]; then
	echo "fname contains dots"
	ext1="${fname1##*.}"
    else
	echo "fname contains not dots, using default"
	ext1="txt"
    fi
    file_spec="${dir1}/${base}_found.${ext1}"

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
    echo "OK"

    # check if output exists
    echo -n "output file ${file_out}... "
    while [ -f ${file_out} ]; do
        echo "exists"
        echo -n "${TAB}renaming output... "
	file_out=${dir1}/${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
	echo ${file_out}
    done
    echo "OK"

    # read input file
    j=$(cat ${file_in} | wc -l)
    echo " input file ${file_in} has $j entries"

    while read line; do
        fname=$line
        ((k++))
	echo -n "$k looking for ${fname}... "

	echo "$2 is a... "
	if [ -f $2 ]; then
	    # otherwise write match to file
	    echo "file"
	else
	    echo -n "not a file, but "
	    if [ -d $2 ]; then
		echo "a directory"
		find ./ -type f -name *${fname}* >> ${file_out}
		echo "done"
	    else
		echo "something else"
		exit 1
	    fi
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
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"