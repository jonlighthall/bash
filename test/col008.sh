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
declare -i fore_max=8
declare -i back_max=${fore_max}
for fore in $(seq 0 ${fore_max}); do
	for back in $(seq 0 ${back_max}); do
		echo -ne "\E[3${fore};4${back}m"
		printf ' b=3%d f=4%d ' $back $fore
	done
	echo -e "\E[m"
done
