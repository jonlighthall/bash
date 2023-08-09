#!/bin/bash
set -e # exit on non-zero status
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
# print time at exit
echo -e "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
