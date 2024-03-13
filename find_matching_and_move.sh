#!/bin/bash -u
#
# find_matching_and_move.sh - Reads an input list of files name patterns. Any
# files matching the individual patterns are saved to a new list of file names.
# Handling is included to backup any duplicated input/output file names.
#
# Adapted from find_missing_and_empty.sh
#
# The first argument is the FILE containing a list of files to be moved.
#
# The second argument is the DIRECTORY specifying the named sub-directory to
# move the matching files
#
# Use example:
#
# find_matching output.txt subdir
#
# the command will take the located files specified by the list and move them to
# the sub-directory subdir. For example below, the search pattern (first line)
# matches the file name (second line) found by running the first command. The
# file is then moved to the new sub-directory with the second command.
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
			nprint=$((j / 10 + 1))
		fi
		echo "${TAB}printing one results for every $nprint lines"

		# parse arguments
		if [ $# -eq 1 ]; then
			echo "Please provide a target subdirectory"
			exit 1
		else
			echo "target subdirectory: $2"
		fi

		# process input file
		while read line; do
			fname=$line
			((k++))
			# print status
			printf "\E[2K\r%4d/$j %3d%%" $k $((((k * 100)) / j))
			if [ $((k % $nprint)) -eq 0 ]; then
				echo -ne " looking for ${fname}... "
			fi
			# define subdir
			dir_par=$(dirname "${fname}")
			dir_mv=${dir_par}/$2
			if ! [ -d ${dir_mv} ]; then
				echo "${dir_mv} not found"
				mkdir -pv ${dir_mv}
			fi
			# move matches
			if [ -f ${fname} ]; then
				mv ${fname} ${dir_mv} | sed "s/^/${TAB}/"
			fi
			# print result
			if [ $((k % $nprint)) -eq 0 ]; then
				if [ -f ${fname} ]; then
					echo "done"
				else
					echo "not found"
				fi
			fi
		done <$file_in
		echo
		# print summary
		echo $k "file names checked"
		echo "$((j - k)) files not searched for"
	else
		echo "does not exit"
		exit 1
	fi
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
