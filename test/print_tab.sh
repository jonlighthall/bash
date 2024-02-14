#!/bin/bash -u
yellow='\E[0;33m'
  GOOD='\E[0;32m' # green
NORMAL='\E[0m'    # reset
 space='\E[30;106m'

# set tab
thisTAB='   '
for var in TAB fTAB
do
	echo -n "${thisTAB}$var "
    if [ -z ${!var+dummy} ]; then
	echo -e "${yellow}unset${NORMAL}"
    else
	val=${!var}
	i=${#val}
	echo -en "${GOOD}set${NORMAL} to ${space}${val}${NORMAL}"
	[ $i -gt 0 ] && echo -n " "
	echo "length = $i"
    fi
done
