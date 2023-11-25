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
q=0
tput setaf $q
for p in $(seq 0 255); do
    tput setab $p
    printf ' b=%d f=%d ' $p $q
done
tput sgr0
printf '\n'

