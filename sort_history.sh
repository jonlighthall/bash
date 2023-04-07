#!/bin/bash
#
# Purpose: this script will compare the comntents of of the given input argument against
# .bash_history, append the non-common lines to .bash_history and delte the resulting redundant
# file.
#
# JCL Apr 2023

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
cp -pv ${hist_in} ${hist_out}

# delete blank lines
sed -i 's/^$//'
\diff --suppress-common-lines ${hist_in} ${hist_out}

# find timestamps
sed -i 's/^#[0-9]\{10\}.*/&$$$/' ${hist_out}
