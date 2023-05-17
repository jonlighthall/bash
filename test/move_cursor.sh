#!/bin/bash
clear -x
echo -en "\x1B[1;34mhere\x1B[0m"
echo -en "\E[6n"
read -sdR CURPOS
CURPOS=${CURPOS#*[}
echo "${CURPOS}"
cx=${CURPOS#*;}
cy=${CURPOS%;*}
echo "position is x=$cx y=$cy"
ls -la
echo -en "\E[6n"
read -sdR CURPOS
CURPOS=${CURPOS#*[}
cx1=${CURPOS#*;}
cy1=${CURPOS%;*}
echo -e "\x1B[${cy};${cx}H \033[1;31mthere $cx $cy\033[0m"
echo -e "\x1B[${cy1};${cx1}H\033[1;35manywhere $cx1 $cy1\033[0m"
