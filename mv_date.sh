#!/bin/bash -eu
# -----------------------------------------------------------------------------------------------
#
# mv_date.sh
#
# Purpose: Rename input file to include modification date.
#
# Adapted from grep_matching.sh
#
# Apr 2023 JCL
#
# -----------------------------------------------------------------------------------------------

function get_mod_date() {
    trap 'print_return $?' RETURN
    echo -e "${INVERT}function: ${FUNCNAME}${RESET}"
    if [ $# -lt 2 ]; then
	      echo "Please provide an input file"
	      return 1
    fi
    echo "number of arguments = $#"

    local -r in_file="$(readlink -f "$1")"
    echo "argument 1: $1"

    local -n output=$2
    echo "argument 2: $2"
    
    TAB+=${fTAB:='   '}
    echo -n "${TAB}input path: ${in_file}... "
    if [ -L "${in_file}" ] || [ -f "${in_file}" ] || [ -d "${in_file}" ]; then
	      echo "exits"

	      # parse input
        # directory name
        in_dir="$(dirname "${in_file}")"
        # base name
	      in_fname="$(basename "${in_file}")"
        # file name
	      in_base="${in_fname%.*}"
        # extension
        if [[ $in_fname == *"."* ]]; then
		        ext=".${in_fname##*.}"
	      else
		        ext=""
	      fi
        # redefine if hidden file
        if [ -z "${in_base}" ] && [[ "${in_fname::1}" == "." ]]; then
            in_base="${ext}"
            ext=''
        fi

        (
            echo "input dir: $in_dir"
	          echo "input file: $in_fname"
	          echo "base name: $in_base"
	          echo -n "ext name: ${ext}"
	          if [ ${#ext} -eq 0 ]; then
		            echo "EMPTY"
	          else
		            echo
	          fi
        ) | column -t -s: -o ":" -R1 | sed "s/^/${TAB}/"
        
	      # set default output file name to match input
	      out_base="${in_base}"
	      output="${in_dir}/${out_base}${ext}"

	      # check if input and output are the same file
	      echo -e "output file ${output} is ..."
	      while [ "${in_file}" -ef "${output}" ]; do
		        echo "${TAB}the same file as input file ${in_file}"
		        echo -n "${TAB}renaming output... "
		        # NB: don't rename any existing files; change the ouput file name to something unique
		        output=${in_dir}/${out_base}_$(date -r "${output}" +'%Y-%m-%d-t%H%M%S')${ext}
		        echo ${output}
	      done
	      echo "${TAB}uniquely named"

	      # check if output exists
	      echo "output file ${output}... "
	      if [ -f "${output}" ]; then
		        echo "${TAB}exists"
		        echo -n "${TAB}waiting for new time stamp... "
		        while [ -f "${output}" ]; do
			          # NB: don't rename any existing files; change the ouput file name to something
			          # unique
			          output=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
		        done
		        echo "done"
		        echo "${TAB}unique file name found"
		        output=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
		        echo "output file ${output}"
	      else
		        echo "${TAB}does not exist (uniquely named)"
	      fi
    else
	      echo "is not valid"
	      test_file $1 | sed "s/^/${TAB}/"
	      if [ -L "$1" ]; then
		        in_file=$1
		        echo "${in_file} is a broken link!"
		        mdate=$(stat -c '%y' "${in_file}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/' | sed 's/://g')
		        output=$1_${mdate}
	      else		
		        echo "${TAB}exiting..."
		        exit 1
	      fi
    fi
}

# set debug level
declare -i DEBUG=0

# load formatting and functions
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi
print_source

# check for input
if [ $# -eq 0 ]; then
	  echo "Please provide an input file"
	  exit 1
fi
echo "number of arguments = $#"

# set file names
in_file=$(readlink -f $1)
echo "argument 1: $1"

declare out_file

get_mod_date "${in_file}" out_file

# now move file
mv -nv "${in_file}" "${out_file}"
