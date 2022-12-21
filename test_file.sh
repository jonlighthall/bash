#!/bin/bash

GOOD='\033[1;36m'
BAD='\033[1;31m'
NORMAL='\033[0m'
BOLD='\033[4m'
DIR='\033[1;34m'

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
    for arg in "$@"
    do
	echo -n "$arg "
	if [ -L $arg ] ; then
	    echo -n "is a "
	    if [ -e $arg ] ; then
		echo -e -n "${GOOD}valid${NORMAL}"
	    else
		echo -e -n "${BAD}broken${NORMAL}"
	    fi
	    echo -e " ${BOLD}link${NORMAL}"
	elif [ -e $arg ] ; then
	    if [ -f $arg ]; then
		echo -e "is a regular ${BOLD}file${NORMAL}"
	    else
		if [ -d $arg ]; then
		    echo -e "is a ${DIR}${BOLD}directory${NORMAL}"
		else
		    echo -e "${BOLD} exits, but is not a link, file, or directory"
		fi
	    fi
	else
	    echo -e "${BAD}${BOLD}does not exist${NORMAL}"
	fi
    done
fi
