#!/bin/bash

# define replacement seperator
sep=_._

declare -i count_found=0
declare -i count_rm=0
declare -i count_mv=0
declare -i count_mv_fail=0
declare -i count_skip=0

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	  set_traps
    print_source
fi

function reset_counters() {
    echo "${TAB}resetting counters..."
    export count_found=0
    export count_rm=0
    export count_mv=0
    export count_mv_fail=0
    export count_skip=0
}

reset_counters

declare -a bad_list
bad_list=( "bat" "bin" "cmd" "csh" "exe" "gz" "js" "ksh" "mar" "osx" "out" "prf" "ps" "ps1" )

function check_arg() {
    # check argument
    if [ $# -eq 0 ]; then
	      echo "Please provide a target directory"
	      exit 1
    fi

    # find input directory
    if [[ "$1" == "." ]]; then
        in_dir=$(readlink -f "$PWD/$1")
    else
        in_dir=$(readlink -f $1)
    fi
    echo -en "target directory ${PSDIR}${in_dir##*/}${RESET}... "
    if [ ! -d "${in_dir}" ]; then
		    echo "not found"
		    exit 1
    fi
    echo "found "
    cd "${in_dir}"
}

function print_stat() {
    echo
    echo -e "${UL}Files found: $count_found${NORMAL}"
    echo "Files deleted: $count_rm"
    echo "Files skipped: $count_skip"
    echo "Files renamed: $count_mv"
    echo "Files not renamed: $count_mv_fail"
    echo
}

function fix_bad_ext() {
    # look for bad extensions
    echo -n "${TAB}checking for files with bad extensions... "
    itab
    for bad in ${bad_list[@]}; do
        # print current extension
        start_new_line
        echo -n "${TAB}.${bad}... "

        # find bad files
        name_list=$(find -L ./ -name "*.${bad}")  

        # if list is empty, continue
        if [ -z "${name_list}" ]; then
            echo "none"
            continue
        fi
        itab

        # print number of matches
        local -i n_files=$(echo "$name_list" | wc -l)
        echo "$n_files files found"

        # loop over file names
        for fname in ${name_list[@]}; do
            ((++count_found))
            echo -n "${TAB}${count_found}) $fname... "

            # check if the file is tracked
            git ls-files --error-unmatch "$fname" &>/dev/null
            RETVAL=$?
            if [ $RETVAL -eq 0 ]; then
                echo -n "tracked: "

                # check if the file is modified
                if [ -z "$(git diff $fname)" ]; then
                    echo -n "unmodified: "
                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo -en "${CYAN}modified: ${RESET}"
                    mv -nv "$fname" "$(echo "$fname" | sed "s/\.$bad/$sep$bad/")"
                    if [ -f "$fname" ];then
                        echo "rename $fname FAILED"
                        ((++count_mv_fail))
                    else
                        ((++count_mv))
                    fi
                fi
            else
                echo -en "${MAGENTA}untracked: ${RESET}"

                git check-ignore "${fname}" &>/dev/null
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    echo -n "ignored: "

                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo -n "not ignored: "

                    fname_out=$(echo "$fname" | sed "s/\.$bad/$sep$bad/")
                    echo
                    itab
                    decho "${TAB}fname: $fname"
                    decho "${TAB}fname out: $fname_out"
                    decho "${TAB}mv -nv $fname ${fname_out}"
                    echo -n "${TAB}"
                    dtab
                    mv -nv "$fname" "${fname_out}"
                    if [ -f "$fname" ];then
                        echo "rename $fname FAILED"
                        ((++count_mv_fail))
                    else
                        ((++count_mv))
                    fi
                fi
            fi

        done
        dtab
    done
    dtab
    echo "done"

}

function fix_bin() {
    # first, remove tracked files from the repository
    echo -n "${TAB}removing tracked binary (and empty) files from the repository... "
    itab
    for fname in $(find -L ./ -not -path "*$GITDIR/*" -not -path "*/*git/*" -type f ); do

        # Check if the file is binary
        if perl -e 'exit -B $ARGV[0]' "$fname"; then
            :  #echo "File is text."; file $file
        else
            start_new_line
            echo -en "${TAB}${fname##*./}... "
            if [ ! -s $fname ]; then
                echo -en "${YELLOW}empty: ${RESET}"
                rm -v "$fname"
                ((++count_rm))
                continue
            else
                echo -ne "${BAD}binary: ${RESET}"
            fi

            # check if the file is tracked
            git ls-files --error-unmatch $fname &>/dev/null
            RETVAL=$?
            if [ $RETVAL -eq 0 ]; then
                echo -n "tracked: "
                # check if the file is modified
                if [ -z "$(git diff $fname)" ]; then
                    echo -n "unmodified: "
                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo -e "${CYAN}modified${RESET}"
                    ((++count_skip))
                fi
            else
                echo -en "${MAGENTA}untracked${RESET}"
                if [[ "$@" =~ -[m]*u[m]* ]]; then
                    echo -en "${MAGENTA} -u : ${RESET}"
                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo
                    ((++count_skip))
                fi
            fi
        fi
    done
    echo "done"
    dtab

}
