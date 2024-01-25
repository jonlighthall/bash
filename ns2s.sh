#!/bin/bash -u

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
		declare deci=''
		declare -i nd=0
		declare frac=''
	fi
	echo -e "\x1B[${ln}G and $nd decimal places"

	if [ $nd -gt 0 ]; then
		echo "decimals: $deci"
		echo "number of decimails: $nd"
		echo "fractional part: $frac"
	fi

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
	echo "padded lenght: $nl0"
	
	echo "zero-padded: $pad0f ns"		
fi

# format timestamp in s
if [ $nw -gt $nd_max ]; then
	ni=$(($nw-$nd_max))
	declare sdec=${pad0:$ni}
	if [ $sdec -gt 0 ]; then 
		echo "greater than 1 s"
	else
		echo "equal to 1 s"
	fi
	wholns=${pad0:0:$ni}.${sdec}
else
	echo "less than 1 s"
	wholns="0.${pad0}"
fi
echo "   whole ns: $wholns"
if [ $nd -gt 0 ]; then
	echo "    deci ns: $deci"
fi
fracns="${wholns}${deci}"
echo "decimalized: $fracns s"

# round timestamp to nearest second
fmt="%.0f"			
declare -i whols=$(printf "$fmt" ${fracns})
echo "integerized: $whols s"

if [[ "$fracns" = *"."* ]]; then
	# determine number of decimal places
	declare  decis=${fracns#*.}
	declare  nds=${#decis}
else
	declare -i decis=''
	declare -i nds=0
fi
echo -e "\x1B[${ln}G and $nds decimal places"

echo "remainder: 0.$decis"

if [ ${decis} -gt 0 ]; then
	echo "round up"
	declare rsec=$((whols+1))
else
	echo "no change"
	declare rsec=$whols
fi

echo "    rounded: $rsec s"
