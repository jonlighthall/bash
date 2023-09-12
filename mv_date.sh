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
    if [ -f "${file_in}" ]; then
	echo "exits"

	# parse input
	in_dir=$(dirname "${file_in}")
	echo "${TAB}  input dir: $in_dir"
	in_fname=$(basename "${file_in}")
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

	# check if input and output are the same file
        echo -e "output file ${file_out} is ..."
	while [ "${file_in}" -ef "${file_out}" ]; do
	    echo "${TAB}the same file as input file ${file_in}"
            echo -n "${TAB}renaming output... "
	    # NB: don't rename any existing files; change the ouput file name to something unique
	    file_out=${in_dir}/${out_base}_$(date -r "${file_out}" +'%Y-%m-%d-t%H%M%S')${ext}
	    echo ${file_out}
	done
	echo "${TAB}uniquely named"

	# check if output exists
	echo "output file ${file_out}... "
	if [ -f "${file_out}" ]; then
            echo "${TAB}exists"
	    echo -n "${TAB}waiting for new time stamp... "
	    while [ -f "${file_out}" ]; do
		# NB: don't rename any existing files; change the ouput file name to something
		# unique
		file_out=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
	    done
	    echo "done"
	    echo "${TAB}unique file name found"
	    file_out=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
	    echo "output file ${file_out}"
	else
	    echo "${TAB}does not exist (uniquely named)"
	fi
    else
	echo "does not exist"
	echo "${TAB}exiting..."
	exit 1
    fi
fi

# now move file
mv -nv "${file_in}" "${file_out}"
