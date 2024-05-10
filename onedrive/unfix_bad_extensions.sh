#!/bin/bash -u

# used to un-fix bad file extensions for OneDrive

# Nov 2021 JCL

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	  set_traps
    itab
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
        for bad in bat bin cmd csh exe gz osx out prf ps; do
            echo "${TAB}replacing \"${sep}${bad}\" with \".$bad\"..."
            for fname in $(find $1 -name "*$sep$bad"); do
                mv -nv "$fname" "$(echo $fname | sed "s/$sep$bad/.$bad/")" | sed "s/^/${TAB}${fTAB}/"
            done
        done
        dtab
    else
        echo "not found"
        exit 1
    fi
fi

dtab
