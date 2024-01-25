#!/bin/bash -ueE
declare -ir DEBUG=0

# conditional debug echo
decho() {
	if [ -z ${DEBUG:+dummy} ] || [ $DEBUG -gt 0 ]; then
		# if DEBUG is (unset or null) or greater than 0
		echo "$@"
	fi
}

if [ $# -eq 0 ]; then
	echo "NULL"
else
	# determine input length
	declare -i ln=${#1}
	decho "$1 is $ln long"

	# define number of "decimals" for ns timestamp
	declare -ir nd_max=9

	# determine number of integer places
	declare -i whol=${1%.*}
	declare -i nw=${#whol}

	decho -e "\x1B[${ln}G has $nw integer places"
	
	# check if input is floating point
	if [[ "$1" = *"."* ]]; then
		# determine number of decimal places
		declare deci=${1#*.}
		declare -i nd=${#deci}
		declare frac=".${deci}"
	else
		declare deci=''
		declare -i nd=0
		declare frac=''
	fi
	decho -e "\x1B[${ln}G and $nd decimal places"

	if [ $nd -gt 0 ]; then
		decho "decimals: $deci"
		decho "number of decimails: $nd"
		decho "fractional part: $frac"
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
	decho "padded integer places: $nw0"
	if [ ${nw0} -ne ${nw} ]; then
		decho "change in whole number length"
	else
		decho "no change"
		if [ ${nw0} -lt ${nd_max} ]; then
			decho "fail"
			exit 1
		else
			decho "ok"
		fi
	fi

	pad0f="${pad0}${frac}"	
	declare -i nl0=${#pad0f}
	decho "padded lenght: $nl0"	
	decho "zero-padded: $pad0f ns"		
fi

# format timestamp in s
if [ $nw -gt $nd_max ]; then
	ni=$(($nw-$nd_max))
	declare sdec=${pad0:$ni}
	if [ $sdec -gt 0 ]; then 
		decho "greater than 1 s"
	else
		decho "equal to 1 s"
	fi
	wholns=${pad0:0:$ni}.${sdec}
else
	decho "less than 1 s"
	wholns="0.${pad0}"
fi
decho "   whole ns: $wholns"
if [ $nd -gt 0 ]; then
	decho "    deci ns: $deci"
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
decho -e "\x1B[${ln}G and $nds decimal places"

decho "remainder: 0.$decis"

if [ ${decis} -gt 0 ]; then
	decho "round up"
	declare rsec=$((whols+1))
else
	decho "no change"
	declare rsec=$whols
fi

echo "    ceiling: $rsec s"
