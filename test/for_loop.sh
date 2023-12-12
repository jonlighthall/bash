#!/bin/bash -u
N=5000
echo "start"
echo -e "counting to $N... \E[s+++"
for ((i=1;i<=$N;i++))
do
    echo -en "   $i: x"
    echo -en "y"
    echo -en "z"
    if [ "$i" -lt "$N" ];then
	echo -en " $i < $N"
	echo -en "\E[K"
    else
	echo " $i >= $N"
	echo "done"
	echo -en "\E[u"
	sleep 1
	echo "here"
	echo -e "\E[E"
    fi
done
echo "one more line"
