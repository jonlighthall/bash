#!/bin/bash -u
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

function check_arg1() {
    #   set +T
    #    trap 'print_return;trap -- RETRUN' RETURN
    if [ $# -eq 0 ]; then
	      echo "Please provide an input file"
	      exit 1
    fi
    echo "${TAB}number of arguments = $#"
    itab
    echo "${TAB}argument 1: $1"
}

function print_arg() {
    # print arguments
    local -i n_arg=$#
    echo "${TAB}number of arguments = $n_arg"

    echo $@
    local -i i=0
    for iarg in "$@"; do
        ((++i))
        echo "$i $iarg"
    done
}

function parse_arg() {
    print_arg $@

    # if argument is a broken link, an error is produced
    set +e
    # set file names
    arg=$1
    echo $arg

    test_file "$arg" | sed "s/^/${TAB}/"

    # determine type
    if [ -L "${arg}" ]; then
        [ -e "${arg}" ] && type="link ${VALID}" || type="broken link ${BROKEN}"
    fi
    [ -f "${arg}" ] && type="file ${FILE}"
    [ -d "${arg}" ] && type="directory ${DIR}"

    # check if argument is a link
    if [ -L "${arg}" ]; then
        echo "${arg} is a link"
        if [ $DEBUG -gt 0 ]; then
            itab
            echo -n "${TAB}readlink    : "
            readlink $arg
            echo -n "${TAB}readlink -e : "
            readlink -e $arg
            [ $? -eq 1 ] && echo
            echo -n "${TAB}readlink -f : "
            readlink -f $arg
            echo -n "${TAB}readlink -mv: "
            readlink -mv $arg
        fi
        readlink -e $arg
        RETVAL=$?
        echo -n "${TAB}readlink "
        if [ $RETVAL -eq 0 ]; then
            echo -e "${GOOD}OK${RESET}"
        else
            echo -e "${BAD}FAILED${RESET}"
        fi
        # if the file is a link, use the link name as the input file; otherwise the link target
        # will be used
        in_file=$arg

        echo "${TAB}in file: ${in_file}"
        dtab

		    if [ ! -e "${arg}" ]; then
            echo -en "${YELLOW}$arg${RESET} "
            echo -n "is a "
				    echo -e -n "${BROKEN}broken${RESET}"
			      echo -e " ${UL}link${RESET}"
            ls -l --color ${arg} | sed 's,^.*\(\./\),\1,'

            # check if the broken link is a duplicate of a valid link
            og_fname=$(echo ${arg} | sed 's/_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-t[0-9]\{6\}//')
            echo -n "${TAB}original target ${og_fname}... "
            itab
            if [ -e "${og_fname}" ]; then
                echo "exists"
                echo "${og_fname} points to $(echo readlink -f ${og_fname})"
                echo -e "${TAB}${YELLOW}${type}${RESET}${YELLOW}${arg} should be removed${RESET}"
            else
                echo "not found"
            fi
            dtab
        else
            echo "the link is valid"
		    fi
    else
        echo "$ arg is not a link"
        in_file=$(readlink -f $arg)
        RETVAL=$?
        echo -n "${TAB}readlink "
        if [ $RETVAL -eq 0 ]; then
            echo -e "${GOOD}OK${RESET}"
        else
            echo -e "${BAD}FAILED${RESET}"
        fi

        if [ -f "${arg}" ]; then
            echo "$arg is a file"
        fi

        if [ -d "${arg}" ]; then
            echo "$arg is a dir"
        fi

        if [ -e "${arg}" ]; then
            echo "$arg does not exist"
        fi
    fi
    echo "in_file = ${in_file}"
}

function get_mod_date() {
    trap 'print_return; trap -- RETURN' RETURN
    # set debug level
    declare -i DEBUG=${DEBUG:-0}

    itab
    # set trap and print function name
    if [ $DEBUG -gt -1 ]; then
        trap 'print_return $?;dtab' RETURN
        echo -e "${TAB}${INVERT}function: ${FUNCNAME}${RESET}"
    fi
    if [ $# -lt 2 ]; then
	      echo "${TAB}Please provide an input file and an output variable"
	      return 1
    fi

}

function get_unique_name() {
    trap 'print_return; trap -- RETURN' RETURN
    # set debug level
    declare -i DEBUG=${DEBUG:-0}

    itab
    # set trap and print function name
    if [ $DEBUG -gt -1 ]; then
        trap 'print_return $?;dtab' RETURN
        echo -e "${TAB}${INVERT}function: ${FUNCNAME}${RESET}"
    fi
    if [ $# -lt 2 ]; then
	      echo "${TAB}Please provide an input file and an output variable"
	      return 1
    fi

    print_arg $@
    itab
    parse_arg $1

    echo "in_file = ${in_file}"

    local -n output=$2
    echo "${TAB}argument 2: $2"
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
            echo "input dir: $in_dir"
	          echo "input file: $in_fname"
	          echo "base name: $in_base"
	          echo -n "ext name: ${ext}"
	          if [ ${#ext} -eq 0 ]; then
		            echo -e "${GRAY}EMPTY${RESET}"
	          else
		            echo
	          fi
        ) | column -t -s: -o ":" -R1 | sed "s/^/${TAB}/"

	      # set default output file name to match input
	      out_base="${in_base}"
	      output="${in_dir}/${out_base}${ext}"

        # extract date from broken link
	      if [ -L "$in_file" ]; then
            echo -ne "${TAB}output ${type}${output##*/}${RESET}... "
		        link_name=$in_file
            if [ ! -e "${in_file}" ]; then
                echo -e "${BAD}name exists${RESET}"
                itab
		            echo "${TAB}${link_name} is a broken link!"
                echo "${TAB}getting modification date with stat()"
                if [ $DEBUG -gt 0 ]; then
                    stat -c '%y' "${link_name}"
                    stat -c '%y' "${link_name}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/'
                    stat -c '%y' "${link_name}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/' | sed 's/://g'
                fi
		            mdate=$(stat -c '%y' "${link_name}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/' | sed 's/://g')
                itab
                echo "${TAB}modification date of broken link $mdate"
                dtab 2
		            output=${link_name}_${mdate}
            else
                echo "exits"
                itab
                echo "${TAB}${link_name} is a valid link"
                echo "${TAB}getting modification date with date()..."
            fi
	      else
            dtab 2
	      fi

	      # check if input and output are the same file
        [ -L "${output}" ] & [ -e "${output}" ] &&  echo -ne "${TAB}output ${type}${output##*/}${RESET}... "
        if [ -L "${output}" ] || [ -f "${output}" ] || [ -d "${output}" ]; then
            if [ -e "${output}" ]; then
                echo -e "${BAD}exists${RESET}"
                itab
		            echo -e "${TAB}is ${YELLOW}the same file${RESET} as input file ${in_file##*/}"
		            echo "${TAB}getting file modification date... "
                local mod_date=$(date -r "${output}" +'%Y-%m-%d-t%H%M%S')
                itab
                echo "${TAB}modification date is ${mod_date}"
                dtab
                echo "${TAB}renaming output..."

		            output=${in_dir}/${out_base}_${mod_date}${ext}
                itab
		            echo "${TAB}${output##*/}"
	              echo "${TAB}named differently than input"
                dtab 2
            fi

        else
            echo -e "${GOOD}OK${RESET}"
        fi

	      # check if output exists
        echo -en "${TAB}output ${type}${output##*/}${RESET}... "
        itab
		    # NB: don't rename any existing files; change the ouput file name to something unique
        if [ -L "${output}" ] || [ -f "${output}" ] || [ -d "${output}" ]; then
            [ ! -e "${output}" ] && echo -en "${BAD}name "
		        echo -e "${BAD}exists${RESET}"
            # append the curent timestamp to the file name and wait to find a file that doesn't
            # exist
		        echo -n "${TAB}waiting for new time stamp... "
		        while [ -L "${output}" ] || [ -f "${output}" ] || [ -d "${output}" ]; do
                local ts_date=$(date +'%Y-%m-%d-t%H%M%S')
			          output=${in_dir}/${out_base}_${ts_date}${ext}
		        done
		        echo "done"
            # print summary
            itab
            echo "${TAB}timestamp is ${ts_date}"
            dtab
		        echo "${TAB}unique file name found"
            dtab
		        echo -e "${TAB}output ${type}${output##*/}${RESET} is unique"
	      else
		        echo -e "${GOOD}does not exist${RESET} (uniquely named)"
	      fi
        dtab
    else
	      echo "is not valid"
		    echo -e "${TAB}${BAD}exiting...${RESET}"
        dtab
		    exit 1
    fi
}
