#!/bin/bash -u

# used to fix bad file extensions for OneDrive
# OneDrive restricts syncing files with certain extensions. This script renames
# files by reversing the extension (zip -> piz).
# For palindrome extensions (e.g., exe), it falls back to appending underscore.
#
# Example: file.bat -> file.tab
#
# Nov 2021 JCL
# Jan 2026 JCL - updated to use append-underscore method instead of _._
# May 2026 JCL - updated to use flipped extension method as default

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source "$flib"
fi

check_arg "$@"
echo "${TAB}looking for bad extensions..."

for bad in ${bad_ext[@]}; do
    repl_ext=$(get_safe_ext_replacement "$bad")
    decho -n "${TAB}$bad: "

    # -------------------------------------------------------------------------
    # First, migrate any old-format files (_._ext -> .<replacement>)
    # -------------------------------------------------------------------------
    old_pattern="*${sep}${bad}"
    old_list=$(find ./ -name "${old_pattern}")

    if [ -n "${old_list}" ]; then
        start_new_line
        echo "${TAB}migrating old format \"${sep}${bad}\" to \".${repl_ext}\"..."
        itab
        for fname in ${old_list[@]}; do
            ((++count_found))
            echo -n "${TAB}"
            # convert: file_._bat -> file.tab
            fname_out=$(echo "$fname" | sed "s/${sep}${bad}/.${repl_ext}/")
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
    # Second, migrate append-underscore files (.ext_ -> .<replacement>)
    # -------------------------------------------------------------------------
    if [[ "${repl_ext}" != "${bad}_" ]]; then
        underscore_pattern="*.${bad}_"
        underscore_list=$(find ./ -name "${underscore_pattern}")

        if [ -n "${underscore_list}" ]; then
            start_new_line
            echo "${TAB}migrating underscore format \".${bad}_\" to \".${repl_ext}\"..."
            itab
            for fname in ${underscore_list[@]}; do
                ((++count_found))
                echo -n "${TAB}"
                fname_out="${fname%_}"
                fname_out=$(build_ext_filename "$fname_out" "$bad" "$repl_ext")
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
    fi

    # -------------------------------------------------------------------------
    # Then, fix any unfixed files (.ext -> .<replacement>)
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
    echo "${TAB}converting files ending with \".${bad}\" to \".${repl_ext}\"..."
    itab
    for fname in ${name_list[@]}; do
        ((++count_found))
        echo -n "${TAB}"
        # replace extension with OneDrive-safe extension
        fname_out=$(build_ext_filename "$fname" "$bad" "$repl_ext")
        mv -nv "$fname" "${fname_out}"
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
