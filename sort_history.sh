#!/bin/bash
#
# sort_history.sh - this script will merge all commands in .bash_history with their corresponding
# timestamps, sort the result, and unmerge the sorted list.
#
# JCL Apr 2023

TAB="   "

# define random marker functions
esc=$(printf '\033')

function find_marker () {
    \grep -m 1 -n ${marker} ${hist_out}
}

function add_marker () {
    start=33
    end=126
    span=$(( $end - $start + 1 ))
    escape_list="36 42 47 91 92"
    valid=.false.
    while [ $valid == .false. ]; do
	N_dec=$(($RANDOM % span + start))
	if [[ ! $escape_list =~ ${N_dec} ]]; then
	    valid=.true.
	fi
    done
    marker+=$(printf '%b' $(printf '\\%03o' ${N_dec}))
}

function gen_marker () {
    echo "${TAB}generating unique marker..."
    marker=""
    add_marker
    while [[ ! -z $(find_marker) ]]; do
	echo -ne "${TAB}${TAB}marker = ${marker}\t"
	echo -ne "found     "
	find_marker | sed "s/${marker}/${esc}[0;44m${marker}${esc}[0m/" | ( [[ -z ${TS_MARKER} ]] && cat || sed "s/${TS_MARKER}/${esc}[4m${TS_MARKER}${esc}[0m/" )
	add_marker
    done
    echo -e "${TAB}${TAB}marker = ${marker}\tnot found"
}

# specify default history file
hist_ref=${HOME}/.bash_history

# set list of files to check
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

# check list of files
list_out=""
list_del=""
for hist_in in $list_in
do
    echo -n "${hist_in}... "
    if [ -f ${hist_in} ]; then
	echo -e "is a regular ${UL}file${NORMAL}"
	list_out+="${hist_in} "
	if [ ! ${hist_in} -ef ${hist_ref} ]; then
	    echo "${hist_in} is not the same as ${hist_ref}"
	    list_del+="${hist_in} "
	else
	    echo "${hist_ref} and ${hist_in} are the same file"
	fi
    else
	echo -e "${BAD}${UL}does not exist${NORMAL}"
    fi
done
echo "list out = ${list_out}"
echo "list del = ${list_del}"

echo "list of files:"
for file in $list_out
do
    echo "${TAB}$file"
done

# set output file name
hist_out=${hist_ref}_merge
#list_del+="${hist_out} "
echo "${TAB}output file name is ${hist_out}"

# create history file
cat ${list_out} > ${hist_out}

# clean up whitespace
echo "${TAB}${TAB}delete trailing whitespaces..."
sed -i 's/^$//;s/[[:blank:]]*$//' ${hist_out}

# find and mark timestamp lines
gen_marker
TS_MARKER=${marker}
echo "${TAB}mark timestamp lines..."
sed -i "s/^#[0-9]\{10\}.*/&${TS_MARKER}/" ${hist_out}

# remove marks from timestamp lines with no associated commands
echo "${TAB}un-mark childless timestamp lines..."
sed -i "/${TS_MARKER}/{N; /${TS_MARKER}\n#[0-9]\{10\}/{s/${TS_MARKER}\n#/\n#/}};P;D" ${hist_out}

# merge commands with timestamps
echo "${TAB}merge commands with timestamp lines..."
sed -i "/${TS_MARKER}/{N; s/${TS_MARKER}\n/${TS_MARKER}/};P;D" ${hist_out}

# mark orphaned lines
gen_marker
OR_MARKER=${marker}
echo "${TAB}mark orphaned lines..."
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

if [[ ! -z ${list_del} ]]; then
    echo "${TAB}removing merged files..."
    rm -v ${list_del}
fi

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
