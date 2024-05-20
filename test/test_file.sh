#!/bin/bash -u

# no echo source since this is a utility
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi
# set tab
itab
#
# check for input
if [ $# -eq 0 ]; then
	echo "Please provide an input file"
else
	# check arguments
	for arg in "$@"; do
		echo -n "$arg "
		if [ -L "${arg}" ]; then
			echo -n "is a "
			if [ -e "${arg}" ]; then
				echo -e -n "${VALID}valid${RESET}"
			else
				echo -e -n "${BROKEN}broken${RESET}"
			fi
			echo -e " ${UL}link${RESET}"
		elif [ -e "${arg}" ]; then
			echo -n "exists and "
			if [ -f "${arg}" ]; then
				echo -e "is a regular ${UL}file${RESET}"
			else
				if [ -d "${arg}" ]; then
					echo -e "is a ${DIR}${UL}directory${RESET}"
					exit 1
				else
					echo -e "${UL} is not a link, file, or directory"
				fi
			fi
		else
			echo -e "${BAD}${UL}does not exist${RESET}"
			exit 1
		fi
	done
fi
