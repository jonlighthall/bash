#!/bin/bash
mkdir -pv ~/bin
# list files to be linked in bin
for prog in bell sec2elap whatsup rmbin fix_bad_extensions \
    unfix_bad_extensions test_file update_repos update_packages \
    untar clean_mac
do
    if [ ! -f $HOME/bin/$prog ]; then
	if [ -f $PWD/$prog.sh ]; then
	    ln -svf $PWD/$prog.sh $HOME/bin/$prog
	fi
    fi
done
