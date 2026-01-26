#!/bin/bash -u

# used to fix bad file extensions for OneDrive
# OneDrive restricts syncing files with certain extensions. This script renames
# files by appending an underscore to the end of the filename.
#
# Example: file.bat -> file.bat_
#
# Nov 2021 JCL
# Jan 2026 JCL - updated to use append-underscore method instead of _._

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source "$flib"
fi

check_arg "$@"
echo "${TAB}looking for bad extensions..."

for bad in ${bad_ext[@]}; do
    decho -n "${TAB}$bad: "

    # -------------------------------------------------------------------------
    # First, migrate any old-format files (_._ext -> .ext_)
    # -------------------------------------------------------------------------
    old_pattern="*${sep}${bad}"
    old_list=$(find ./ -name "${old_pattern}")

    if [ -n "${old_list}" ]; then
        start_new_line
        echo "${TAB}migrating old format \"${sep}${bad}\" to \".${bad}_\"..."
        itab
        for fname in ${old_list[@]}; do
            ((++count_found))
            echo -n "${TAB}"
            # convert: file_._bat -> file.bat_
            fname_out=$(echo "$fname" | sed "s/${sep}${bad}/.${bad}_/")
            mv -nv "$fname" "${fname_out}"
            if [ -f "$fname" ]; then
                echo -e "rename $fname ${BAD}FAILED${RESET}"
                ((++count_mv_fail))
            else
                ((++count_mv))
            fi
        done
        dtab
    fi

    # -------------------------------------------------------------------------
    # Then, fix any unfixed files (.ext -> .ext_)
    # -------------------------------------------------------------------------
    pattern="*.${bad}"

    decho -n "${pattern}: "

    # find bad files
    # exclude already-fixed files:
    #   - new format: ending with _ (e.g., file.bat_)
    name_list=$(find ./ -name "${pattern}" ! -name "*_")

    # if list is empty, continue
    if [ -z "${name_list}" ]; then
        decho "none"
        continue
    fi

    # print current extension
    start_new_line
    echo "${TAB}appending underscore to files ending with \".${bad}\"..."
    itab
    for fname in ${name_list[@]}; do
        ((++count_found))
        echo -n "${TAB}"
        # append underscore to end of filename
        mv -nv "$fname" "${fname}_"
        if [ -f "$fname" ];then
            echo -e  "rename $fname ${BAD}FAILED${RESET}"
            ((++count_mv_fail))
        else
            ((++count_mv))
        fi
    done
    dtab
done

print_stat
