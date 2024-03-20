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
	# check if variable is set
    if [ -z ${!var+dummy} ]; then
		echo -e "${YELLOW}unset${RESET}"
		continue
	fi

	#print variable value
	val=${!var}
	echo -en "${GOOD}set${RESET} to ${space}${val}${RESET}"

	# print variable length
	i=${#val}
	[ $i -gt 0 ] && echo -n " "
	echo "length = $i"
done
