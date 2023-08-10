#!/bin/bash
echo -n "elapsed time is "
# check if input is empty
echo -ne "\x1B[1;37m"
if [ $# -eq 0 ]
then
    echo "NULL"
else
    # check if input is floating point
    if [[ "$1" = *"."* ]]; then
	# round to the nearest integer
	ELAP=$(echo "scale=0;(${1}+0.5)/1" | bc)
	# calculate number of decimal places
	deci=${1#*.}
	nd=${#deci}
    else
	ELAP=$1
	nd=0
    fi

    if [ $(echo "$1<1" | bc) -eq 1  ]; then
	fmt="%.${nd}f sec\n"
	printf "$fmt" $1
    else
	if [ ${nd} -gt 1 ];then
	    ((nd--))
	fi
	if [ $(echo "$1<10" | bc) -eq 1  ]; then
	    fmt="%.${nd}f sec\n"
	    printf "$fmt" $1
	else
	    ((nd--))
	    if [ $(echo "$1<60" | bc) -eq 1  ]; then
		if [ ${nd} -gt 0 ];then
		    fmt="%.${nd}f sec\n"
		    printf "$fmt" $1
		else
		    echo "$ELAP sec"
		fi
	    else
		if (( $ELAP < $((60*60)) )); then
		    echo $(date -d @${ELAP} +"%M min %S sec")
		else
		    HR=$(($ELAP/(60*60)))
		    if (( $HR < 24 )); then
			echo $(date -d @${ELAP} +"$HR hours %M min %S sec")
		    else
			DY=$(($HR/24))
			HR=$(($HR - $DY*24))
			if (( $DY < $((365)) )); then
			    echo $(date -d @${ELAP} +"$DY days $HR hours %M min %S sec")
			else
			    YR=$(($DY/365))
			    DY=$(($DY - $YR*365))
			    echo $(date -d @${ELAP} +"$YR years $DY days $HR hours %M min %S sec")
			fi
		    fi
		fi
	    fi
	fi
    fi
fi
echo -ne "\x1B[0m"
