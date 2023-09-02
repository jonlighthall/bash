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
    echo -n "${TAB} input path: ${file_in}... "
    if [ -f ${file_in} ]; then
	echo "exits"

	# parse input
	in_dir=$(dirname $file_in)
	echo "${TAB}  input dir: $in_dir"
	in_fname=$(basename $file_in)
	echo "${TAB} input file: $in_fname"
	in_base="${in_fname%.*}"
	echo "${TAB}  base name: $in_base"
	if [[ $in_fname == *"."* ]]; then
	    ext=".${in_fname##*.}"
	else
	    ext=""
	fi
	echo -n "${TAB}   ext name: ${ext}"
	if [ ${#ext} -eq 0 ]; then
	    echo "EMPTY"
	else
	    echo
	fi

	# set default output file name to match input
	out_base="${in_base}"
	file_out="${in_dir}/${out_base}${ext}"

	echo "${TAB}output file: $file_out"

	# check if input and output are the same file
	echo -n " input file ${file_in} is... "
	while [ ${file_in} -ef ${file_out} ]; do
            echo -e "\n${TAB}the same file as output file ${file_out}"
            echo -n "${TAB}renaming output... "
	    # NB: don't rename any existing files; change the ouput file name to something unique
	    file_out=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
	    echo ${file_out}
	done
	echo "${TAB}uniquely named"

	# check if output exists
	echo "output file ${file_out}... "
	if [ -f ${file_out} ]; then
            echo "${TAB}exists"
	    while [ -f ${file_out} ]; do
		echo "${file_out##*/} exists"
		echo -n "${TAB}renaming output... "
		# NB: don't rename any existing files; change the ouput file name to something
		# unique
		file_out=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
		echo ${file_out##*/}
	    done
	    echo "${TAB}unique file name found"
	else
	    echo "${TAB}does not exist (uniquely named)"
	fi
    else
	echo "does not exist"
	echo "${TAB}exiting..."
	exit 1
    fi
fi
