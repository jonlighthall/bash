#!/bin/bash
echo -e "elapsed time is \c"
if [ $# -eq 0 ]
then
    echo "NULL"
else
    if (( $1 < 60 )); then
	echo "$1 sec"
    else
	if (( $1 < $((60*60)) )); then
	    echo $(date -d @${1} +"%M min %S sec")
	else
	    HR=$(($1/(60*60)))
	    if (( $HR < 24 )); then
		echo $(date -d @${1} +"$HR hours %M min %S sec")
	    else
		DY=$(($HR/24)) 
		HR=$(($HR - $DY*24))
		if (( $DY < $((365)) )); then
		    echo $(date -d @${1} +"$DY days $HR hours %M min %S sec")
		else
		    YR=$(($DY/365))
		    DY=$(($DY - $YR*365))
		    echo $(date -d @${1} +"$YR years $DY days $HR hours %M min %S sec")
		fi
	    fi
	fi
    fi
fi