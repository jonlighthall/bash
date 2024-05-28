#!/bin/bash -u
start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

echo

# deterimine run type
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing (not sourced)"
    # exit on errors
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi

# print source name at start
echo -e "\$BASH_SOURCE = $BASH_SOURCE"
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "        ${VALID}link${RESET} = $src_name"
fi

echo
echo "compare process name..."
called_by=$(ps -o comm= $PPID)
echo -n "   called by ${called_by}: "
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
    echo -e "\E[0;36menvoked by shell\E[0m"
    #(return not_child)
else
    echo -e "\E[0;35menvoked by another process\E[0m"
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
echo "           shell level = $SHLVL"
echo -n "   same as SHLVL? "

if [ "$SHLVL" = "$SH_LEV" ]; then
    echo "yes"
else
    echo "no"
    echo -e "\E[0;31mSHELL LEVEL MISMATCH\E[0m"
    echo "           shell level = $SHLVL"
    echo "           shell level = $SH_LEV"
    #  exit 1
fi

SHELL_NAME=${SHELL##*/}
echo
echo "compare with shell"
echo "   shell is $SHELL_NAME"
echo "-----------------------------------"
echo "process shell level: "
pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g"
PS_LEV=$(pstree -Apu | grep $$ | xargs | sed "s/\($$[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g" | grep -o "\-\-\-" | wc -l)
if [ "${PS_LEV}" -eq 0 ]; then
    echo "EMPTY!"
fi

echo "parent process shell level: "
pstree -Apu | grep $PPID | xargs | sed "s/\($PPID[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g"
PPS_LEV=$(pstree -Apu | grep $PPID | xargs | sed "s/\($PPID[^)]*)\).*/\1/" | sed "s/^.*SessionLeader([0-9]*)//" | sed "s/\-\-\-$SHELL_NAME([^)]*)//g" | grep -o "\-\-\-" | wc -l)
if [ "${PPS_LEV}" -eq 0 ]; then
    echo "EMPTY!"
fi

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
    if [ "${0}" = "$BASH_SOURCE" ]; then
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
    echo -e "\E[33m   sourced\E[0m"
    echo "   compare shell/script to source..."
    # only works if sourced
    if [ "${0}" = "$BASH_SOURCE" ]; then
        echo -e "      \$0 same as \$BASH_SOURCE"
        echo "      This script is called by another process."
    else
        echo -e "      \$0 NOT same as \$BASH_SOURCE"
        echo "      This script is NOT called by another process."
    fi
else
    echo -e "\E[34m   not sourced\E[0m"
fi

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

echo "process level $PS_LEV"

echo -n "(shell level $SHLVL) -gt (process level $PS_LEV) ? "

if [ "$PS_LEV" -gt 1 ] || ([ "$PS_LEV" -gt "$PPS_LEV" ]) || ([ "$SH_LEV" -gt "$PSH_LEV" ] && [ "$PS_LEV" -gt 1 ]); then
    echo true
    echo -e "\E[0;35m$(basename $BASH_SOURCE) was envoked by another process\E[0m"
else
    echo false
    echo -e "\E[0;32m$(basename $BASH_SOURCE) was envoked by $SHELL_NAME shell\E[0m"
fi

# print time at exit
echo -en "${TAB}${PSDIR}$(basename $BASH_SOURCE)${RESET} "
print_elap
echo -en "\n${fTAB}DUMMY"
if [ -z ${DUMMY+dummy} ]; then
	echo " undefined"
else
	echo "=$DUMMY"
fi

#./ par pslvl 1, child pslvl 2; par by shell, child by other; both not sourced

#. par 0 ch 1; both by shell; parent source
#bash par 0, ch 1; both by shell
#source par 0, ch 1; both by shell
