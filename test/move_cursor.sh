#!/bin/bash -u
function cursor_pos() {
	# get the cursor position
	echo -en "\E[6n"
	read -sdR CURPOS
	# parse the cursor position
	CURPOS=${CURPOS#*[}
	x_pos=${CURPOS#*;}
	y_pos=${CURPOS%;*}
	# print the cursor position
	echo -e "\nposition is x=$x_pos y=$y_pos"
}

clear -x
echo -en "\E[1;34mhere\E[0m"
sleep 1
cursor_pos
set -x
ls -la --color=always
sleep 1
set +x
echo -en "\E[6n"
read -sdR CURPOS
CURPOS=${CURPOS#*[}
cx1=${CURPOS#*;}
cy1=${CURPOS%;*}
echo -en "\E[${y_pos};${x_pos}H \E[1;31mthere $x_pos $y_pos\E[0m"
sleep 1
echo -e "\E[${cy1};${cx1}H\E[1;35manywhere $cx1 $cy1\E[0m"
