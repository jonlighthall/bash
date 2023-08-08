#!/bin/bash
#
# grep_matching.sh - Reads an input list of files name regex patterns. Any files matching the
# individual patterns are saved to a new list of file names. Handling is included to backup any
# duplicated input/output file names.
#
# Example:
#
#       grep_matching list_of_patterns.txt list_of_files.txt
#
#    The first argument is the FILE containing a list regex patterns corresponding to the desired
#    files. The second argument is the FILE containing a list of files to be searched, e.g. the
#    'ls' contents of a directory. The command will locate the files matching the pattern and
#    write the matches to file.
#
# Generating the list of files:
#
#    Say ./big_dir is a huge directory for which using 'find' iteratively is too slow. Use one of
#    the following commands to produce a list of files
#       \ls -L ./big_dir > list_of_files.txt
#    then
#       cat list_of_files | awk '{print $9}' | sed '/^$/d' > list_of_files.txt
#    or
#       \ls -L -1 ./big_dir > list_of_files.txt
#    or
#       find ./big_dir -type f > list_of_files.txt
#
# Generating the list of patterns:
#
#    For example, if you want to locate a file matching the pattern 'file_name_[0-9]\{6\},' save
#    that pattern in a file, replacing all \ with \\.
#
# Operation:
#
#    Call the command with the pattern file as the first argument and the file to be searched as
#    the second argument. If pattern matches a line in the search file, the resulting output
#    file, list_of_patterns_found.txt, will have content such as
#    'big_dir/new_file_name_123456.bin'
#
# Next steps:
#
#    Use rsync to copy the list of files:
#
#       rsync -av --files-from=list_of_patterns_found.txt . user@remote.url:/dir
#
# Adapted from find_matching.sh
#
# Apr 2023 JCL

# set tab
TAB+=${TAB+${fTAB:='   '}}

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
    TAB+=${fTAB:='   '}
    echo -n "${TAB}input file ${file_in}... "
    if [ -f ${file_in} ]; then
	echo "exits"
	# read input file
	j=$(cat ${file_in} | wc -l)
	TAB+=${fTAB:='   '}
	echo "${TAB}and has $j entries"

	# set print frequency
	if [ $j -lt 10 ]; then
	    nprint=1
	else
	    nprint=$((j/10+1))
	fi
	echo "${TAB}printing one results for every $nprint lines"

	# parse input
	dir1=$(dirname $file_in)
	echo "${TAB}input dir = $dir1"
	fname1=$(basename $file_in)
	echo "${TAB}input file = $fname1"
	base1="${fname1%.*}"
	echo "${TAB}base name = $base1"
	TAB+=${fTAB}
	if [[ $fname1 == *"."* ]]; then
	    echo "${TAB}fname contains dots"
	    ext="${fname1##*.}"
	else
	    echo "${TAB}fname does not contains dots, using default"
	    ext="txt"
	fi
	TAB=${TAB%$fTAB}

	# set default output file name to match input
	base="${base1}_found"
	file_spec="${dir1}/${base}.${ext}"

	TAB=${TAB%$fTAB}
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
	if [ -f ${file_out} ]; then
            echo "exists"
	    while [ -f ${file_out} ]; do
		echo "${file_out##*/} exists"
		echo -n "${TAB}renaming output... "
		file_out=${dir1}/${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
		echo ${file_out##*/}
	    done
	    echo "${TAB}unique file name found"
	else
	    echo "uniquely named"
	fi

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

	# process input file
    	while read line; do
            fname=$line
            ((k++))
	    # print status
	    printf "\x1b[2K\r%4d/$j %3d%%" $k $((((k*100))/j))
	    if [ $(( k % $nprint)) -eq 0 ]; then
		echo -ne " looking for ${fname}... "
	    fi
	    # save matches to file
	    grep "${fname}" $2 >> ${file_out}
	    RETVAL=$?
	    # print result
	    if [ $(( k % $nprint)) -eq 0 ]; then
		if [[ $RETVAL != 0 ]]; then
		    echo "done"
		else
		    echo "not found"
		fi
	    fi
	done < $file_in
	echo
	# print summary
	echo $k "file names checked"
	echo "$((j-k)) files not searched for"
	l=$(cat ${file_out} | wc -l)
	echo "$l files found"
	if [ $j -lt $l ]; then
	    printf "%0.2f files found for each pattern" $(bc <<< "scale=2; $l / $j")
	else
	    echo "$((j-l)) files not found"
	fi
    else
	echo "does not exit"
	exit 1
    fi
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
