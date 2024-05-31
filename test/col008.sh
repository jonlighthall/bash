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
	if [ $mode -eq 6 ] || [ $mode -eq 8 ]; then
		continue
	fi			
	
	echo "mode = ${mode}"
  echo "${mode}:3-:4- standard"
	for ((fore=0; fore<=${fore_max}; fore++)); do
		if [ $fore -eq 8 ]; then
			continue
		fi			
		for ((back=0; back<=${back_max}; back++)); do
			if [ $back -eq 8 ]; then
				continue
			fi			
			echo -ne "\E[${mode};3${fore};4${back}m"
			printf ' %d;3%d;4%d ' $mode $fore $back
		done
		echo -e "\E[m"
	done
	echo -e "\E[m"
  echo "${mode}:3-:10- bright background"
	for ((fore=0; fore<=${fore_max}; fore++)); do
		if [ $fore -eq 8 ]; then
			continue
		fi			
		for ((back=0; back<=${back_max}; back++)); do
			echo -ne "\E[${mode};3${fore};10${back}m"
			printf ' %d;3%d;10%d ' $mode $fore $back
		done
		echo -e "\E[m"
	done
	echo -e "\E[m"
  echo "${mode}:9-:4- bright foreground"
	for ((fore=0; fore<=${fore_max}; fore++)); do
		for ((back=0; back<=${back_max}; back++)); do
			if [ $back -eq 8 ]; then
				continue
			fi			
			echo -ne "\E[${mode};9${fore};4${back}m"
			printf ' %d;9%d;4%d ' $mode $fore $back
		done
		echo -e "\E[m"
	done
	echo -e "\E[m"
  echo "${mode}:9-:10- all bright"
	for ((fore=0; fore<=${fore_max}; fore++)); do
		for ((back=0; back<=${back_max}; back++)); do
			echo -ne "\E[${mode};9${fore};10${back}m"
			printf ' %d;9%d;10%d ' $mode $fore $back
		done
		echo -e "\E[m"

	done
	echo -e "\E[m"	
done
