#!/bin/bash
#
# Purpose: this script will compare the comntents of of the given input argument against
# .bash_history, append the non-common lines to .bash_history and delte the resulting redundant
# file.
#
# JCL Mar 2023

# shell settings
#set -e # exit on non-zero status
#set -x
#shopt -s expand_aliases
#alias diffy='diff --color=auto --suppress-common-lines -yiEZbwB'
#alias comm1='comm -2 -3 --nocheck-order'


# define highligt colors
GOOD='\033[0;32m' # green
BAD='\033[0;31m' # red
NORMAL='\033[0m'    # reset
UL='\033[4m'    # underline

# check for input
if [ $# -eq 0 ]
then
    echo "Please provide a (list of) files to compare"
    exit 1
else
    # check for reference file
    hist=${HOME}/.bash_history
    echo -n "${hist}... "
    if [ -f $hist ]; then
	echo -e "is a regular ${UL}file${NORMAL}"
    else
	echo -e "${BAD}${UL}does not exist${NORMAL}"
	exit 1
    fi
    # check arguments
    for arg in "$@"
    do
	echo -n "${arg}... "
	if [ -f $arg ]; then
	    echo -e "is a regular ${UL}file${NORMAL}"
	    echo "proceeding..."
	    diff --color=auto --suppress-common-lines -yiEZbwB ${arg} ${hist}

	    echo -e "\n-----\n"
	    diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history
	    echo -e "\n-----\n"
	    diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep "^[^\s]*<"
	    echo -e "\n-----\n"
	    diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep "^[^\s]*<" | sed 's/\s*<$//'
	    echo -e "\n-----\n"
	    diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep -v "^[^\s]*>"
	    echo -e "\n-----\n"
	    diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep -v "^[^\s]*>" | sed 's/\s*<$//; s/\s*|.*$//'

	    N=$(diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep -v "^[^\s]*>" | sed 's/\s*<$//; s/\s*|.*$//' | wc -l)

	    #	    N=(diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep -v "^[^\s]*>" | sed 's/\s*>.*$//' | wc -l)
	    echo "$N lines from ${arg}"

	    if [[ $N > 0 ]]; then
		echo "yes"
		echo "#$(date +'%s') INDIFF $(date +'%a %b %d %Y %R:%S %Z')" >> ${hist}
		diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep -v "^[^\s]*>" | sed 's/\s*<$//; s/\s*|.*$//' >> ${hist}
	    else
		echo "no"
	    fi

	    #

	    #	    diff --color=auto --suppress-common-lines -yiEZbwB ./.bash_history_old ./.bash_history | grep "^[^\s]*<" | sed 's/\s*<$//' >> ${hist}

	    echo -e "\n-----\n"
	    set -x
	    comm -2 -3 --nocheck-order ${arg} ${hist}
	    set +x
	    N=$(comm -2 -3 --nocheck-order ${arg} ${hist} | wc -l)
	    echo "  initial uncommon lines = ${N}"
	    #	    echo "#$(date +'%s') INCOMM $(date +'%a %b %d %Y %R:%S %Z')" >> ${hist}
	    N=$(comm -2 -3 --nocheck-order ${arg} ${hist} | wc -l)
	    echo "remaining uncommon lines = ${N}"
	    exit





	    echo "${arg} contains $(comm -2 -3 --nocheck-order ${arg} ${hist}|wc -l) lines not present in ${hist}"
	    read -p "Press q to quit, any other key to continue " -n 1 -s -r
	    echo
	    if [[ $REPLY =~ [qQ] ]]; then
		echo "exiting..."
		exit 1
	    else
		echo "continuing..."
	    fi
	    set -x
	    comm -2 -3 --nocheck-order ${arg} ${hist} &>> ${hist}
	    comm -2 -3 --nocheck-order ${arg} ${hist}
	    N=$(comm -2 -3 --nocheck-order ${arg} ${hist} | wc -l)
	    echo "remaining uncommon lines = ${N}"
	    if [[ $N == 0 ]]; then
		echo "yes"
		rm -v ${arg}
	    else
		echo "no"
	    fi
	else
	    echo -e "${BAD}${UL}does not exist${NORMAL}"
	fi
    done
fi
