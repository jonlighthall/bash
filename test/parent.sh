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
echo "directory--------------------"
echo -e "     \$ directory ${0%/*}"
source_dir=$(dirname $BASH_SOURCE)
echo "source directory ${source_dir}"
link_dir=$(dirname "${src_name}")
echo "  link directory ${link_dir}"
real_dir=$(dirname "$(realpath $BASH_SOURCE)"	 )
echo "  real directory ${real_dir}"
start_dir=$PWD
echo "             PWD ${start_dir}"
echo "         logical" $(\pwd -L)
echo "        physical" $(\pwd -P)

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
if [ "$$" = "$PPID"  ];then
    echo "   PID = PPID"
else
    echo "   PID ne PPID"
fi

echo "compare shell level..."
if (return 0 2>/dev/null); then
    echo "   sourced"
    nstack=1
else
    echo "   not sourced"
    nstack=2
fi

echo "   assuming stack size is ${nstack}"
echo "   shell level = $SHLVL"

[[ $SHLVL -gt ${nstack} ]] &&
    echo "   called from parent" ||
	echo "   called directly"

echo "compare process name..."
called_by=$(ps -o comm= $PPID)
echo "   called by ${called_by}"
echo -en "${white}"
echo "   ----------------------"
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
    echo "   envoked by shell"
else
    echo "   envoked by another process"
fi
echo "   ----------------------"
echo -en "${NORMAL}"

echo
echo "compare pstree"
pstree -Apu -H $$
pstree -Apu -H $PPID

echo "parent: "
pstree -Apu -H $$ | grep $PPID
pstree -Apu -H $$ | grep $PPID | tr -d "$PPID"
pstree -Apu -H $$ | grep $PPID | sed "s/$PPID.*//"
pstree -Apu -H $$ | grep $PPID | sed "s/$PPID.*//" | grep -o "\-\-\-" | wc -l


echo "child: "
pstree -Apu -H $$ | grep $$
pstree -Apu -H $$ | grep $$ | sed "s/$$.*//" | grep -o "\-\-\-"
pstree -Apu -H $$ | grep $$ | sed "s/$$.*//" | grep -c "\-\-\-" | wc -l



echo
echo "calling child process..."
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
echo " on $(date +"%a %b %-d at %-l:%M %p %Z")"
