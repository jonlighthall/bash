#!/bin/bash -u

# used to un-fix bad file extensions for OneDrive

# Nov 2021 JCL

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source $flib
fi

check_arg "$@"
for bad in ${bad_list[@]}; do
    decho -n "${TAB}$bad: "

    sep_in="${sep}${bad}"
    sep_out=".${bad}"

    decho -n "${sep_in}: "
    
    # find bad files
    name_list=$(find ./ -name "*${sep_in}")
    
    # if list is empty, continue
    if [ -z "${name_list}" ]; then
        decho "skip"
        continue
    fi
    
    # print current extension
    start_new_line
    echo "${TAB}replacing \"${sep_in}\" with \"${sep_out}\"..."
    itab
        for fname in ${name_list[@]}; do
        ((++count_found))
        echo -n "${TAB}${fTAB}"
        git mv -fv "$fname" "$(echo $fname | sed "s/${sep_in}/${sep_out}/")"
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
