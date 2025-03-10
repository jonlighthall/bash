#!/bin/bash -u

# used to un-fix bad file extensions for OneDrive

# Nov 2021 JCL

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
echo -n "${TAB}looking for bad extensions..."

decho $(start_new_line)
declare -i RETVAL
declare cmd
unset_traps

for bad in ${bad_ext[@]}; do

    decho -n "${TAB}$bad: "

    sep_in="${sep}${bad}"
    sep_out=".${bad}"

    decho -n "${sep_in}: "

    # find bad files
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
        #       git ls-files --error-unmatch ${fname}
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
done
echo "done"
print_stat
reset_traps
