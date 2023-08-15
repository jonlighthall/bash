#!/bin/bash
set -e # exit on non-zero status
start_time=$(date +%s%N)
# print source name at start
echo "source----------------------"
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi


echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
echo "  running ${0}"
echo "running ${0##*/}"



echo "directory--------------------"
echo "in ${0%/*}"

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

echo "parent----------------------"

if [ "${0}" = "$BASH_SOURCE"  ];then
    echo "   0 same as bash source"
    echo "   This script is called by another process."
else
    echo "   0 NOT same as bash source"
    echo "   This script is not called by another process."
fi

echo "       PID = $$"
echo "parent PID = $PPID"


echo "$SHLVL"


 if (return 0 2>/dev/null); then
     echo "sourced"
     nstack=1
 else
     echo "not sourced"
     nstack=2
 fi

[[ $SHLVL -gt ${nstack} ]] &&
  echo "called from parent" ||
      echo "called directly"

echo "called by $(ps -o comm= $PPID)"
# print time at exit
echo -en "${TAB}${PSDIR}$(basename $BASH_SOURCE)${NORMAL} "
end_time=$(date +%s%N)
elap_time=$((${end_time}-${start_time}))
dT_sec=$(bc <<< "scale=3;$elap_time/1000000000")
if command -v sec2elap &>/dev/null
then
    echo -n "$(sec2elap $dT_sec | tr -d '\n')" 
else
    echo -n "elapsed time is ${dT_sec} sec"
fi
echo " on $(date +"%a %b %-d at %-l:%M %p %Z")"
