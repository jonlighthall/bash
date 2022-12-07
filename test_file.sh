#!/bin/sh

GOOD='\033[1;32m'
BAD='\033[1;31m'
NORMAL='\033[0m'
BOLD='\033[4m'

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
    for arg in "$@"
    do
	echo -n "$arg "
	if [ -L $arg ] ; then
	    echo -en "is a "
	    if [ -e $arg ] ; then
		echo -en "${GOOD}valid${NORMAL}"
	    else
		echo -en "${BAD}broken${NORMAL}"
	    fi
	    echo -e " ${BOLD}link${NORMAL}"
	elif [ -e $arg ] ; then
	    if [ -f $arg ]; then
		echo -e "is a regular ${BOLD}file${NORMAL}"
	    else
		if [ -d $arg ]; then
		    echo -e "is a ${BOLD}directory${NORMAL}"
		else
		    echo "${BOLD} exits, but is not a link, file, or directory"
		fi
	    fi	
	else
	    echo "${BOLD}does not exist${NORMAL}"
	fi
    done
fi