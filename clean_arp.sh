#!/bin/bash
# this cleans up the nspe files in an arp directory

find $1 -name "nspe*.prs" -exec rm -rv "{}" \;
find $1 -name "nspe*_4?.dat" -exec rm -rv "{}" \;
find $1 -name "nspe*.out" -exec rm -rv "{}" \;
find $1 -name "nspe*.log" -exec rm -rv "{}" \;
find $1 -name "nspe*.003" -exec rm -rv "{}" \;
#find $1 -name "nspe*.asc" -exec rm -rv "{}" \;

printf "\a"