#!/bin/bash -u
sleep 1 &
echo $!
sleep 2 &
echo $!
sleep 3 &
echo $!
echo $(date +%T)
echo -n "waiting..."
wait 
echo "done"
echo $(date +%T)
echo -en "\n$(date), "
if [ -z sesc2elap ]; then
    echo "$SECONDS"
else
    bash sec2elap ${SECONDS}
fi
