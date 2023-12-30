#!/bin/bash -u
echo "${0##*/}"

# test X11
export LC_ALL=C
list_test="xeyes xclock xcalc xman xlogo xterm"
list_found=''

for prog in $list_test; do
    echo -e "opening $prog... \r\E[18C\c"
    $prog 2>/dev/null &
    if ! command -v $prog &>/dev/null; then
        echo -e "\E[33mnot found\E[0m"
    else
        echo -e "\E[32mOK\E[0m"
        list_found="$list_found $prog"
    fi
done

if [ -z "${list_found}" ]; then
    echo "FAIL: no X-programs found!"
    exit
fi

# close windows
read -n 1 -s -r -p $'\E[32m> \E[0mPress any key to continue'
echo
for prog in $list_found; do
    echo -e "closing $prog...\r\E[18C\c"
    pkill $prog 2>/dev/null
	RETVAL=$?
	if [ $RETVAL = 0 ]; then
     echo -e "\E[90mOK\E[0m"
	else
		echo -e "\E[31mFAIL\E[0m"
	fi
done
