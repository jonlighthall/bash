#!/bin/bash -u
#
# cp_tar.sh - Reads an input list of files name patterns. Any files matching the
# individual patterns are copied to the ouput directory. File names are expected
# to be formatted using semantic versioning of the form
# name<major><minor><patch>. In this example, periods are not expected in the
# file name between version sections.
#
# Adapted from find_matching.sh
#
# Apr 2023 JCL

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# define tab
TAB="   "

# parse arguments
# set input file
if [ $# -eq 0 ]; then
	  echo "Please provide an input file"
	  exit 1
else
	  file_in=$1
fi
# set output directory
if [ $# -ge 2 ]; then
	  dir_mv=$2
else
	  dir_mv=./
fi

# check if output exists
echo -n "output directory ${dir_mv}... "
if [ -d ${dir_mv} ]; then
	  echo "exists"
else
	  mkdir -pv ${dir_mv}
	  echo "OK"
fi

declare -i n_checked
declare -i n_found
declare -i n_not_found
n_checked=0
n_found=0
n_not_found=0
declare -i n_same
declare -i n_unique
n_unique=0

declare file_list=local_list.txt
declare file_copy=source.txt
declare -i RETVAL

declare out_file

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi
print_source

# load date library
fname="${HOME}/utils/bash/datetime/lib_date.sh"
if [ -e "${fname}" ]; then
    if [[ "$-" == *i* ]] && [ ${DEBUG:-0} -gt 0 ]; then
        echo "${TAB}loading $(basename "${fname}")"
    fi
    source "${fname}"
else
    echo "${fname} not found"
    exit 1
fi

export DEBUG=0
export NO_FMT=true

function remote2unique() {
    declare cp_fname
    print_ cp_fname

    local file_remote="$@"

    echo "copying..."
    parse_file_parts "${file_remote}"
    echo "file name is ${in_fname}"
    out_fname="${dir_mv}/${in_fname}"
    echo "file name is ${out_fname}"
    test_file "${out_fname}"

    if [ -e "${out_fname}" ]; then
        echo "need to re-name"
        get_unique_name "${out_fname}" cp_fname
    else
        echo "no need to re-name"
        cp_fname="${out_fname}"
    fi

    echo "local file name = ${cp_fname}"

    #    set -x

    echo -ne "${GRH}"
    cp -pvi "${file_remote}" "${cp_fname}"
    [ $? -eq 1 ] && exit
    #  echo "RETVAL = $?"
    #   set +x
    echo -ne "${RESET}"
    ((n_unique++))

}

# read input file
while read line; do
	  file_remote=$line
	  ((n_checked++))
	  echo -n "$n_checked looking for ${file_remote}... "
	  if [ -f "${file_remote}" ]; then
		    echo "found"
        ((n_found++))

        n_same=0
        \ls ${dir_mv}/*.doc* > $file_list
        if [ $? -eq 0 ]; then
            echo "local files found:"
            cat $file_list
        else
            echo "no local files"

            remote2unique "${file_remote}"

            continue

            get_unique_name "${file_remote}" out_file
            #[ $? -eq 1 ] && exit
            cp -pv "${file_remote}" "${dir_mv}/${out_file##*/}"
            ((n_unique++))
            continue
        fi

        while read lline; do
            file_local=${lline}
            \diff "${file_local}" "${file_remote}"
            RETVAL=$?
            echo $RETVAL
            echo -n "$file_local... "
            if [ ${RETVAL} -eq 0 ]; then
                echo "duplicate found: don't copy"
                ((n_same++))
                break
            else
                echo "not a duplicate"
            fi
        done <$file_list
        echo "done checking local files"
        if [ ${n_same} -lt 1 ]; then
            echo "new file found: copy"
            remote2unique "${file_remote}"
            continue
        else
            echo "duplicates found: do not copy"
        fi
		else
		    echo "not found"
        ((n_not_found++))
	  fi
done <$file_in
echo

echo "$n_checked files checked"
echo "$n_found files found"
echo "$n_not_found files not found"
echo "$n_unique unique files found"

ls -lah "${dir_mv}"

# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
