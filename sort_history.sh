#!/bin/bash
#
# sort_history.sh - this script will merge all commands in .bash_history with their corresponding
# timestamps, sort the result, and unmerge the sorted list.
#
# JCL Apr 2023

export TAB="   "

# check for reference file
hist_in=${HOME}/.bash_history
hist_out=${hist_in}_edit
echo -n "${hist_in}... "
if [ -f ${hist_in} ]; then
    echo -e "is a regular ${UL}file${NORMAL}"
else
    echo -e "${BAD}${UL}does not exist${NORMAL}"
    exit 1
fi

# copy file
echo "${TAB}copying..."
cp -pv ${hist_in} ${hist_out} | sed "s/^/${TAB}${TAB}/"

# delete blank lines
echo "${TAB}delete blank lines..."
sed -i 's/^$//' ${hist_out}
\diff --suppress-common-lines ${hist_in} ${hist_out}

# find and mark timestamp lines
echo "${TAB}mark timestamp lines..."
sed -i 's/^#[0-9]\{10\}.*/&$$$/' ${hist_out}

# remove marks from timestamp lines with no associated commands
echo "${TAB}un-mark childless timestamp lines..."
sed -i ':start;N;s/\$\$\$\n#/\n#/;t start;P;D' ${hist_out}

# merge commands with timestamps
echo "${TAB}merge commands with timestamp lines..."
sed -i ':start;N;s/\$\$\$\n/$$$/;t start;P;D' ${hist_out}

# mark orphaned lines
echo "${TAB}mark orphaned lines..."
sed -i 's/^[^#]/@@@&/' ${hist_out}

# merge commands with timestamps
echo "${TAB}merge orphaned lines..."
sed -i ':start;N;s/\n@@@/@@@/;t start;P;D' ${hist_out}

# sort history
echo "${TAB}sorting lines..."
sort -u ${hist_out} -o ${hist_out}

# unmerge commands
echo "${TAB}unmerge commands..."
sed -i 's/\$\$\$/\n/;s/@@@/\n/' ${hist_out}

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
