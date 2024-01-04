#!/bin/bash -u
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
	in_file=$(readlink -f $1)
	echo "argument 1: $1"
	TAB+=${fTAB:='   '}
	echo -n "${TAB} input path: ${in_file}... "
	if [ -f "${in_file}" ]; then
		echo "exits"

		# parse input
		in_dir=$(dirname "${in_file}")
		echo "${TAB}  input dir: $in_dir"
		in_fname=$(basename "${in_file}")
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
		out_file="${in_dir}/${out_base}${ext}"

		# check if input and output are the same file
		echo -e "output file ${out_file} is ..."
		while [ "${in_file}" -ef "${out_file}" ]; do
			echo "${TAB}the same file as input file ${in_file}"
			echo -n "${TAB}renaming output... "
			# NB: don't rename any existing files; change the ouput file name to something unique
			out_file=${in_dir}/${out_base}_$(date -r "${out_file}" +'%Y-%m-%d-t%H%M%S')${ext}
			echo ${out_file}
		done
		echo "${TAB}uniquely named"

		# check if output exists
		echo "output file ${out_file}... "
		if [ -f "${out_file}" ]; then
			echo "${TAB}exists"
			echo -n "${TAB}waiting for new time stamp... "
			while [ -f "${out_file}" ]; do
				# NB: don't rename any existing files; change the ouput file name to something
				# unique
				out_file=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
			done
			echo "done"
			echo "${TAB}unique file name found"
			out_file=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
			echo "output file ${out_file}"
		else
			echo "${TAB}does not exist (uniquely named)"
		fi
	else
		echo "is not a file"
		echo "${TAB}exiting..."
		exit 1
	fi
fi

# now move file
mv -nv "${in_file}" "${out_file}"
