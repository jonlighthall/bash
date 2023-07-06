#!/bin/bash
#
# find_matching.sh - Reads an input list of files name patterns. Any files matching the
# individual patterns are saved to a new list of file names. Handling is included to backup any
# duplicated input/output file names.
#
# Adapted from find_missing_and_empty.sh
#
# The first argument is the FILE containing a list of files to be moved.
#
# The second argument is the DIRECTORY specifying the named sub-directory to move the matching files
#
# Use example:

# find_matching output.txt subdir
#
#  the command will take the located files specified by the list and move them to the
# sub-directory subdir. For example below, the search pattern (first line) matches the file name
# (second line) found by running the first command. The file is then moved to the new
# sub-directory with the second command.
#
# file_name_???
# dir/new_file_name123.bin
# dir/subdir/new_file_name123.bin
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

    echo -n " input file ${file_in}... "
    if [ -f ${file_in} ]; then
	echo "exits"

	# read input file
	j=$(cat ${file_in} | wc -l)
	echo "${TAB}and has $j entries"

	# set print frequency
	if [ $j -lt 10 ]; then
	    nprint=1
	else
	    nprint=$((j/10))
	fi
	#	echo "${TAB}printing one results for every $nprint lines"

	if [ $# -eq 1 ]; then
	    echo "Please provide a target subdirectory"
	    exit 1
	else
	    echo "argument 2: $2"
	    while read line; do
		fname=$line
		((k++))
		#	    if [ $(( k % $nprint)) -eq 0 ]; then
		echo -n "$k looking for ${fname}... "
		#	    else
		#		echo -n $k
		#	    fi

		dir_par=${fname%/*}
		dir_mv=${dir_par}/$2
		if ! [ -d ${dir_mv} ]; then
		    echo "${dir_mv} not found"
		    mkdir -pv ${dir_mv}
		fi
		if [ -f ${fname} ]; then
		    #		if [ $(( k % $nprint)) -eq 0 ]; then
		    echo "done"
		    #		else
		    #		    echo -n "."
		    #		fi

		    #		echo -n ${TAB}
		    mv ${fname} ${dir_mv} | sed "s/^/${TAB}/"
		else
		    echo "not found"
		fi

	    done < $file_in
	    echo
	    echo $k "file names checked"
	fi
    else
	echo "does not exit"
	exit 1
    fi
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
