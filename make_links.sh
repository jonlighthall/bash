#!/bin/bash
mkdir -pv ~/bin
# list files to be linked in bin
for prog in bell sec2elap whatsup rmbin fix_bad_extensions unfix_bad_extensions test_file
do
    if [ ! -f $HOME/bin/$prog ]; then
	ln -svf $PWD/$prog.sh $HOME/bin/$prog
    fi
done
