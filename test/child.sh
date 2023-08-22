#!/bin/bash
start_time=$(date +%s%N)
# print source name at start
echo
echo "source----------------------"
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing (not sourced)"
    set -e # exit on non-zero status
fi

echo -e "\$BASH_SOURCE = $BASH_SOURCE"
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "        ${VALID}link${NORMAL} = $src_name"
fi
echo -e "          \$0 = ${0}"

echo "    \$0 running ${0##*/}"

echo
echo "parent----------------------"
echo "compare shell/script to source..."
if [ "${0}" = "$BASH_SOURCE"  ];then
    echo -e "   \$0 same as \$BASH_SOURCE"
    echo "   This script is called by another process."
else
    echo -e "   \$0 NOT same as \$BASH_SOURCE"
    echo "   This script is not called by another process."
fi

echo "compare PID..."
echo "          PID = $$"
echo "   parent PID = $PPID"

BASE_LVL=0
echo "compare shell level..."
if (return 0 2>/dev/null); then
    echo -e "\x1b[33m   sourced\x1b[0m"
    nstack=1

else
    echo -e "\x1b[34m   not sourced\x1b[0m"
    nstack=2
    BASE_LVL=$((BASE_LVL+1))
fi

echo "   assuming stack size is ${nstack}"
echo "   shell level = $SHLVL"
echo "BASE_LVL = $BASE_LVL"

[[ $SHLVL -gt ${nstack} ]] &&
    echo "   called from parent" ||
	echo "   called directly"

echo "compare process name..."
called_by=$(ps -o comm= $PPID)
echo "   called by ${called_by}"
echo -en "${white}"
echo "   ----------------------"
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
    echo -e "\x1b[0;36m   envoked by shell\x1b[0m"

else
    echo -e "\x1b[0;31m   envoked by another process\x1b[0m"

fi
echo "   ----------------------"
echo -en "${NORMAL}"

echo
echo "compare pstree"
pstree -Apu | grep $$ | xargs
pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/"
pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//"
SH_LEV=$(pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | grep -o "\-\-\-" | wc -l)
echo "ps tree shell level $SH_LEV"
echo -n "same as SHLVL? "
if [ "$SHLVL" = "$SH_LEV" ]; then
    echo "yes"
else
    echo "no"
fi
SHELL_NAME=${SHELL##*/}
echo "shell is $SHELL_NAME"
pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g"
PS_LEV=$(pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g" | grep -o "\-\-\-" | wc -l)
echo "process level $PS_LEV"
PSH_LEV=$((SH_LEV - PS_LEV))
echo "prompt shell level is $PSH_LEV"

echo "BASE_LVL = $BASE_LVL"
echo "process level $PS_LEV"
echo -n "PS lev > $BASE_LVL " 

if [ "$PS_LEV" -gt "$BASE_LVL" ]; then
    echo true
    echo -e "\x1b[0;35m$(basename $BASH_SOURCE) was envoked by another process\x1b[0m"
else
    echo false
    echo -e "\x1b[0;32m$(basename $BASH_SOURCE) was envoked by $SHELL_NAME shell\x1b[0m"
fi

# print time at exit
echo -en "${TAB}${PSDIR}$(basename $BASH_SOURCE)${NORMAL} "
end_time=$(date +%s%N)
elap_time=$((${end_time}-${start_time}))
dT_sec=$(bc <<< "scale=3;$elap_time/1000000000")
if command -v sec2elap &>/dev/null
then
    echo -n "$(sec2elap $dT_sec | tr -d '\n')" 
else
    echo -en "elapsed time is ${white}${dT_sec} sec${NORMAL}"
fi
echo " on $(date +"%a %b %-d at %-l:%M %p %Z")"

#./ par pslvl 1, child pslvl 2; par by shell, child by other; both not sourced

#. par 0 ch 1; both by shell; parent source
#bash par 0, ch 1; both by shell
#source par 0, ch 1; both by shell
