#!/bin/bash
# define highligt colors
  GOOD='\033[0;32m' # green
   BAD='\033[0;31m' # red
NORMAL='\033[0m'    # reset
    UL='\033[4m'    # underline

 VALID='\033[1;36m' # bold cyan: valid link
BROKEN='\033[1;31m' # bold red : broken link
   DIR='\033[1;34m' # bold blue: directory

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
		echo -e -n "${VALID}valid${NORMAL}"
	    else
		echo -e -n "${BROKEN}broken${NORMAL}"
	    fi
	    echo -e " ${UL}link${NORMAL}"
	elif [ -e $arg ] ; then
	    echo -n "exists and "
	    if [ -f $arg ]; then
		echo -e "is a regular ${UL}file${NORMAL}"
	    else
		if [ -d $arg ]; then
		    echo -e "is a ${DIR}${UL}directory${NORMAL}"
		else
		    echo -e "${UL} is not a link, file, or directory"
		fi
	    fi
	else
	    echo -e "${BAD}${UL}does not exist${NORMAL}"
	fi
    done
fi
