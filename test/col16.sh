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
declare -i qmax=15
declare -i pmax=${qmax}
for q in $(seq 0 ${qmax}); do
    tput setaf $q
	for p in $(seq 0 ${pmax}); do
		tput setab $p
		printf ' b=%2d f=%2d ' $p $q
	done
	tput sgr0
	printf '\n'
done
