#!/bin/bash -u

# determine terminal colors
case $TERM in
    xterm*)
        TERM=xterm-256color
        ;;
    linux*)
        TERM=linux-16color
        ;;
esac
export TERM
echo "printing $TERM colors..."

# set looping limits
declare -ir control_var=0
declare -ir loop_limit=255

# loop through colors
tput setab $control_var
for col in $(seq 0 ${loop_limit}); do
	tput setaf $col
	printf ' f=%3d ' $col
	if [ $col -lt 15 ] || [ $col -gt 231 ]; then
		# display system colors in groups of 8
		if [ $((((col + 1)) % 8)) -eq 0  ] ; then
			echo -e "\E[m"
		fi
	else
		# display non-system colors in 6 groups of 36
		if [ $((((col -16 + 1)) % 6)) -eq 0  ] ; then
			echo -ne "\E[m"
		fi
		if [ $((((col -16 + 1)) % ((6 *6)))) -eq 0  ] ; then
			echo -e "\E[m"
		fi
		# seperate out system colors and grays		
		if [ $col = 15 ] || [ $col = 231 ]; then
			echo -e "\E[m"
		fi
	fi
done
tput sgr0

