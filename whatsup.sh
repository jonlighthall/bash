#!/bin/bash

echo "   host:" $HOSTNAME
echo -n "     IP: ";hostname -I
echo "   user:" $USER$USERNAME
echo " groups:" `id -nG`
echo "    pwd:" $PWD
echo "   date:" $(date)
