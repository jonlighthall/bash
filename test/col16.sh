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
declare -i fore_max=15
declare -i back_max=${fore_max}
for fore in $(seq 0 ${fore_max}); do
    tput setaf $fore
	for back in $(seq 0 ${back_max}); do
		tput setab $back
		printf ' b=%2d f=%2d ' $back $fore
	done
	tput sgr0
	printf '\n'
done
