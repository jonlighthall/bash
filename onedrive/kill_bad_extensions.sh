#!/bin/bash -u

# used to delete or rename files with bad extensions for OneDrive
# checks git status before taking action

# Oct 2025 JCL

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source "$flib"
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
                        echo -n "${TAB}${fname}: "

                        # Check if already ignored without calling print_git_status
                        file_status=$(git ls-files -v "$fname" 2>/dev/null | cut -c1)
                        if [[ "$file_status" =~ ^[a-z]$ ]]; then
                            # Already ignored
                            echo -e "${CYAN}tracked${RESET}, ${RED}deleted${RESET}, ${MAGENTA}ignored${RESET} → already ignored"
                            ((++count_skip))
                        else
                            # Mark as assume-unchanged to hide the deletion
                            echo -en "${CYAN}tracked${RESET}, ${RED}deleted${RESET}, ${GREEN}not ignored${RESET} → "
                            if git update-index --assume-unchanged "$fname" > /dev/null 2>&1; then
                                echo -e "${GOOD}marked to ignore${RESET}"
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
        echo -n "${TAB}$fname: "

        # Print git status and capture return value (disable error exit temporarily)
        print_git_status "$fname" && git_status=$? || git_status=$?
        echo -n " → "

        # Take action based on git status
        case $git_status in
            0)  # tracked, unmodified, not ignored - mark and delete
                if git update-index --assume-unchanged "$fname" > /dev/null 2>&1; then
                    echo -n "marked to ignore, "
                    ((++count_index))
                else
                    echo -en "${BAD}failed to mark${RESET}, "
                fi

                if rm "$fname"; then
                    echo -e "${GOOD}deleted${RESET}"
                    ((++count_rm))
                else
                    echo -e "${BAD}failed to delete${RESET}"
                fi
                ;;

            1)  # tracked, modified - rename instead
                echo -n "renaming... "
                new_name="$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
                mv -nv "$fname" "$new_name" 2>&1 | sed "s/^/${TAB}${TAB}/"
                if [ -f "$fname" ]; then
                    echo -e "${TAB}${TAB}${BAD}FAILED${RESET}"
                    ((++count_mv_fail))
                else
                    ((++count_mv))
                fi
                ;;

            2)  # tracked, ignored - just delete
                echo -n "already ignored, "
                if rm "$fname"; then
                    echo -e "${GOOD}deleted${RESET}"
                    ((++count_rm))
                    ((++count_skip))
                else
                    echo -e "${BAD}failed to delete${RESET}"
                fi
                ;;

            3|4)  # untracked or not in git repo - rename
                echo -n "renaming... "
                new_name="$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
                mv -nv "$fname" "$new_name" 2>&1 | sed "s/^/${TAB}${TAB}/"
                if [ -f "$fname" ]; then
                    echo -e "${TAB}${TAB}${BAD}FAILED${RESET}"
                    ((++count_mv_fail))
                else
                    ((++count_mv))
                fi
                ;;
        esac
    done
    dtab
done

print_stat
