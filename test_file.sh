#!/bin/sh

GOOD='\033[0;32m'
BAD='\033[0;31m'
NORMAL='\033[0m'
BOLD='\033[4m'

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
    for arg in "$@"
    do
	echo
	echo -n "$arg "
	if [ -L $arg ] ; then
	    echo -e "is a ${BOLD}link${NORMAL}"
	    echo -n " The link is... "
	    if [ -e $arg ] ; then
		echo -e "${GOOD}valid${NORMAL}"
	    else
		echo -e "${BAD}broken${NORMAL}"
	    fi
	elif [ -e $arg ] ; then
	    echo "exists"
	    echo -n " It is... "
	    if [ -f $arg ]; then
		echo -e "a regular ${BOLD}file${NORMAL}"
	    else
		echo -n "not a regular file, but... "
		if [ -d $arg ]; then
		    echo -e "a ${BOLD}directory${NORMAL}"
		else
		    echo "not a directory"
		fi
	    fi	
	else
	    echo "${BOLD}does not exist${NORMAL}"
	fi
    done
fi
echo
echo " " $(date) "at time $SECONDS"
