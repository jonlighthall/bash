#!/bin/sh
#
INPUT=$1

ENDTIME=$INPUT
echo $(date) "at time $ENDTIME"
if [ $ENDTIME -ge $((60*60*24)) ]; then
    echo "date overflow"
    HR=$(($ENDTIME/(60*60)))
    echo "$HR > 24 hours"
    echo "runtime is" $(date -u -d @${ENDTIME} +"$HR hr %M min %S sec")
else
    echo "runtime is" $(date -u -d @${ENDTIME} +"%H hr %M min %S sec")
fi
