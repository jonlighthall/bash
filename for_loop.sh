#!/bin/bash
N=5
for ((i=1;i<=$N;i++))
do
    echo -en "$i: x"
    sleep 1
    echo -en "y"
    sleep 1
    echo -en "z"
    #    echo -e "xy\x1B[Kz"
    if [ "$i" -lt "$N" ];then
	echo -en " $i < $N"
	sleep 1
	echo -en "\x1B[K"

    else
	echo " $i >= $N"
    fi
done
