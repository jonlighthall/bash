#!/bin/bash
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