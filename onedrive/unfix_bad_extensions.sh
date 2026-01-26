#!/bin/bash -u

# used to un-fix bad file extensions for OneDrive
# This script reverts renamed files back to their original extensions.
#
# Handles both naming conventions:
#   - Old format: file_._bat -> file.bat (using _._ separator)
#   - New format: file.bat_  -> file.bat (appended underscore)
#
# Nov 2021 JCL
# Jan 2026 JCL - added support for append-underscore format

declare -i start_time=$(date +%s%N)

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source "$flib"
fi

# load Git library
glib=${HOME}/utils/bash/git/lib_git.sh
if [ -e $glib ]; then
    source "$glib"
fi

check_arg "$@"
echo -n "${TAB}looking for bad extensions..."

decho $(start_new_line)
declare -i RETVAL
declare cmd
unset_traps

for bad in ${bad_ext[@]}; do

    decho -n "${TAB}$bad: "

    # -------------------------------------------------------------------------
    # Handle OLD format: file_._bat -> file.bat
    # -------------------------------------------------------------------------
    sep_in="${sep}${bad}"
    sep_out=".${bad}"

    decho -n "${sep_in}: "

    # find files with old naming convention
    name_list=$(find ./ -name "*${sep_in}")

    # process old format files if found
    if [ -n "${name_list}" ]; then
        # print current extension
        start_new_line
        echo "${TAB}replacing \"${sep_in}\" with \"${sep_out}\" (old format)..."
        itab
        for fname in ${name_list[@]}; do
            ((++count_found))
            echo -n "${TAB}"
            git ls-files --error-unmatch ${fname} &>/dev/null
            RETVAL=$?
            if [ $RETVAL == 0 ]; then
                cmd="git mv"
            else
                cmd="mv"
            fi

            "${cmd}" -fv "$fname" "$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
            if [ -f "$fname" ];then
                echo -e  "rename $fname ${BAD}FAILED${RESET}"
                ((++count_mv_fail))
            else
                ((++count_mv))
            fi
        done
        dtab
    else
        decho -n "none"
        echo -n "."
        decho
    fi

    # -------------------------------------------------------------------------
    # Handle NEW format: file.bat_ -> file.bat
    # -------------------------------------------------------------------------
    new_pattern=".${bad}_"

    decho -n "${new_pattern}: "

    # find files with new naming convention (appended underscore)
    name_list=$(find ./ -name "*${new_pattern}")

    # process new format files if found
    if [ -n "${name_list}" ]; then
        # print current extension
        start_new_line
        echo "${TAB}removing trailing underscore from \"*${new_pattern}\" (new format)..."
        itab
        for fname in ${name_list[@]}; do
            ((++count_found))
            echo -n "${TAB}"
            git ls-files --error-unmatch ${fname} &>/dev/null
            RETVAL=$?
            if [ $RETVAL == 0 ]; then
                cmd="git mv"
            else
                cmd="mv"
            fi

            # remove trailing underscore
            fname_out="${fname%_}"
            "${cmd}" -fv "$fname" "$fname_out"
            if [ -f "$fname" ];then
                echo -e  "rename $fname ${BAD}FAILED${RESET}"
                ((++count_mv_fail))
            else
                ((++count_mv))
            fi
        done
        dtab
    else
        decho -n "none"
        echo -n "."
        decho
    fi

done
echo "done"
print_stat
reset_traps
