#!/bin/bash
#
# sort_history.sh - this script will merge all commands in .bash_history with their corresponding
# timestamps, sort the result, and unmerge the sorted list.
#
# JCL Apr 2023

TAB="   "

# check for reference file
hist_ref=${HOME}/.bash_history

list_in=${hist_ref}

if [ $# -gt 0 ]; then
    list_in+=" $@"
    echo "list of arguments:"
    for arg in "$@"
    do
	echo "${TAB}$arg"
    done

    echo "list of files:"
    for file in $list_in
    do
	echo "${TAB}$file"
    done
fi

list_out=""
for hist_in in $list_in
do
    echo -n "${hist_in}... "
    if [ -f ${hist_in} ]; then
	echo -e "is a regular ${UL}file${NORMAL}"
	list_out+="${hist_in} "
    else
	echo -e "${BAD}${UL}does not exist${NORMAL}"
    fi
done
echo "list out = ${list_out}"

echo "list of files:"
for file in $list_out
do
    echo "${TAB}$file"
done

hist_in=${hist_ref}_merge

cat ${list_out} > ${hist_in}

hist_out=${hist_in}

# delete blank lines
echo "${TAB}delete blank lines..."
sed -i 's/^$//' ${hist_out}
\diff --suppress-common-lines ${hist_in} ${hist_out}

# find unique marker
function find_marker () {
    \grep -m 1 $marker ${hist_out}
}

function add_marker () {
    marker+=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 26 + 65))))
}

function gen_marker () {
    marker=""
    echo "marker = $marker"
    add_marker
    echo "marker = $marker"
    while [[ ! -z $(find_marker) ]]; do
	if [[ -z $(find_marker) ]]; then
	    echo "true"
	    echo "$marker not found"
	else
	    echo "false"
	    echo "$marker found:"
	    find_marker | sed "s/$marker.*/$marker.../"
	fi
	add_marker
    done
}

echo "finding marker"
marker=""
for n in {1..5}; do
    marker+=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 26 + 65))))
    echo -n "trying $marker..."
    if [[ -z $(\grep -m 1 $marker ${hist_out}) ]]; then
	echo "not found"
	break
    else
	echo -e "found\n${TAB}\c"
	\grep -m 1 $marker ${hist_out}
    fi
done
echo -e "${marker} is not found\n"

marker=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 26 + 65))))
while [[ ! -z $(\grep -m 1 $marker ${hist_out}) ]]; do
    echo "trying $marker..."
    \grep -m 1 $marker ${hist_out}
    marker+=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 26 + 65))))
done

echo "marker = $marker"

echo "test functions"
gen_marker
echo "marker = $marker"

# find and mark timestamp lines
echo "${TAB}mark timestamp lines..."

TS_MARKER=$marker
sed -i "s/^#[0-9]\{10\}.*/&${TS_MARKER}/" ${hist_out}

# remove marks from timestamp lines with no associated commands
echo "${TAB}un-mark childless timestamp lines..."
sed -i ":start;N;s/${TS_MARKER}\n#/\n#/;t start;P;D" ${hist_out}

# merge commands with timestamps
echo "${TAB}merge commands with timestamp lines..."
sed -i ":start;N;s/${TS_MARKER}\n/${TS_MARKER}/;t start;P;D" ${hist_out}

# mark orphaned lines
echo "${TAB}mark orphaned lines..."
marker=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 26 + 65))))
while [[ ! -z $(\grep -m 1 $marker ${hist_out}) ]]; do
    marker+=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 26 + 65))))
done
OR_MARKER=$marker
sed -i "s/^[^#]/${OR_MARKER}&/" ${hist_out}

# merge commands with timestamps
echo "${TAB}merge orphaned lines..."
sed -i ":start;N;s/\n${OR_MARKER}/${OR_MARKER}/;t start;P;D" ${hist_out}

# sort history
echo "${TAB}sorting lines..."
sort -u ${hist_out} -o ${hist_out}

# unmerge commands
echo "${TAB}unmerge commands..."
sed -i "s/${TS_MARKER}/\n/" ${hist_out}
sed -i "s/${OR_MARKER}/\n/" ${hist_out}

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"