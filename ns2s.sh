#!/bin/bash -u

trap "echo -e '\x1B[11G BASH: $(sec2elap $SECONDS)'" EXIT

if [ $# -eq 0 ]; then
	echo "NULL"
else
	# determine input length
	declare -i ln=${#1}
	echo "$1 is $ln long"

	# define number of "decimals" for ns timestamp
	declare -ir nd_max=9

	# determine number of integer places
	declare -i whol=${1%.*}
	declare -i nw=${#whol}

	echo -e "\x1B[${ln}G has $nw integer places"
	
	# check if input is floating point
	if [[ "$1" = *"."* ]]; then
		# determine number of decimal places
		declare -i deci=${1#*.}
		declare -i nd=${#deci}
		declare frac=".${deci}"
	else
		declare -i deci=''
		declare -i nd=0
		declare frac=''
	fi
	echo -e "\x1B[${ln}G and $nd decimal places"

	echo "decimals: $deci"
	echo "number of decimails: $nd"
	echo "fractional part: $frac"

	# pad timestamp with leading zeros
	if [ $nw -lt $nd_max ]; then
		fmt="%0${nd_max}d"
		declare pad0=$(printf "$fmt" ${whol})
	else
		declare pad0="${whol}"
	fi
	declare -i nw0=${#pad0}

	# check new length
	# zero-padded whole number length shoudl be 9 or nw
	echo "padded integer places: $nw0"
	if [ ${nw0} -ne ${nw} ]; then
		echo "change in whole number length"
	else
		echo "no change"
		if [ ${nw0} -lt ${nd_max} ]; then
			echo "fail"
			exit 1
		else
			echo "ok"
		fi
	fi

	pad0f="${pad0}${frac}"	
	declare -i nl0=${#pad0f}
	echo "new lenght: $nl0"
	
	echo "zero-padded: $pad0f"		
fi

# format timestamp in s
if [ $nw -gt $nd_max ]; then
	echo "greater than 1 s"
	ni=$(($nw-$nd_max))
	wholns=${pad0:0:$ni}.${pad0:$ni}
else
	echo "less than or equal to 1 s"
	wholns="0.${pad0}"
fi
echo "   whole ns: $wholns"
fracns="${wholns}${deci}"
echo "decimalized: $fracns "

# round timestamp to nearest second
fmt="%.0f"			
declare -i whols=$(printf "$fmt" ${fracns})
echo "integerized: $whols "
