#!/bin/bash
set -e # exit on non-zero status
T_start=$(date +%s%N)
# print source name at start
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

echo "running ${0}"

if [ "${0}" = "$BASH_SOURCE"  ];then
    echo "0 same as bash source"
    echo "This script is not called by another process."
else
    echo "0 NOT same as bash source"
    echo "This script is called by another process."
fi

echo "running ${0##*/}"
echo "in ${0%/*}"
echo "       PID = $$"
echo "parent PID = $PPID"

[[ $SHLVL -gt 2 ]] &&
    echo "called from parent" ||
	echo "called directly"

echo "called by $(ps -o comm= $PPID)"
echo
echo "calling child process..."
${source_dir}/child.sh
# print time at exit
echo -n "${TAB}$(basename $BASH_SOURCE) "
T_end=$(date +%s%N)
dT_ns=$((${T_end}-${T_start}))
dT_sd=$((dT_ns/1000000000))
dT_sf=$(bc <<< "scale=3;$dT_ns/1000000000")

echo "elapsed time is ${dT_ns} ns"
echo "elapsed time is ${dT_sd} dec sec"
printf "elapsed time is %.3f float sec\n" ${dT_sf}

if command -v sec2elap &>/dev/null
then
    echo "$(sec2elap $dT_sd)"
else
    echo "elapsed time is ${dT_sd} sec"
fi
echo "${TAB}$(date +"%a %b %-d %I:%M %p %Z")"

# echo "goodbye"
# if (return 0 2>/dev/null); then
#     return
# else
#     exit
# fi
