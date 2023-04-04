#!/bin/bash
#
# find_matching.sh - Reads an input list of files name patterns. Any files matching the
# individual patterns are saved to a new list of file names. handling is included to backup any
# duplicated input/output file names.
#
# Adapted from find_missing_and_empty.sh
#
#JCL Apr 2023

TAB="   "
# set file names
file_in=$1
fname=found.txt
base="${fname%.*}"
ext="${fname##*.}"
file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}

# initialize counters
k=0 # files in list

# check for input
if [ $# -eq 0 ]
then
    echo "Please provide an input file"
    exit 1
else
   # check if input and output are the same file
    echo -n " input file ${file_in} is... "
    while [ ${file_in} -ef ${file_out} ]; do
        eqcho "the same file as ${file_out}"
	echo "${TAB}waiting..."
	sleep 1
        echo -n "${TAB}renaming output..."
	file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
	echo ${file_out}
    done
    echo "OK"

    # check if output exists
    echo -n "output file ${file_out}... "
    while [ -f ${file_out} ]; do
        echo "exists"
	echo "${TAB}waiting..."
	sleep 1
        echo -n "${TAB}renaming output..."
	file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
	echo ${file_out}
    done
    echo "OK"

    # read input file
    while read line; do
        fname=$line
        ((k++))
	echo -n "$k looking for ${fname}..."
	find ./ -type f -name *${fname}* >> ${file_out}
	echo "done"
    done < $file_in
    echo $k "filenames checked"
    echo $(cat ${file_out} | wc -l) "files found"
fi
