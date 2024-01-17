#!/bin/bash -u
echo "${0##*/}"

# test X11
export LC_ALL=C
list_test="xeyes xclock xcalc xman xlogo xterm"

# find programs
list_found=''
for prog in $list_test; do
    echo -e "locating $prog... \r\E[19C\c"
	which $prog
	RETVAL=$?
	if [ $RETVAL = 0 ]; then
		list_found="$list_found $prog"
	else
		echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	fi
done

if [ -z "${list_found}" ]; then
    echo "FAIL: no X-programs found!"
    exit
fi

# open programs
list_open=''
for prog in $list_found; do
	$prog 2>/dev/null & 
	RETVAL=$?
	if [ $RETVAL = 0 ]; then
		list_open="$list_open $prog"
	else
		echo -e " opening $prog... \r\E[19C\c"
		echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	fi		
done

if [ -z "${list_open}" ]; then
    echo "FAIL: no X-programs opened!"
    exit
fi

# check if programs are running
echo
list_run=''
for prog in $list_found; do
    echo -e "checking $prog... \r\E[19C\c"
	ps | grep "$prog" >/dev/null
	RETVAL=$?
	if [ $RETVAL = 0 ]; then
		echo -e "\E[32mOK\E[0m"
		list_run="$list_run $prog"
	else
		echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	fi
done

if [ -z "${list_run}" ]; then
    echo "FAIL: no X-programs running!"
    exit
fi

# close windows
echo
read -n 1 -s -r -p $'\E[32m> \E[0mPress any key to continue'
echo
for prog in $list_run; do
    echo -e " closing $prog...\r\E[19C\c"
    pkill $prog
	RETVAL=$?
	if [ $RETVAL = 0 ]; then
		echo -e "\E[90mOK\E[0m"
	else
		echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	fi
done
