#!/bin/bash -u
# -----------------------------------------------------------------------------------------------
#
# cp_date.sh
#
# Purpose : Copy input file renamed to include modification date.
#
# Adapted from mv_date.sh
#
# Mar 2024 JCL
#
# -----------------------------------------------------------------------------------------------

function get_mod_date() {
    itab
    # set trap and print function name
    if [ $DEBUG -gt 0 ]; then
        trap 'print_return $?;dtab' RETURN
        echo -e "${TAB}${INVERT}function: ${FUNCNAME}${RESET}"
    fi
    if [ $# -lt 2 ]; then
	      echo "${TAB}Please provide an input file"
	      return 1
    fi

    # print arguments
    ddecho "${TAB}number of arguments = $#"
    itab
    local -r in_file="$(readlink -f "$1")"
    ddecho "${TAB}argument 1: $1"

    local -n output=$2
    ddecho "${TAB}argument 2: $2"
    dtab
    
	  # parse input
    echo -n "${TAB}input path: ${in_file##*/}... "
    # check if input exists
    if [ -L "${in_file}" ] || [ -f "${in_file}" ] || [ -d "${in_file}" ]; then
	      echo -e "${GOOD}exists${RESET}"
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
        # redefine "extension" if a hidden file
        if [ -z "${in_base}" ] && [[ "${in_fname::1}" == "." ]]; then
            in_base="${ext}"
            ext=''
        fi
        
        # print summary
        (
            ddecho "input dir: $in_dir"
	          ddecho "input file: $in_fname"
	          ddecho "base name: $in_base"
	          ddecho -n "ext name: ${ext}"
	          if [ ${#ext} -eq 0 ]; then
		            ddecho -e "${GRAY}EMPTY${RESET}"
	          else
		            ddecho
	          fi
        ) | column -t -s: -o ":" -R1 | sed "s/^/${TAB}/"
        
	      # set default output file name to match input
	      out_base="${in_base}"
	      output="${in_dir}/${out_base}${ext}"

	      # check if input and output are the same file
	      decho -e "${TAB}output file ${output} is..."
        itab
	      while [ "${in_file}" -ef "${output}" ]; do
		        decho -e "${TAB}${YELLOW}the same file${RESET} as input file ${in_file}"
		        echo -n "${TAB}renaming output... "
		        # NB: don't rename any existing files; change the ouput file name to something unique
		        output=${in_dir}/${out_base}_$(date -r "${output}" +'%Y-%m-%d-t%H%M%S')${ext}
		        echo ${output##*/}
	      done
	      ddecho "${TAB}named differently than input"
        dtab

	      # check if output exists
	      echo -n "${TAB}output file: ${output##*/}... "
        itab
	      if [ -f "${output}" ]; then
		        decho -e "${BAD}exists${RESET}"
		        ddecho -n "${TAB}waiting for new time stamp... "
            # append the cuurent timestamp to the file name and wait to find a file that doesn't
            # exist
		        while [ -f "${output}" ]; do
			          # NB: don't rename any existing files; change the ouput file name to something
			          # unique
			          output=${in_dir}/${out_base}_$(date +'%Y-%m-%d-t%H%M%S')${ext}
		        done
		        ddecho "done"
		        ddecho "${TAB}unique file name found"
		        echo "${TAB}output file ${output##*/}"
	      else
		        echo -e "${GOOD}does not exist${RESET} (uniquely named)"
	      fi
        dtab
    else
	      echo "is not valid"
        itab
	      test_file "$1" | sed "s/^/${TAB}/"
        # extract date from broken link
	      if [ -L "$1" ]; then
		        link_name=$1
		        decho "${TAB}${link_name} is a broken link!"
		        mdate=$(stat -c '%y' "${link_name}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/' | sed 's/://g')
		        output=${link_name}_${mdate}
	      else		
            dtab 
		        echo -e "${TAB}${BAD}exiting...${RESET}"
            dtab 
		        exit 1
	      fi
        dtab
    fi
}

# set debug level
declare -i DEBUG=${DEBUG:-0}

# load bash utilities
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
ddecho "${TAB}number of arguments = $#"
itab
ddecho "${TAB}argument 1: $1"

# if argument is a broken link, an error is produced
set +e
# set file names
in_file=$(readlink -f $1)
RETVAL=$?
decho -n "${TAB}link "
if [ $RETVAL -eq 0 ]; then
    decho -e "${GOOD}OK${RESET}"
else
    decho -e "${BAD}FAILED${RESET}"
    in_file=$(readlink -mv $1)
    decho "${TAB} ${in_file}"
    in_file=$1
fi
dtab
echo "${TAB}getting modifcation date..."
declare out_file
get_mod_date "${in_file}" out_file

# now move file
echo "${TAB}copying file..."
itab
echo -n "${TAB}"
cp -npv "${in_file}" "${out_file}"
dtab 2
trap 'print_exit' EXIT
