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
# Second argument is the name of the output file
#
# Third argument specifies the named sub-directory to move the matching files
#
# Use example:
# find_matching list_of_patterns.txt output.txt
# find_matching output.txt dummy subdir
#
# the first command will locate the files matching the pattern and write the matches to file. the
# second command will take the located files specified by the list and move them to the
# sub-directory subdir. For example below, the search pattern (first line) matches the file name
# (second line) found by running the first command. The file is then moved to the new
# sub-directory with the second command.
#
# file_name_???
# dir/new_file_name123.bin
# dir/subdir/new_file_name123.bin
#
#JCL Apr 2023

TAB="   "
# set file names
file_in=$1

# initialize counters
k=0 # files in list

# check for input
if [ $# -eq 0 ]; then
    echo "Please provide an input file"
    exit 1
else
    # second argument (output) becomes dummy variable if third argument is specified
    if [ $# -lt 3 ]; then
	if [ $# -ge 2 ]; then
	    file_spec=$2
	else
	    # set default output file name to match input
	    base1="${1%.*}"
	    if [[ "$1" == *"."* ]]; then
		ext1="${1##*.}"
	    else
		ext1="txt"
	    fi
	    file_spec="${base1}_found.${ext1}"
	fi
	base="${file_spec%.*}"
	if [[ "{file_spec}" == *"."* ]]; then
	    ext="${file_spec##*.}"
	else
	    ext="txt"
	fi

	file_out=${base}.${ext}

	# check if input and output are the same file
	echo -n " input file ${file_in} is... "
	while [ ${file_in} -ef ${file_out} ]; do
            echo "the same file as ${file_out}"
            echo -n "${TAB}renaming output... "
	    file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
	    echo ${file_out}
	done
	echo "OK"

	# check if output exists
	echo -n "output file ${file_out}... "
	while [ -f ${file_out} ]; do
            echo "exists"
            echo -n "${TAB}renaming output... "
	    file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
	    echo ${file_out}
	done
	echo "OK"
    fi

    # read input file
    j=$(cat ${file_in} | wc -l)
    echo " input file ${file_in} has $j entries"

    while read line; do
        fname=$line
        ((k++))
	echo -n "$k looking for ${fname}... "
	# if third argument present, mv file
	if [ $# -ge 3 ]; then
	    dir_par=${fname%/*}
	    dir_mv=${dir_par}/$3
	    if ! [ -d ${dir_mv} ]; then
		echo "${dir_mv} not found"
		mkdir -pv ${dir_mv}
	    fi
	    if [ -f ${fname} ]; then
		echo
#		echo -n ${TAB}
		mv -v ${fname} ${dir_mv} | sed "s/^/${TAB}/"
	    else
		echo "not found"
	    fi

	    # otherwise write match to file
	else
	    find ./ -type f -name *${fname}* >> ${file_out}
	    echo "done"
	fi
    done < $file_in
    echo
    echo $k "file names checked"
    if [ $# -lt 3 ]; then
	echo "$((j-k)) files not searched for"
	l=$(cat ${file_out} | wc -l)
	echo "$l files found"
	echo "$((j-l)) files not found"
    fi
fi
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"