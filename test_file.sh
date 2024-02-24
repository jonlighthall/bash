#!/bin/bash -u
# set tab
TAB+=${fTAB:='   '}
# no echo source since this is a utility
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
	source $fpretty
	set_traps
fi
#
# check for input
if [ $# -eq 0 ]; then
	echo "Please provide an input file"
else
	# check arguments
	for arg in "$@"; do
		echo -n "$arg "
		if [ -L $arg ]; then
			echo -n "is a "
			if [ -e $arg ]; then
				echo -e -n "${VALID}valid${NORMAL}"
			else
				echo -e -n "${BROKEN}broken${NORMAL}"
			fi
			echo -e " ${UL}link${NORMAL}"
		elif [ -e $arg ]; then
			echo -n "exists and "
			if [ -f $arg ]; then
				echo -e "is a regular ${UL}file${NORMAL}"
			else
				if [ -d $arg ]; then
					echo -e "is a ${DIR}${UL}directory${NORMAL}"
					exit 1
				else
					echo -e "${UL} is not a link, file, or directory"
				fi
			fi
		else
			echo -e "${BAD}${UL}does not exist${NORMAL}"
			exit 1
		fi
	done
fi
