#!/bin/bash

# test X11
export LC_ALL=C
list="xeyes xclock xcalc xman xlogo xterm"

for prog in $list
do
    echo "opening $prog..."
    $prog 2>/dev/null &
done

# close windows
read -n 1 -s -r -p "Press any key to continue"
echo
for prog in $list
do
    echo "closing $prog..."
    pkill $prog 2>/dev/null &
done