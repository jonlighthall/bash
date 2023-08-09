#!/bin/bash
yellow='\033[0;33m'
  GOOD='\033[0;32m' # green
NORMAL='\033[0m'    # reset
 space='\x1B[30;106m'

# set tab
thisTAB='   '
for var in TAB fTAB
do
    val=${!var}
    echo -n "${thisTAB}$var "
    if [ -z ${!var+dummy} ]; then
	echo -e "${yellow}unset${NORMAL}"
    else
	i=${#val}
	echo -en "${GOOD}set${NORMAL} to ${space}${val}${NORMAL}"
	[ $i -gt 0 ] && echo -n " "
	echo "length = $i"
    fi
done
