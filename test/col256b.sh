#!/bin/bash -u
case $TERM in
    xterm*)
        TERM=xterm-256color
        ;;
    linux*)
        TERM=linux-16color
        ;;
esac
export TERM
declare -i qmax=0
declare -i pmax=256
for q in $(seq 0 ${qmax}); do
    tput setaf $q
	for p in $(seq 0 ${pmax}); do
		tput setab $p
		printf ' b=%d f=%d ' $p $q
	done
	tput sgr0
	printf '\n'
done
