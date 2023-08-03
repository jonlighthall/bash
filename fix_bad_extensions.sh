#!/bin/bash

# used to fix bad file extensions for OneDrive

# Nov 2021 JCL

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi
TAB+=${fTAB:='   '}

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# define replacement seperator
sep=_._

if [ $# -eq 0 ]
then
    echo "${TAB}Please provide a target directory"
    exit 1
else
    echo -n "${TAB}target directory $1 "
    if [[ -d $1 ]]; then
	echo "found"
	TAB+=$fTAB
	for bad in bat bin cmd csh exe gz prf out osx
	do
	    echo "${TAB}replacing \".$bad\" with \"${sep}${bad}\"..."
	    for fname in $(find $1 -name "*.${bad}"); do
		mv -nv "$fname" "`echo $fname | sed "s/\.$bad/$sep$bad/"`";
	    done
	done
	TAB=${TAB#$fTAB}
    else
	echo "not found"
	exit 1
    fi
fi

TAB=${TAB#$fTAB}
# print time at exit
echo -en "${TAB}$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} "
if command -v sec2elap &>/dev/null; then
    sec2elap ${SECONDS}
else
    echo "elapsed time is ${SECONDS} sec"
fi
