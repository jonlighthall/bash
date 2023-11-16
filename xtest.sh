#!/bin/bash
echo "${0##*/}"

# test X11
export LC_ALL=C
list="xeyes xclock xcalc xman xlogo xterm"

for prog in $list
do
    echo -e "opening $prog... \c"
    $prog 2>/dev/null &
    if ! command -v $prog &> /dev/null
    then
	echo "not found"
    else
	echo "OK"
	list2="$list2 $prog"
    fi
done

if [ -z "${list2}" ]; then
    echo  "FAIL: no X-programs found!"
    exit
fi

# close windows
read -n 1 -s -r -p "Press any key to continue"
echo
for prog in $list2
do
    echo "closing $prog..."
    pkill $prog 2>/dev/null &
done
