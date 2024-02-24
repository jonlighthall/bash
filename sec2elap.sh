#!/bin/bash -u
echo -n "elapsed time is "
# check if input is empty
echo -ne "\E[1;37m"
if [ $# -eq 0 ]; then
	echo "NULL"
else
	# check if input is floating point
	if [[ "$1" = *"."* ]]; then
		# truncate time
		ELAP=${1%.*}
		# calculate number of decimal places
		deci=${1#*.}
		declare -i nd=${#deci}

		declare -ir nd_max=9
		if [ $nd -gt $nd_max ]; then
			ddeci=${deci:0:$nd_max}.${deci:$nd_max}
			fmt="%.0f"
			deci=$(printf "$fmt" ${ddeci})
			nd=nd_max
		fi
		
		# get most significant decimal
		if [ $nd -gt 1 ]; then
			declare -ir tenths=${deci::$(($nd - 1))}
		else
			declare -ir tenths=${deci}
		fi
	else
		ELAP=$1
		declare -ir nd=0
		declare -r prnt_deci=
		declare -ir tenths=0
	fi

	# if less than 1 second
	if [[ $ELAP -lt 1 ]]; then
		# print argument with full precision
		fmt="%.${nd}f sec\n"
		printf "$fmt" $1
	else
		# reduce precision
		if [ ${nd} -gt 0 ]; then
			((nd--))
			prnt_deci=${deci::1}
		fi
		# less than 10 seconds
		if (( $ELAP < 10 )); then
 			fmt="%.${nd}f sec\n"
			printf "$fmt" $1
		else
			# reduce precision
			if [ ${nd} -gt 0 ]; then
				((nd--))
				prnt_deci=${prnt_deci::1}
			fi

			# less than 1 minute
			if (( $ELAP < 60 )); then
				fmt="%.${nd}f sec\n"
				printf "$fmt" $1
			else
				if [ $ELAP -ge 100 ]; then
					# reduce precision
					if [ ${nd} -gt 0 ]; then
						((nd--))
						prnt_deci=${prnt_deci::1}					
					fi
				fi
				if [ $ELAP -ge $((10**3)) ]; then
					# reduce precision
					if [ ${nd} -gt 0 ]; then
						((nd--))
						prnt_deci=${prnt_deci::1}					
					fi
				fi				
				# round to the nearest integer
				if [ ${nd} -eq 0 ] && [ ${tenths} -ge 5 ]; then
					((ELAP++))
				fi
				# check if the decimals round to zero
				fmt="%.${nd}f"
				declare -i tenths_fmt=$(printf "$fmt" $1 | sed 's/^.*\.//')
				# ...and round up accordingly
				if [ $tenths_fmt -eq 0 ]; then
					ELAP=$(printf "$fmt" $1 | sed 's/\..*$//')
				fi
				
				# less than 1 hour	
				if (($ELAP < $((60 * 60)))) ; then
					echo -n $(date -d @${ELAP} +"%M min %S")
					if [ ${nd} -gt 0 ]; then
						fmt="%.${nd}f"
						printf "$fmt" $1 | sed 's/^.*\././'
					fi
					echo " sec"
				else
					HR=$(($ELAP / (60 * 60)))
					if [ $ELAP -ge $((10**4)) ]; then
						# reduce precision
						if [ ${nd} -gt 0 ]; then
							((nd--))
							prnt_deci=${prnt_deci::1}					
						fi
					fi				
					# if less than a day					
					if (($HR < 24)); then					
						echo -n $(date -d @${ELAP} +"$HR hours %M min %S")
						if [ ${nd} -gt 0 ]; then
							fmt="%.${nd}f"
							printf "$fmt" $1 | sed 's/^.*\././'
						fi
						echo " sec"					
					else
						DY=$(($HR / 24))
						HR=$(($HR - $DY * 24))
						if [ $ELAP -ge $((10**5)) ]; then
							# reduce precision
							if [ ${nd} -gt 0 ]; then
								((nd--))
								prnt_deci=${prnt_deci::1}					
							fi
						fi
						if [ $ELAP -ge $((10**6)) ]; then
							# reduce precision
							if [ ${nd} -gt 0 ]; then
								((nd--))
								prnt_deci=${prnt_deci::1}					
							fi
						fi				

						# if less than a year
						if (($DY < $((365)))); then
							echo -n $(date -d @${ELAP} +"$DY days $HR hours %M min %S")
							if [ ${nd} -gt 0 ]; then
								fmt="%.${nd}f"
								printf "$fmt" $1 | sed 's/^.*\././'
							fi
							echo " sec"
						else
							YR=$(($DY / 365))
							DY=$(($DY - $YR * 365))
							if [ $ELAP -ge $((10**7)) ]; then
								# reduce precision
								if [ ${nd} -gt 0 ]; then
									((nd--))
									prnt_deci=${prnt_deci::1}					
								fi
							fi
							echo -n $(date -d @${ELAP} +"$YR years $DY days $HR hours %M min %S")
							if [ ${nd} -gt 0 ]; then
								fmt="%.${nd}f"
								printf "$fmt" $1 | sed 's/^.*\././'
							fi
							echo " sec"
						fi # year
					fi # day
				fi # hour
			fi # 1 minute
		fi # 10 seconds
	fi # 1 second
fi # null

echo -ne "\E[0;m"
