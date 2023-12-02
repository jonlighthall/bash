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
declare -i fore_max=9
declare -i back_max=${fore_max}
declare -i mode_max=9
for mode in $(seq 0 ${mode_max}); do
	echo "mode = ${mode}"
	for fore in $(seq 0 ${fore_max}); do
		if [ $fore -eq 8 ]; then
			continue
		fi			
		for back in $(seq 0 ${back_max}); do
			if [ $back -eq 8 ]; then
				continue
			fi			
			echo -ne "\E[${mode};3${fore};4${back}m"
			printf ' %d;3%d;4%d ' $mode $fore $back
		done
		echo -e "\E[m"
	done
	echo -e "\E[m"
done
