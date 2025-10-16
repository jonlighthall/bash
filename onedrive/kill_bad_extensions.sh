#!/bin/bash -u

# used to delete or rename files with bad extensions for OneDrive
# checks git status before taking action

# Oct 2025 JCL

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source $flib
fi

check_arg "$@"
echo "${TAB}looking for bad extensions..."

for bad in ${bad_ext[@]}; do
    decho -n "${TAB}$bad: "

    sep_in=".${bad}"
    sep_out="${sep}${bad}"

    decho -n "${sep_in}: "

    # find bad files
    name_list=$(find ./ -name "*${sep_in}")

    # if list is empty, continue
    if [ -z "${name_list}" ]; then
        decho "none"
        continue
    fi

    # print current extension
    start_new_line
    echo "${TAB}processing files with extension \"${sep_in}\"..."
    itab
    for fname in ${name_list[@]}; do
        ((++count_found))
        echo -n "${TAB}"

        # Check if we're in a git repository
        if git rev-parse --git-dir > /dev/null 2>&1; then
            # Check if file is tracked by git
            if git ls-files --error-unmatch "$fname" > /dev/null 2>&1; then
                # File is tracked
                # Check if file is modified
                if git diff --quiet "$fname" && git diff --cached --quiet "$fname"; then
                    # File is tracked and unmodified
                    echo "tracked, unmodified: $fname"

                    # Update index to ignore changes (assume unchanged)
                    if git update-index --assume-unchanged "$fname" > /dev/null 2>&1; then
                        echo "${TAB}${TAB}marked to ignore changes"
                        ((++count_index))
                    else
                        echo -e "${TAB}${TAB}${BAD}failed to update index${RESET}"
                    fi

                    # Delete the file
                    if rm "$fname"; then
                        echo -e "${TAB}${TAB}${GOOD}deleted${RESET}"
                        ((++count_rm))
                    else
                        echo -e "${TAB}${TAB}${BAD}failed to delete${RESET}"
                    fi
                else
                    # File is tracked but modified - rename instead
                    echo "tracked, modified: $fname - renaming instead"
                    new_name="$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
                    mv -nv "$fname" "$new_name"
                    if [ -f "$fname" ]; then
                        echo -e "${TAB}${TAB}rename ${BAD}FAILED${RESET}"
                        ((++count_mv_fail))
                    else
                        ((++count_mv))
                    fi
                fi
            else
                # File is not tracked - rename it
                echo "not tracked: $fname - renaming"
                new_name="$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
                mv -nv "$fname" "$new_name"
                if [ -f "$fname" ]; then
                    echo -e "${TAB}${TAB}rename ${BAD}FAILED${RESET}"
                    ((++count_mv_fail))
                else
                    ((++count_mv))
                fi
            fi
        else
            # Not in a git repository - just rename
            echo "not in git repo: $fname - renaming"
            new_name="$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
            mv -nv "$fname" "$new_name"
            if [ -f "$fname" ]; then
                echo -e "${TAB}${TAB}rename ${BAD}FAILED${RESET}"
                ((++count_mv_fail))
            else
                ((++count_mv))
            fi
        fi
    done
    dtab
done

print_stat
