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
declare -i fore_max=7
declare -i back=0
declare -i mode_max=9
declare -i i
for mode in $(seq 0 ${mode_max}); do
	  if [ $mode -eq 6 ] || [ $mode -eq 8 ]; then
		    continue
	  fi

	  echo "mode = ${mode}"
    echo "standard  bright"
	  for ((fore=0; fore<=${fore_max}; fore++)); do
		    if [ $fore -eq 8 ] || [ $mode -eq 7 ]; then
			      continue
		    fi

			  echo -ne " \E[${mode};3${fore};4${back}m"
			  printf '%d;3%d;4%d' $mode $fore $back

		    echo -en "\E[0m  "
	
			  echo -ne "\E[${mode};9${fore};4${back}m"
			  printf '%d;9%d;4%d' $mode $fore $back

		    echo -e "\E[m"
	  done
	  echo -e "\E[m"

done
