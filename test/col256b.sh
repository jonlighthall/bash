#!/bin/bash -u
case $TERM in
    xterm*)
        TERM=xterm-256color
        ;;
    linux*)
        TERM=linux-16color
        ;;
esac
export TERM
declare -i fore_max=0
declare -i back_max=256
for fore in $(seq 0 ${fore_max}); do
    tput setaf $fore
	for back in $(seq 0 ${back_max}); do
		tput setab $back
		printf ' b=%3d f=%3d ' $back $fore
		if [ $((back % 16)) -eq 0  ]; then
			echo -e "\E[m"
		fi
	done
	tput sgr0
	printf '\n\n'
done
