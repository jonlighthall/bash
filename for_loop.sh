#!/bin/bash
N=5
echo "start"
echo -e "counting to $N... \x1B[s"
for ((i=1;i<=$N;i++))
do
    echo -en "$i: x"
#    sleep 1
    echo -en "y"
 #   sleep 1
    echo -en "z"
    #    echo -e "xy\x1B[Kz"
    if [ "$i" -lt "$N" ];then
	echo -en " $i < $N"
#	sleep 1
#	echo -en "\x1B[K"
	echo
    else
	echo " $i >= $N"
	echo "done"
	#echo -e "\x1B[3F\x1B[1D"
	echo -en "\x1B[u"
	echo "here"
	echo -en "\x1B[$((N+1))B"
    fi
done
echo "one more line"
