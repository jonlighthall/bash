#!/bin/bash -ueE
# program to test formatting of sec2elap over different time epochs
for n in {0..10}; do
    echo -n "10^$n = "
    declare -i i=$((10**$n))
	echo "$i"
	((i--))
	dec="."
	for m in {0..2}; do 
		echo -n "  $i, $m: "
		dec+="$m"
		declare j=$(echo "$i$dec")
		echo "$j"
#		if [ $m -ge $n ]; then 
		../ns2s.sh $j
#		fi
	done
done
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
