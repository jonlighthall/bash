#!/bin/bash

# test X11
export LC_ALL=C
list="xeyes xclock xcalc xman xlogo xterm"

for prog in $list
do
    $prog 2>/dev/null &
done

# close windows
read -n 1 -s -r -p "Press any key to continue"
echo
for prog in $list
do
   pkill $prog 2>/dev/null &
done