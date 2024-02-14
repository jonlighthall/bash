#!/bin/bash -u

# define colors
declare -r yellow='\E[0;33m' # yellow
declare -r   GOOD='\E[0;32m' # green
declare -r NORMAL='\E[0m'    # reset
declare -r  space='\E[30;106m' # highlight white space

# set lcoal tab
declare -r thisTAB='   '

# check tabs
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
