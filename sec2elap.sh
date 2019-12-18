#!/bin/bash
if [ $# -eq 0 ]
then
    echo "Please provide an input"
else
    echo $(date) "at end, elapsed time $1 sec"
    if [[ $1 < $((60*60)) ]]; then
	echo $(date -d @${1} +"%M min %S sec")
    else
	HR=$(($1/(60*60)))
	if (( $HR < 24 )); then
	    echo $(date -d @${1} +"$HR hours %M min %S sec")
	else
	    DY=$(($HR/24)) 
	    HR=$(($HR - $DY*24))
	    echo $(date -d @${1} +"$DY days $HR hours %M min %S sec")
	fi
    fi
fi