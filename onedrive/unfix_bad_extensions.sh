#!/bin/bash -u

# used to un-fix bad file extensions for OneDrive

# Nov 2021 JCL

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	  set_traps
    print_source
fi

# load onedrive utilities
flib=${HOME}/utils/bash/onedrive/lib_onedrive.sh
if [ -e $flib ]; then
    source $flib
fi

check_arg "$@"
for bad in ${bad_list[@]}; do
    # find bad files
    name_list=$(find ./ -name "*.${bad}")
    
    # if list is empty, continue
    if [ -z "${name_list}" ]; then
        continue
    fi
    
    # print current extension
    start_new_line
    echo "${TAB}replacing \".$bad\" with \"${sep}${bad}\"..."
    itab
        for fname in ${name_list[@]}; do
        ((++count_found))
        echo -n "${TAB}${fTAB}"
        mv -nv "$fname" "$(echo $fname | sed "s/$sep$bad/.$bad/")"
        if [ -f "$fname" ];then
            echo -e  "rename $fname ${BAD}FAILED${RESET}"
            ((++count_mv_fail))
        else
            ((++count_mv))
        fi
    done
done

print_stat
