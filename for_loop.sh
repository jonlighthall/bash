#!/bin/bash
N=5000
echo "start"
echo -e "counting to $N... \x1B[s+++"
for ((i=1;i<=$N;i++))
do
    echo -en "   $i: x"
    echo -en "y"
    echo -en "z"
    if [ "$i" -lt "$N" ];then
	echo -en " $i < $N"
	echo -en "\x1B[K"
    else
	echo " $i >= $N"
	echo "done"
	echo -en "\x1B[u"
	sleep 1
	echo "here"
	echo -e "\x1B[E"
    fi
done
echo "one more line"
