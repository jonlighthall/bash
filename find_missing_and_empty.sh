#!/bin/bash
# reads a list of input files and if the 02.asc file does not exist or is empty
# writes the name of the input file to the screen
#FILE1='all_infiles.lst'
FILE1=$1

k=1
while read line; do
  fpre="${line%.*}"
  fname=$(printf '%s_02.asc' "$fpre" )
  #echo $fname
  if [ ! -f $fname ]; then
    echo $line
  fi
#  if [ ! -s $fname ]; then
#    echo $line
#  fi
  ((k++))
done < $FILE1
