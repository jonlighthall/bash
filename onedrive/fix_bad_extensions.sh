#!/bin/bash -u

# used to fix bad file extensions for OneDrive

# Nov 2021 JCL

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	  set_traps
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${RESET}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${RESET} -> $src_name"
fi

# define replacement seperator
sep=_._

if [ $# -eq 0 ]; then
    echo "${TAB}Please provide a target directory"
    exit 1
else
    echo -n "${TAB}target directory $1 "
    if [[ -d $1 ]]; then
        echo "found"
        itab
        declare -i count_found=0
        declare -i count_mv=0
        declare -i count_mv_fail=0
        for bad in bat bin cmd csh exe gz js ksh osx out prf ps ps1; do
            echo "${TAB}replacing \".$bad\" with \"${sep}${bad}\"..."
            for fname in $(find $1 -name "*.${bad}"); do
                ((++count_found))
                echo -n "${TAB}${fTAB}"
                mv -nv "$fname" "$(echo $fname | sed "s/\.$bad/$sep$bad/")" 
                if [ -f "$fname" ];then
                    echo "rename $fname FAILED"
                    ((++count_mv_fail))
                else
                    ((++count_mv))
                fi
            done
        done
        dtab
    else
        echo "not found"
        exit 1
    fi
fi

echo "Files found: $count_found"
echo "Files renamed: $count_mv"
echo "Files not renamed: $count_mv_fail"
