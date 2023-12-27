#!/bin/bash -u
echo -n "elapsed time is "
# check if input is empty
echo -ne "\E[1;37m"
if [ $# -eq 0 ]; then
	echo "NULL"
else
	# check if bc installed
	if command -v bc &>/dev/null; then
		# check if input is floating point
		if [[ "$1" = *"."* ]]; then
			# round to the nearest integer
			ELAP=$(echo "scale=0;(${1}+0.5)/1" | bc)
			# calculate number of decimal places
			deci=${1#*.}
			nd=${#deci}
		else
			ELAP=$1
			declare -i nd=0
		fi
		# print output with decimal formatting

		# if less than 1 second
		if [ $(echo "$1<1" | bc) -eq 1 ]; then
			# (maximum decimal places)
			fmt="%.${nd}f sec\n"
			printf "$fmt" $1
		else
			# reduce precision
			if [ ${nd} -gt 1 ]; then
				((nd--))
			fi
			# less than 10 seconds
			if [ $(echo "$1<10" | bc) -eq 1 ]; then
				fmt="%.${nd}f sec\n"
				printf "$fmt" $1
			else
				# reduce precision
				if [ ${nd} -gt 1 ]; then
					((nd--))
				fi
				# less than 1 minute
				if [ $(echo "$1<60" | bc) -eq 1 ]; then
					if [ ${nd} -gt 0 ]; then
						fmt="%.${nd}f sec\n"
						printf "$fmt" $1
					else
						echo "$ELAP sec"
					fi
				fi # minute
			fi # 10 seconds
		fi # 1 second
	else
		# print output without decimal formatting
		ELAP=$1
		if [[ "$1" = *"."* ]]; then
			# truncate time
			ELAP=${ELAP%.*}
			# format time
			deci=${1#*.}
			declare -i nd=${#deci}
			rnd=${deci::-$(($nd - 1))}
		else
			declare -i nd=0
		fi
		
		if (( $ELAP < 1 )); then
			# print argument with full precision
			echo "$1 sec"						
		else
			# reduce precision
			if [ ${nd} -gt 1 ]; then
				((nd--))
				deci=${deci::-1}
			fi
			# if less than 10 seconds
			if (( $ELAP < 10 )); then
				echo -n "$ELAP"
 				if [ ${nd} -gt 0 ]; then
					echo -n ".$deci"
				fi
				echo " sec"
			else
				# reduce precision
				if [ ${nd} -gt 1 ]; then
					((nd--))
					deci=${deci::-1}
				fi
				# if less than a minute
				if (( $ELAP < 60 )); then
					echo -n "${ELAP}"
 					if [ ${nd} -gt 0 ]; then
						echo -n ".$deci"
					fi
					echo " sec"
				else
					# round to the nearest integer
 					if [ ${rnd} -ge 5 ]; then
					 	((ELAP++))						
					fi # round
				fi # minute
			fi # 10 seconds
		fi # 1 second
	fi # bc

	# less than 1 minute
	if [ ! $ELAP -lt 60 ]; then
		if [ $ELAP -gt 100 ]; then
			# reduce precision
			if [ ${nd} -gt 1 ]; then
				((nd--))
				deci=${deci::-1}
			fi
		fi
		# less than 1 hour	
		if (($ELAP < $((60 * 60)))) ; then
			echo $(date -d @${ELAP} +"%M min %S sec")
		else
			HR=$(($ELAP / (60 * 60)))
			# if less than a day
			if (($HR < 24)); then
				echo $(date -d @${ELAP} +"$HR hours %M min %S sec")
			else
				DY=$(($HR / 24))
				HR=$(($HR - $DY * 24))
				# if less than a year
				if (($DY < $((365)))); then
					echo $(date -d @${ELAP} +"$DY days $HR hours %M min %S sec")
				else
					YR=$(($DY / 365))
					DY=$(($DY - $YR * 365))
					echo $(date -d @${ELAP} +"$YR years $DY days $HR hours %M min %S sec")
				fi # year			
			fi # day
		fi # hour
	fi
fi # null

echo -ne "\E[0m"
