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
declare -i fore_max=256
declare -ir back_max=0

# loop through colors
tput setab $back_max
for fore in $(seq 0 ${fore_max}); do
	tput setaf $fore
	printf ' f=%3d ' $fore
	if [ $((fore % 16)) -eq 0  ]; then
		echo -e "\E[m"
	fi
done
tput sgr0
printf '\n\n'

