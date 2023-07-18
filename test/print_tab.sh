#!/bin/bash
set -e # exit on non-zero status
echo "running ${0##*/}"
#echo "in ${0%/*}"
echo "called by $(ps -o comm= $PPID)"

yellow='\033[33m'
GOOD='\033[0;32m' # green
NORMAL='\033[0m'    # reset
space='\x1B[30;106m'

# set tab
thisTAB='   '

TAB=${TAB:='apple'}
fTAB=${fTAB:='banana'}

for var in TAB fTAB profTAB comTAB
do
    echo "var = $var = " ${!var}
    val=${!var}
    i=${#val}
    #    echo "length = $i"
    echo -n "${thisTAB}$var "

    if [ -z ${!var+dummy} ]; then
	echo -e "${yellow}unset${NORMAL}"
    else
	echo -en "${GOOD}set${NORMAL} to ${space}${val}${NORMAL}"
	[ $i -gt 0 ] && echo -n " "
	echo "length = $i"
    fi


    continue



    if [ -z ${var+dummy} ]; then
	echo -e "${yellow}unset${NORMAL}"
    else
	echo -en "${GOOD}set${NORMAL} to ${space}${var}${NORMAL}"
	[ $i -gt 0 ] && echo -n " "
	echo "length = $i"
    fi
done

# print time at exit
echo -e "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
