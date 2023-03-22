#!/bin/bash

echo "   host:" $HOSTNAME
echo -n "     IP: ";hostname -I
echo "   user:" $USER$USERNAME
echo " groups:" `id -nG`
echo "    pwd:" $PWD
echo "   date:" $(date)
echo "    PID:  $PPID"
echo "   time:" $(sec2elap $(ps -p $PPID -o etimes | tail -n 1))
