#!/bin/bash
start_time=$(date +%s%N)
# print source name at start
echo
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

echo
echo "compare process name..."
called_by=$(ps -o comm= $PPID)
echo -n "   called by ${called_by}: "
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
    echo -e "\x1b[0;36menvoked by shell\x1b[0m"
    #(return not_child)
else
    echo -e "\x1b[0;35menvoked by another process\x1b[0m"
    #(return child)
fi

echo "compare PID..."
echo "          PID = $$"
echo "   parent PID = $PPID"

echo
echo "compare pstree"
pstree -Apu | grep $$ | xargs
pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/"
pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//"
SH_LEV=$(pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | grep -o "\-\-\-" | wc -l)
echo "   ps tree shell level = $SH_LEV"
#echo "           shell level = $SHLVL"
#echo -n "   same as SHLVL? "
if [ "$SHLVL" = "$SH_LEV" ]; then
    :
    #   echo "yes"
else
    #  echo "no"
    exit 1
fi

SHELL_NAME=${SHELL##*/}
echo
echo "compare with shell"
echo "   shell is $SHELL_NAME"
echo "-----------------------------------"
pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g"
PS_LEV=$(pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g" | grep -o "\-\-\-" | wc -l)

pstree -Apu | grep $PPID | xargs | sed "s/\($PPID[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g"
PPS_LEV=$(pstree -Apu | grep $PPID | xargs | sed "s/\($PPID[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g" | grep -o "\-\-\-" | wc -l)

PSH_LEV=$((SH_LEV - PS_LEV))
echo "-----------------------------------"
echo "           shell level = $SHLVL"
echo "         process level = $PS_LEV"
echo "  parent process level = $PPS_LEV" 
echo "    prompt shell level = $PSH_LEV"
echo "-----------------------------------"

echo -n "parent process level = 0? "
if [ "$PPS_LEV" -eq 0 ]; then
    echo "yes"
    # only works if sourced
    if [ "${0}" = "$BASH_SOURCE"  ];then
	echo -e "      \$0 same as \$BASH_SOURCE"
	echo "      This script is called by another process."
    else
	echo -e "      \$0 NOT same as \$BASH_SOURCE"
	echo "      This script is not called by another process."
    fi
else
    echo "no"
fi

echo
echo "compare shell level..."
if (return 0 2>/dev/null); then
    echo -e "\x1b[33m   sourced\x1b[0m"
    echo "   compare shell/script to source..."
    # only works if sourced
    if [ "${0}" = "$BASH_SOURCE"  ];then
	echo -e "      \$0 same as \$BASH_SOURCE"
	echo "      This script is called by another process."
    else
	echo -e "      \$0 NOT same as \$BASH_SOURCE"
	echo "      This script is not called by another process."
    fi
    BASE_LVL=0
else
    echo -e "\x1b[34m   not sourced\x1b[0m"
    BASE_LVL=1
fi

echo "BASE_LVL = $BASE_LVL"

[[ $SHLVL -gt ${nstack} ]] &&
    echo "   called from parent" ||
	echo "   called directly"

echo "BASE_LVL = $BASE_LVL"
echo "process level $PS_LEV"
echo "PS lev > $BASE_LVL " 

echo -n "(shell level $SHLVL) -gt (process level $PS_LEV) ? "

if [ "$PS_LEV" -gt 1 ] || ( [ "$PS_LEV" -gt "$PPS_LEV" ] && [ "$SH_LEV" -eq "$PSH_LEV"]) || ( [ "$SH_LEV" -gt "$PSH_LEV" ] && [ "$PS_LEV" -gt 1 ] ); then
    echo true
    echo -e "\x1b[0;35m$(basename $BASH_SOURCE) was envoked by another process\x1b[0m"
else
    echo false
    echo -e "\x1b[0;32m$(basename $BASH_SOURCE) was envoked by $SHELL_NAME shell\x1b[0m"
fi

# call child process
echo
echo "calling child process..."
source_dir=$(dirname $BASH_SOURCE)
${source_dir}/child.sh

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
echo " on $(date +"%a %b %-d at %-l:%M %p %Z") DUMMY=$DUMMY"
