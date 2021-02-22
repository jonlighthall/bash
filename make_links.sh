#!/bin/bash
mkdir -pv ~/bin
for prog in bell sec2elap whatsup
do
    if [ ! -f $HOME/bin/$prog ]; then
	ln -sv $HOME/bash/$prog.sh $HOME/bin/$prog
    fi
done
