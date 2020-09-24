#!/bin/bash

# test X11
export LC_ALL=C
xeyes 2>/dev/null &
xclock 2>/dev/null &
xcalc 2>/dev/null &
xman 2>/dev/null &
xlogo 2>/dev/null &
xterm 2>/dev/null &

# close windows
read -n 1 -s -r -p "Press any key to continue"
echo
pkill xeyes 
pkill xclock
pkill xcalc
pkill xman
pkill xlogo
pkill xterm
