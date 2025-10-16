#!/bin/bash -u

# used to undo kill_bad_extensions - restore files with bad extensions
# un-ignores git-tracked files and renames files back to original extensions

# Oct 2025 JCL

declare -i start_time=$(date +%s%N)

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source $flib
fi

# load Git library
glib=${HOME}/utils/bash/git/lib_git.sh
if [ -e $glib ]; then
    source $glib
fi

check_arg "$@"

# First, un-ignore any files that were marked with --assume-unchanged
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "${TAB}checking for ignored files in git index..."

    # Get list of files marked as assume-unchanged
    ignored_files=$(git ls-files -v | grep '^[a-z]' | cut -c3-)

    if [ -n "$ignored_files" ]; then
        echo "${TAB}found files marked to ignore changes:"
        itab
        while IFS= read -r fname; do
            if [ -n "$fname" ]; then
                echo -n "${TAB}$fname... "
                if git update-index --no-assume-unchanged "$fname" 2>/dev/null; then
                    echo -e "${GOOD}un-ignored${RESET}"
                    ((++count_index))
                else
                    echo -e "${BAD}failed${RESET}"
                fi
            fi
        done <<< "$ignored_files"
        dtab
    else
        echo "${TAB}no ignored files found"
    fi
    echo
else
    echo "${TAB}not in a git repository, skipping git index check"
    echo
fi

echo -n "${TAB}looking for renamed extensions..."
decho $(start_new_line)

declare -i RETVAL
declare cmd
unset_traps

for bad in ${bad_ext[@]}; do

    decho -n "${TAB}$bad: "

    sep_in="${sep}${bad}"
    sep_out=".${bad}"

    decho -n "${sep_in}: "

    # find renamed files
    name_list=$(find ./ -name "*${sep_in}")

    # if list is empty, continue
    if [ -z "${name_list}" ]; then
        decho -n "none"
        echo -n "."
        decho
        continue
    fi

    # print current extension
    start_new_line
    echo "${TAB}replacing \"${sep_in}\" with \"${sep_out}\"..."
    itab
    for fname in ${name_list[@]}; do
        ((++count_found))
        echo -n "${TAB}"

        # Check if file is tracked by git
        if git rev-parse --git-dir > /dev/null 2>&1; then
            git ls-files --error-unmatch "${fname}" &>/dev/null
            RETVAL=$?
            if [ $RETVAL == 0 ]; then
                cmd="git mv"
            else
                cmd="mv"
            fi
        else
            cmd="mv"
        fi

        "${cmd}" -fv "$fname" "$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
        if [ -f "$fname" ]; then
            echo -e "rename $fname ${BAD}FAILED${RESET}"
            ((++count_mv_fail))
        else
            ((++count_mv))
        fi
    done
    dtab
done

echo "done"
print_stat
reset_traps
