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

# First, check for already deleted files in git with bad extensions
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "${TAB}checking for deleted files in git index..."

    # Get list of deleted files
    deleted_files=$(git ls-files --deleted)

    if [ -n "$deleted_files" ]; then
        declare -i found_deleted=0
        itab
        while IFS= read -r fname; do
            if [ -n "$fname" ]; then
                # Check if file has a bad extension
                for bad in ${bad_ext[@]}; do
                    if [[ "$fname" == *.${bad} ]]; then
                        ((++found_deleted))
                        echo -n "${TAB}$fname (deleted)... "

                        # Check if already marked as assume-unchanged
                        file_status=$(git ls-files -v "$fname" 2>/dev/null | cut -c1)
                        if [[ "$file_status" =~ ^[a-z]$ ]]; then
                            echo "already ignored"
                            ((++count_skip))
                        else
                            # Mark as assume-unchanged to hide the deletion
                            if git update-index --assume-unchanged "$fname" > /dev/null 2>&1; then
                                echo -e "${GOOD}ignored${RESET}"
                                ((++count_index))
                            else
                                echo -e "${BAD}failed to update index${RESET}"
                            fi
                        fi
                        break
                    fi
                done
            fi
        done <<< "$deleted_files"
        dtab

        if [ $found_deleted -eq 0 ]; then
            echo "${TAB}no deleted files with bad extensions found"
        fi
    else
        echo "${TAB}no deleted files found"
    fi
    echo
else
    echo "${TAB}not in a git repository"
    echo
fi

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

                    # Check if file is already marked as assume-unchanged
                    file_status=$(git ls-files -v "$fname" 2>/dev/null | cut -c1)
                    if [[ "$file_status" =~ ^[a-z]$ ]]; then
                        echo "${TAB}${TAB}already marked to ignore changes"
                        ((++count_skip))
                    else
                        # Update index to ignore changes (assume unchanged)
                        if git update-index --assume-unchanged "$fname" > /dev/null 2>&1; then
                            echo "${TAB}${TAB}marked to ignore changes"
                            ((++count_index))
                        else
                            echo -e "${TAB}${TAB}${BAD}failed to update index${RESET}"
                        fi
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
