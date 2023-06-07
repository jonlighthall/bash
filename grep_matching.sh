#!/bin/bash
#
# grep_matching.sh - Reads an input list of files name regex patterns. Any files matching the
# individual patterns are saved to a new list of file names. Handling is included to backup any
# duplicated input/output file names.
#
# Adapted from find_matching.sh
#
# The first argument is the FILE containing a list regex patterns corresponding to the desired
# files.
#
# The second argument is the FILE containing a list of files to be searched, e.g. the 'ls'
# contents of a directory.
#
# Use example:
#
# Say ./big_dir is a huge directory for which using 'find' iteratively is too slow. Use the
# command
#
# \ls -L ./big_dir > list_of_files.txt
# then perhpas cat list_of_files | awk '{print $9}' | sed '/^$/d' > list_of_files.txt
# or just \ls -L -1 ./big_dir > list_of_files.txt
#
# Then, run the following command.
#
# grepd_matching list_of_patterns.txt list_of_files.txt
#
# The command will locate the files matching the pattern and write the matches to file.

# For example, if you want to locate a file matching the pattern 'file_name_[0-9]\{6\},' save
# that pattern in a file, replacing all \ with \\. Call the command with the pattern file as the
# first argument and the search location as the second argument. If pattern matches a line in the
# search file, the resulting output file big_dir_found.txt will have content such as
# 'dir/new_file_name_123456.bin'
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
	echo "no file to search specified"
	exit 1
    else
	echo -n "search file $2... "
	# check for search file
	if [ -f $2 ]; then
	    echo "OK"
	else
	    echo "not found"
	    exit 1
	fi
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
	echo -ne "\x1b[2K\r$k/$j"
	if [ $(( k % $nprint)) -eq 0 ]; then
	    echo -ne " looking for ${fname}... "
	fi
	grep "${fname}" $2 >> ${file_out}
	if [ $(( k % $nprint)) -eq 0 ]; then
	    echo "done"
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
echo -e "\n$(date +"%a %b %d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
