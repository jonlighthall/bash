#!/bin/bash
#
# sort_history.sh - this script will merge all commands in .bash_history with their corresponding
# timestamps, sort the result, and unmerge the sorted list.
#
# JCL Apr 2023

TAB="   "

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
	    list_del+="{hist_in}"
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

# set name of history file to check
hist_in=${hist_ref}_merge

# create history file
cat ${list_out} > ${hist_in}

# set output file name
hist_out=${hist_in}

# delete blank lines
echo "${TAB}delete blank lines..."
sed -i 's/^$//' ${hist_out}
\diff --suppress-common-lines ${hist_in} ${hist_out}

echo "${TAB}delete trailing whitespaces..."
sed -i 's/[[:blank:]]*$//' ${hist_out}

# define random marker functions
function find_marker () {
    \grep -m 1 -n ${marker} ${hist_out}
}

esc=$(printf '\033')

function add_marker () {
    start=33
    end=126
    span=$(( $end - $start + 1 ))
    #    echo "span = $span"
    escape_list="36 42 47 91 92"
    #   echo "list = $escape_list"


    # for N in {33..126}; do
    # 	marker=$(printf '%b' $(printf '\\%03o' $N))
    # 	echo "N = $N ${marker}"
    # 	if [[ ! $escape_list =~ $N ]]; then
    # 	    find_marker | sed "s/${marker}/${esc}[0;44m${marker}${esc}[0m/"
    # 	fi
    # done
    # return

    valid=.false.
    while [ $valid == .false. ]; do
	N_dec=$(($RANDOM % span + start))
	if [[ $escape_list =~ ${N_dec} ]]; then
	    echo "N = ${N_dec} $(printf '%b' $(printf '\\%03o' ${N_dec}))"
	    echo "${N_dec} is in $escape_list"
	    echo "-----------------"
	    echo "finding new value"
	    echo "-----------------"
	else
	    #	    echo $(printf '%b' $(printf '\\%03o' ${N_dec}))
	    #	    printf '%b' $(printf '\\%03o' ${N_dec})
	    #	    echo "${N_dec} is not $escape_list"
	    #	    echo "OK"
	    valid=.true.
	fi
    done
    marker+=$(printf '%b' $(printf '\\%03o' ${N_dec}))
    #    marker+=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 94 + 33))))
    #    marker+=$(printf '%b\n' $(printf '\\%03o' $(($RANDOM % 26 + 65))))
}

function gen_marker () {
    echo "${TAB}generating unique marker..."
    marker=""
    add_marker
    while [[ ! -z $(find_marker) ]]; do
	#   while [[ .true. ]]; do
	echo -ne "${TAB}${TAB}marker = ${marker}\t"
	echo -ne "found     "
	#	esc=$(printf '\033')
	find_marker | sed "s/${marker}/${esc}[0;44m${marker}${esc}[0m/"
	add_marker
    done
    echo -e "${TAB}${TAB}marker = ${marker}\tnot found"
}

# find and mark timestamp lines
gen_marker
TS_MARKER=${marker}
echo "${TAB}mark timestamp lines..."
sed -i "s/^#[0-9]\{10\}.*/&${TS_MARKER}/" ${hist_out}

# remove marks from timestamp lines with no associated commands
echo "${TAB}un-mark childless timestamp lines..."
sed -i ":start;N;s/${TS_MARKER}\n#/\n#/;t start;P;D" ${hist_out}

# merge commands with timestamps
echo "${TAB}merge commands with timestamp lines..."
sed -i ":start;N;s/${TS_MARKER}\n/${TS_MARKER}/;t start;P;D" ${hist_out}

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

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
