#!/bin/bash
mkdir -p ~/bin
for prog in bell
do
    ln -sv $HOME/bash/$prog.sh $HOME/bin/$prog
done
