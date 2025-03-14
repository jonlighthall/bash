#!/bin/bash -u

# used to fix bad file extensions for OneDrive

# Nov 2021 JCL

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
    echo "${TAB}replacing \"${sep_in}\" with \"${sep_out}\"..."
    itab
    for fname in ${name_list[@]}; do
        ((++count_found))
        echo -n "${TAB}"
        mv -nv "$fname" "$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
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
