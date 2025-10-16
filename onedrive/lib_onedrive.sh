#!/bin/bash
# -----------------------------------------------------------------------------
# ONEDRIVE LIBRARY
# -----------------------------------------------------------------------------
#
# ~/utils/bash/onedrive/lib_onedrive.sh
#
# PURPOSE: functions for handling sync issues in OneDrive.
#
# CONTAINS:
#   check_arg()
#   fix_bad_base()
#   fix_bad_ext()
#   fix_bin()
#   print_git_status()
#   print_stat()
#   reset_counters()
#
# Jun 2024 JCL
#
# -----------------------------------------------------------------------------

# define replacement seperator
sep=_._

declare -i count_found=0
declare -i count_rm=0
declare -i count_mv=0
declare -i count_mv_fail=0
declare -i count_skip=0
declare -i count_index=0

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
    export count_index=0
}

reset_counters

declare -a bad_ext
bad_ext=( "bat" "bin" "cmd" "crt" "csh" "exe" "gz" "js" "ksh" "mar" "osx" "out" "prf" "ps" "ps1" )
declare -a bad_base
bad_base=( "con" )

function print_git_status() {
    # PURPOSE - print standardized git status for a file
    #
    # USAGE: print_git_status "filename"
    #
    # OUTPUT: prints status like "tracked, modified, ignored" or "untracked"
    #
    # RETURNS:
    #   0 - tracked, unmodified, not ignored (safe to delete)
    #   1 - tracked, modified (should rename)
    #   2 - tracked, ignored (already handled)
    #   3 - untracked (should rename)
    #   4 - not in git repo (should rename)
    #   5 - deleted (file doesn't exist but is tracked)

    local fname="$1"
    local status_msg=""
    local retval=0

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -en "${YELLOW}not in git repo${RESET}"
        return 4
    fi

    # Check if file is tracked
    if git ls-files --error-unmatch "$fname" > /dev/null 2>&1; then
        # File is tracked
        status_msg="${CYAN}tracked${RESET}"

        # Check if file exists
        if [ ! -e "$fname" ]; then
            echo -en "${status_msg}, ${RED}deleted${RESET}"
            return 5
        fi

        # Check if file is modified
        if git diff --quiet "$fname" && git diff --cached --quiet "$fname"; then
            status_msg="${status_msg}, ${GREEN}unmodified${RESET}"
            retval=0
        else
            status_msg="${status_msg}, ${YELLOW}modified${RESET}"
            retval=1
        fi

        # Check if file is ignored (assume-unchanged)
        local file_status=$(git ls-files -v "$fname" 2>/dev/null | cut -c1)
        if [[ "$file_status" =~ ^[a-z]$ ]]; then
            status_msg="${status_msg}, ${MAGENTA}ignored${RESET}"
            retval=2
        else
            status_msg="${status_msg}, ${GREEN}not ignored${RESET}"
        fi
    else
        # File is not tracked
        status_msg="${MAGENTA}untracked${RESET}"
        retval=3
    fi

    echo -en "$status_msg"
    return $retval
}

function check_arg() {
    local arg
    local in_dir

    # check argument
    if [ $# -eq 0 ]; then
	      echo "No target directory specified"
        echo "Using ."
        arg="."
    else
        arg=$1
    fi

    # find input directory
    if [[ "${arg}" == "." ]]; then
        in_dir=$(readlink -f "$PWD/${arg}")
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
    echo "Files updated: $count_index"
    echo "Files not renamed: $count_mv_fail"
    echo
}

function fix_bad_ext() {
    # PURPOSE - remove or rename files names that are no allowed by OneDrive
    #
    # DEPENDENCIES (local)
    #   bad_ext
    #   count_found
    #   count_mv
    #   count_mv_fail
    #   count_rm

    #   itab
    #   start_new_line
    #   dtab
    #   decho
    #
    # METHOD -
    #   FIND files with bad extensions
    #   check if tracked
    #    + check if unmodified
    #        + delete
    #        - rename
    #    - check if ignored
    #        + delete
    #        - rename
    #
    # CALLED BY
    #   rm_tracked_bad_ext
    #
    # --------------------------------------------------------------------------

    # look for bad extensions
    echo -n "${TAB}checking for files with bad extensions... "
    itab
    for bad in ${bad_ext[@]}; do
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
                    # ...ignore changes
                    git update-index --assume-unchanged "${fname}"
                    ((++count_index))
                    # ...then remove
                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo -en "${CYAN}modified: ${RESET}"
                    # ...then rename (move)
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

                # check if the file is listed in .gitignore
                git check-ignore "${fname}" &>/dev/null
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    echo -n "ignored: "
                    # ...then remove
                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo -n "not ignored: "
                    # ...then rename (move)
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

function fix_bad_base() {
    # look for bad extensions
    echo -n "${TAB}checking for files with bad base names... "
    itab
    for bad in ${bad_base[@]}; do
        # print current baseension
        start_new_line
        echo -n "${TAB}${bad}... "

        # find bad files
        name_list=$(find -L ./ -name "${bad}.*")

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
                    # ...ignore changes
                    git update-index --assume-unchanged "${fname}"
                    ((++count_index))
                    # ...then remove
                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo -en "${CYAN}modified: ${RESET}"
                    # ...then rename (move)
                    mv -nv "$fname" "$sep$fname"
                    if [ -f "$fname" ];then
                        echo "rename $fname FAILED"
                        ((++count_mv_fail))
                    else
                        ((++count_mv))
                    fi
                fi
            else
                echo -en "${MAGENTA}untracked: ${RESET}"

                # check if the file is listed in .gitignore
                git check-ignore "${fname}" &>/dev/null
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    echo -n "ignored: "
                    # ...then remove
                    rm -v "$fname"
                    ((++count_rm))
                else
                    echo -n "not ignored: "
                    # ...then rename (move)
                    fname_out="$fname$sep"
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
