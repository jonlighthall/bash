#!/bin/bash
case $TERM in
    xterm*)
        TERM=xterm-256color
        ;;
    linux*)
        TERM=linux-16color
        ;;
esac
export TERM
for p in $(seq 0 15)
do
    tput setab $p
    for q in $(seq 0 15)
    do
        tput setaf $q
        printf '%x%x' $p $q
    done
    tput sgr0
    printf '\n'
done
