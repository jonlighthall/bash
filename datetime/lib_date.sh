#!/bin/bash -u
# -----------------------------------------------------------------------------------------------
# DATETIME LIBRARY
# -----------------------------------------------------------------------------------------------
#
# ~/utils/bash/datetime/lib_date.sh
#
# Purpose: 
#
# Developed from mv_date.sh
#
# May 2024 JCL
#
# -----------------------------------------------------------------------------------------------

declare -i libDEBUG=1

function check_arg1() {
    #   set +T
    #    trap 'print_return;trap -- RETRUN' RETURN
    if [ $# -eq 0 ]; then
	      echo "Please provide an input file"
	      exit 1
    fi
}

function print_arg() {
    # set debug level
    local -i DEBUG=${DEBUG:-0}
    # manual
    DEBUG=${libDEBUG}
    # set trap and print function name
    if [ $DEBUG -gt 0 ]; then
        itab
        trap 'print_return $?;dtab' RETURN
        echo -e "${TAB}${INVERT}function: ${FUNCNAME}${RESET}"
    else
        return 0
    fi

    # print arguments
    local -i n_arg=$#
    echo "${TAB}number of arguments = $n_arg"

    echo "${TAB}$@"
    local -i i=0
    itab
    for iarg in "$@"; do
        ((++i))
        echo "${TAB}$i) $iarg"
    done
    dtab
    return 0
}

function get_file_type() {
    decho "in type"
    # set debug level
    local -i DEBUG=${DEBUG:-0}
    # manual
    DEBUG=${libDEBUG}
    itab
    # set trap and print function name
    if [ $DEBUG -gt 0 ]; then
        trap 'print_return $?;dtab' RETURN
        echo -e "${TAB}${INVERT}function: ${FUNCNAME}${RESET}"
    else
        trap 'dtab' RETURN
    fi

    print_arg "$@"

    # if argument is a broken link, an error is produced
    set +e
    # set file names
    arg="$1"
    arg_base=${arg##*/}

    decho "${TAB}input: $arg"
    decho "${TAB}base: $arg_base"
    
    [ $DEBUG -gt 0 ] && test_file "${arg_base}" | sed "s/^/${TAB}/"

    echo "determining type..."
    # determine type
    [ -f "${arg}" ] && type="file ${FILE}"
    [ -d "${arg}" ] && type="directory ${DIR}"
    if [ -L "${arg}" ]; then
        [ -e "${arg}" ] && type="link ${VALID}" || type="broken link ${BROKEN}"
    fi

    # check if argument is a link
    if [ -L "${arg}" ]; then
        decho "${TAB}${arg_base} is a link"
        itab
        if [ $DEBUG -gt 0 ]; then
            echo -n "${TAB}readlink    : "
            readlink $arg
            echo -n "${TAB}readlink -e : "
            readlink -e $arg
            [ $? -eq 1 ] && echo
            echo -n "${TAB}readlink -f : "
            readlink -f $arg
            echo -n "${TAB}readlink -mv: "
            readlink -mv $arg
            echo -ne "${TAB}"
            readlink -e $arg
        else
            readlink -e $arg >/dev/null
        fi
        RETVAL=$?
        [ $RETVAL -eq 0 ] & [ $DEBUG -gt 0 ] && echo -n "${TAB}"
        decho -n "readlink "
        if [ $RETVAL -eq 0 ]; then
            decho -e "${GOOD}OK${RESET}"
        else
            decho -e "${BAD}FAILED${RESET}"
        fi
        # if the file is a link, use the link name as the input file; otherwise the link target
        # will be used
        in_file=$arg

        dtab
        decho -e "${TAB}input ${type}${in_file}${RESET}"
        itab

		    if [ ! -e "${arg}" ]; then
            if [ $DEBUG -gt 0 ]; then
                echo -en "${TAB}"
                ls -l --color ${arg} | sed 's,^.*\(\./\),\1,'
            fi
            # check if the broken link is a duplicate of a valid link
            echo ${arg} | grep -q "_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-t[0-9]\{6\}"
            if [ $? -eq 0 ]; then
                og_fname=$(echo ${arg} | sed 's/_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-t[0-9]\{6\}//')
                echo -n "${TAB}original target ${og_fname}... "
                itab
                if [ -e "${og_fname}" ]; then
                    echo "exists"
                    echo "${TAB}${og_fname} points to $(echo $(readlink -f ${og_fname}) | sed 's,^.*/,,')"
                    echo -e "${TAB}${YELLOW}${type}${RESET}${YELLOW}${arg_base} should be removed${RESET}"
                else
                    echo "not found"
                fi
                dtab
            fi
        else
            decho "${TAB}the link is valid"
		    fi
        dtab
    else
        decho "${TAB}$arg_base is not a link"
        in_file="$(readlink -f "$arg")"
        RETVAL=$?
        decho -n "${TAB}readlink "
        if [ $RETVAL -eq 0 ]; then
            decho -e "${GOOD}OK${RESET}"
        else
            decho -e "${BAD}FAILED${RESET}"
        fi

        if [ -f "${arg}" ]; then
            decho "${TAB}$arg_base is a file"
        fi

        if [ -d "${arg}" ]; then
            decho "${TAB}$arg_base is a dir"
        fi

        if [ ! -e "${arg}" ]; then
            decho "${TAB}$arg_base does not exist"
        fi
    fi
}

function get_mod_date() {
    # set debug level
    local -i DEBUG=${DEBUG:-0}
    # manual
    DEBUG=${libDEBUG}
    itab
    # set trap and print function name
    if [ $DEBUG -gt 0 ]; then

        trap 'print_return $?;dtab' RETURN
        echo -e "${TAB}${INVERT}function: ${FUNCNAME}${RESET}"
    else
        trap 'dtab' RETURN
    fi
    if [ $# -lt 2 ]; then
	      echo "${TAB}Please provide an input file and an output variable"
	      return 1
    fi

    decho "${TAB}parsing arguments..."
    print_arg "$@"
    get_file_type "$@"
    decho "${TAB}done parsing arguments"

    echo "checking file..."   
	  # parse input
    echo -en "${TAB}input ${type}${in_file##*/}${RESET}... "
    # check if input exists
    if [ -L "${in_file}" ] || [ -f "${in_file}" ] || [ -d "${in_file}" ]; then
        if [ ! -e "${in_file}" ]; then
            if [ -L "$in_file" ]; then
                # extract date from broken link
                echo -e "${YELLOW}name exists${RESET}"
                itab
		            echo "${TAB}${in_file} is a broken link!"
                echo "${TAB}getting modification date with stat()..."
                itab
                if [ $DEBUG -gt 0 ]; then
                    echo -n "${TAB}"
                    stat -c '%y' "${in_file}"
                    echo -n "${TAB}"
                    stat -c '%y' "${in_file}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/'
                    echo -n "${TAB}"
                    stat -c '%y' "${in_file}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/' | sed 's/://g'
                fi
		            mod_date=$(stat -c '%y' "${in_file}" | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/' | sed 's/://g')
                dtab
                echo "${TAB}modification date of broken link $mod_date"
                dtab
            else
                echo "${BAD}does not exist${RESET}"
		            echo -e "${TAB}${BAD}exiting...${RESET}"
                dtab
		            exit 1
            fi
        else
            echo -e "${GOOD}exists${RESET}"
            itab
            if [ -L "$in_file" ]; then
                decho "${TAB}${in_file} is a valid link"
                decho "${TAB}getting modification date with date()..."
            else
                decho "${TAB}getting file modification date... "
            fi
            local mod_date=$(date -r "${in_file}" +'%Y-%m-%d-t%H%M%S')
            dtab
            echo "${TAB}modification date is ${mod_date}"
        fi
    else
	      echo "is not valid"
		    echo -e "${TAB}${BAD}exiting...${RESET}"
        dtab 2
		    exit 1
    fi

    local -n output_var=$2
    decho "${TAB}output variable: ${!output_var}"
    output_var=$mod_date
}

function parse_file_parts() {
    echo "${TAB}parsing file parts..."
    get_file_type "$@"
    itab
	  # parse input
    echo -en "${TAB}input ${type}${in_file##*/}${RESET}... "
    # check if input exists
    if [ -L "${in_file}" ] || [ -f "${in_file}" ] || [ -d "${in_file}" ]; then
        if [ ! -e "${in_file}" ]; then
            if [ -L "$in_file" ]; then
                echo -e "${YELLOW}name exists${RESET}"
            else
                echo "${BAD}does not exist${RESET}"
                return 1
            fi
        else
	          echo -e "${GOOD}exists${RESET}"
        fi
        # directory name
        in_dir="$(dirname "${in_file}")"
        # base name
	      in_fname="$(basename "${in_file}")"
        # file name
	      in_base="${in_fname%.*}"
        # check for existing timestamp
        pat='^.*[0-9]{4}-[0-9]{2}-[0-9]{2}-t[0-9]{6}'
        decho "${TAB}$pat"
        echo -n "${TAB}${in_base}... "
        if [[ ${in_base} =~ $pat ]]; then
            echo "includes date"
            itab
            in_date=${in_base: -18}
            echo "${TAB}date is ${in_date}"
            name_in=${in_base:0: -18}
            # remove leading underscore
            name_in=${name_in%_}
            echo "${TAB}base name is ${name_in##*/}"
            dtab
            in_base=${name_in}
        else
            echo "does not include date"
        fi
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
        ) | column -t -s: -o ":" | sed "s/^/${TAB}/"

        # set default output file name to match input
	      out_base="${in_base}"
        dtab
        decho "${TAB}done parsing arguments"
    else
        echo "is not valid"
        echo -e "${TAB}${BAD}exiting...${RESET}"
        return 1
    fi
}

function get_unique_name() {
    # set debug level
    declare -i DEBUG=${DEBUG:-0}
    # manual
    DEBUG=${libDEBUG}

    itab
    # set trap and print function name
    if [ $DEBUG -gt 0 ]; then
        trap 'print_return $?;dtab' RETURN
        echo -e "${TAB}${INVERT}function: ${FUNCNAME}${RESET}"
    else
        trap 'dtab' RETURN
    fi
    if [ $# -lt 2 ]; then
        echo "${TAB}Please provide an input file and an output variable"
        return 1
    fi
    dtab

    # check output variable
    echo "${TAB}checking $2..."
    itab
    declare do_gen=true
    if [ -z ${!2+dummy} ]; then
        echo -e "${TAB}$2 is $UNSET"
    else
        echo "${TAB}$2 is set"
        echo -n "${TAB}${!2}... "
        out_file=${!2}

        if [ -L "${out_file}" ] || [ -f "${out_file}" ] || [ -d "${out_file}" ]; then
            [ ! -e "${out_file}" ] && echo -en "${BAD}name "
            echo -e "${BAD}exists${RESET}"
        else
            echo -e "${GOOD}does not exist${RESET}"
            do_gen=false
            echo "${TAB}output file is unique"
            dtab
            decho "${TAB}done checking $2"
        fi
    fi
    dtab
    
    # generate unique file name
    if [ $do_gen = true ]; then
        decho "print..."
        print_arg "$@"; echo $?
        decho "parse..."
        if [ -z ${!2+dummy} ]; then
            parse_file_parts "$1"
        else
            parse_file_parts $out_file
        fi

        echo "${TAB}generating unique file name..."
        itab
        local get_date
        echo "${TAB}getting modifcation date..."
        get_mod_date "${in_file}" get_date
        decho "${TAB}done getting modification"

        echo "${TAB}getting unique file name..."
        out_file=${in_dir}/${out_base}_${get_date}${ext}
        itab

	      # check if output exists
        echo -en "${TAB}output ${type}${out_file##*/}${RESET}... "
        itab
		    # NB: don't rename any existing files; change the ouput file name to something unique
        if [ -L "${out_file}" ] || [ -f "${out_file}" ] || [ -d "${out_file}" ]; then
            [ ! -e "${out_file}" ] && echo -en "${BAD}name "
		        echo -e "${BAD}exists${RESET}"
            # append the curent timestamp to the file name and wait to find a file that doesn't
            # exist
		        decho -n "${TAB}waiting for new time stamp... "
		        while [ -L "${out_file}" ] || [ -f "${out_file}" ] || [ -d "${out_file}" ]; do
                local ts_date=$(date +'%Y-%m-%d-t%H%M%S')
			          out_file=${in_dir}/${out_base}_${ts_date}${ext}
		        done
		        decho "done"
            # print summary
            itab
            decho "${TAB}timestamp is ${ts_date}"
            dtab
		        decho "${TAB}unique file name found"
            dtab
	      else
		        echo -e "${GOOD}does not exist${RESET}"
            dtab
	      fi
        echo -e "${TAB}output ${type}${out_file##*/}${RESET} is unique"
        dtab
        decho "${TAB}done getting unique file name"
        dtab
        decho "${TAB}done generating unique file name"
    fi

    local -n output_var=$2
    decho "${TAB}output variable: ${!output_var}"
    output_var=$out_file
    decho "${TAB}output value   : ${output_var##*/}"
    return 0
}
