#!/bin/bash
mkdir -pv ~/bin
# list files to be linked in bin
for prog in bell sec2elap whatsup rmbin
do
    if [ ! -f $HOME/bin/$prog ]; then
	ln -sv $HOME/bash/$prog.sh $HOME/bin/$prog
    fi
done
