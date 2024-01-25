#!/bin/bash -u

trap "echo -e '\x1B[11G BASH: $(sec2elap $SECONDS)'" EXIT

if [ $# -eq 0 ]; then
	echo "NULL"
else

	# check if input is floating point
	if [[ "$1" = *"."* ]]; then
		# parse input
		declare -i ln=${#1}
		# determine number of integer places
		declare -i whol=${1%.*}
		declare -i nw=${#whol}
		# determine number of decimal places
		declare -i deci=${1#*.}
		declare -i nd=${#deci}

		echo "$1 is $ln long"
		echo -e "\x1B[${ln}G has $nw integer places"
		echo -e "\x1B[${ln}G and $nd decimal places"

		# define number of "decimals" for ns timestamp
		declare -ir nd_max=9

		# pad timestamp with leading zeros
		if [ $nw -lt $nd_max ]; then
			fmt="%0${nd_max}d"
			printf "$fmt\n" ${whol}
			declare pad0=$(printf "$fmt" ${whol})
			declare -i nw0=${#pad0}
			pad0+=".${deci}"
			echo "zero-padded: $pad0"
			declare -i nl0=${#pad0}
			echo $nl0
			if [ $nw0 -eq ${nd_max} ]; then
				echo "change in length"
				echo "${nw0} numbers long"
			else
				echo "no change"
				exit 1
			fi
		else
			declare pad0="${whol}.${deci}"
		fi

		echo "zero-padded: $pad0"

		if [ $nd -gt $nd_max ]; then
			ddeci=${deci:0:$nd_max}.${deci:$nd_max}
			fmt="%.0f"
			deci=$(printf "$fmt" ${ddeci})
			nd=nd_max
		fi
		
		# get most significant decimal
		if [ $nd -gt 1 ]; then
			declare -ir tenths=${deci::-$(($nd - 1))}
		else
			declare -ir tenths=${deci}
		fi
	else
		ELAP=$1
		declare -ir nd=0
		declare -r prnt_deci=
		declare -ir tenths=0
	fi

fi
