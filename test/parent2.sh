#!/bin/bash -ueE

# get source name
declare src_name=$(readlink -f $BASH_SOURCE)
# get source path
declare src_dir_phys=$(dirname "${src_name}")
declare src_dir_logi=$(dirname "${BASH_SOURCE}")
# get starting directory
declare start_dir=$PWD

# load bash utilities
fpretty="${src_dir_phys}/alias.sh"
echo -n "$fpretty..."
if [ -e "$fpretty" ]; then
	echo "found"
    source "$fpretty"
	get_start
	echo ${start_time}
else
	echo "not found"
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi

# print run type and source name
echo -e "${RUN_TYPE} $BASH_SOURCE..."

if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "link -> $src_name"
fi

# print source path
echo -e "phys -> $src_dir_phys"
echo -e "logi -> $src_dir_logi"

# print starting directory
echo "starting directory = ${start_dir}"

echo "you're done!"

set_traps

# add exit code for parent script
if (return 0 2>/dev/null); then
	return 0
	unset src_name
	unset src_dir_phys
	unset src_dir_logi
	unset start_dir	
else
	exit 0
fi

