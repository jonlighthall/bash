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
declare -ir fore_max=0
declare -i back_max=256

# loop through colors
tput setaf $fore_max
for back in $(seq 0 ${back_max}); do
	tput setab $back
	printf ' b=%3d ' $back
	if [ $((back % 16)) -eq 0  ]; then
		echo -e "\E[m"
	fi
done
tput sgr0
printf '\n\n'

