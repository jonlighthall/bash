#!/bin/bash
#
# mv_date.sh - Rename input file to include modification date.
#
# Adapted from grep_matching.sh
#
# Apr 2023 JCL

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

	# parse input
	in_dir=$(dirname $file_in)
	echo "${TAB}input dir = $in_dir"
	in_fname=$(basename $file_in)
	echo "${TAB}input file = $in_fname"
	in_base="${in_fname%.*}"
	echo "${TAB}base name = $in_base"
	TAB+=${fTAB}
	if [[ $in_fname == *"."* ]]; then
	    echo "${TAB}fname contains dots"
	    ext=".${in_fname##*.}"
	else
	    echo "${TAB}fname does not contains dots, no extension will be used"
	    ext=""
	fi
	TAB=${TAB%$fTAB}

	# set default output file name to match input
	out_base="${in_base}"
	file_out="${in_dir}/${out_base}${ext}"

	TAB=${TAB%$fTAB}
	echo "file specification = $file_out"

	# check if input and output are the same file
	echo -n " input file ${file_in} is... "
	while [ ${file_in} -ef ${file_out} ]; do
            echo "the same file as ${file_out}"
            echo -n "${TAB}renaming output... "
	    file_out=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
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
		file_out=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
		echo ${file_out##*/}
	    done
	    echo "${TAB}unique file name found"
	else
	    echo "uniquely named"
	fi
    else
	echo "does not exit"
	exit 1
    fi
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
