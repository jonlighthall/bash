#!/bin/bash
#
# sort_history.sh - this script will merge all commands in .bash_history with their corresponding
# timestamps, sort the result, and unmerge the sorted list.
#
# JCL Apr 2023

set -e
# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
echo "${TAB}running $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# set sort order (desired results with UTF-8 binary sort order)
#LC_ALL=en_US.UTF-8
LC_ALL=C

# define random marker functions
function find_marker () {
    \grep -m 1 -n ${marker} ${hist_out}
}

function add_marker () {
    start=48
    end=122
    span=$(( $end - $start + 1 ))
    bad_list=$(echo -n {58..64} echo {91..96})
    valid=.false.
    while [ $valid == .false. ]; do
	N_dec=$(($RANDOM % span + start))
	if [[ ! $bad_list =~ ${N_dec} ]]; then
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
	find_marker | sed "s/${marker}/\x1b[1;31m${marker}\x1b[0m/" | ( [[ -z ${TS_MARKER} ]] && cat || sed "s/${TS_MARKER}/\x1b[1;31m\x1b[4m${TS_MARKER}\x1b[0m/" )
	add_marker
    done
    echo -e "${TAB}${TAB}marker = ${marker}\tnot found"
}

# specify default history file
hist_ref=${HOME}/.bash_history
hist_bak=${hist_ref}_$(date +'%Y-%m-%d-t%H%M%S')
cp -pv $hist_ref ${hist_bak}

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
list_del+="${hist_out} "
echo "output file name is ${hist_out}"

# create history file
echo -n "${TAB}concatenate files... "
cat ${list_out} > ${hist_out}
echo "done"

# clean up whitespace
echo -n "${TAB}delete trailing whitespaces... "
sed -i '/^$/d;s/^$//g;s/[[:blank:]]*$//g' ${hist_out}
echo "done"

# find and mark timestamp lines
gen_marker
TS_MARKER=${marker}
echo -n "${TAB}mark timestamp lines... "
sed -i "s/^#[0-9]\{10\}.*/&${TS_MARKER}/" ${hist_out}
echo "done"

# remove marks from timestamp lines with no associated commands
echo -n "${TAB}un-mark childless timestamp lines... "
sed -i "/${TS_MARKER}/{N; /${TS_MARKER}\n#[0-9]\{10\}/{s/${TS_MARKER}\n#/\n#/}};P;D" ${hist_out}
echo "done"

# merge commands with timestamps
echo -n "${TAB}merge commands with timestamp lines... "
sed -i "/${TS_MARKER}/{N; s/${TS_MARKER}\n/${TS_MARKER}/};P;D" ${hist_out}
echo "done"

# find orphaned timestamps
echo -n "${TAB}remove orphaned timestamp lines... "
sed -i '/^#[0-9]\{10\}$/d' ${hist_out}
echo "done"

# mark orphaned lines
gen_marker
OR_MARKER=${marker}
echo -n "${TAB}mark orphaned lines... "
sed -i "s/^[^#]/${OR_MARKER}&/" ${hist_out}
echo "done"

# merge commands with timestamps
echo -n "${TAB}merge orphaned lines... "
sed -i ":start;N;s/\n${OR_MARKER}/${OR_MARKER}/;t start;P;D" ${hist_out}
echo "done"

# mark log in/out lines
echo "${TAB}mark login lines... "
N=${#TS_MARKER}
echo "${TAB}${TAB}time stamp marker is $N long"
LI_MARKER="~"
LO_MARKER="Z"
for ((i=1;i<$N;i++))
do
    LI_MARKER+="~"
    LO_MARKER+="Z"
done
echo "${TAB}${TAB}markers = $LI_MARKER, $LO_MARKER"
MARKERS=$"$TS_MARKER $OR_MARKER $LI_MARKER $LO_MARKER"

locale

echo "${TAB}${TAB}unsorted:"
echo $MARKERS | xargs -n1 | sed "s/^/${TAB}${TAB}${TAB}/"
echo "${TAB}${TAB}sorted:"
echo $MARKERS | xargs -n1 | sort -u | sed "s/^/${TAB}${TAB}${TAB}/"
sed -i "s/ LOGIN/${LI_MARKER}LOGIN/;s/ LOGOUT/${LO_MARKER}LOGOUT/" ${hist_out}

# sort history
echo -n "${TAB}sorting lines... "
sort -u ${hist_out} -o ${hist_out}
echo "done"

echo -n "${TAB}unmark login lines... "
sed -i "s/${LI_MARKER}LOGIN/ LOGIN/;s/${LO_MARKER}LOGOUT/ LOGOUT/" ${hist_out}
echo "done"

# unmerge commands
echo -n "${TAB}unmerge commands... "
sed -i "s/${TS_MARKER}/\n/;s/${OR_MARKER}/\n/g" ${hist_out}
echo "done"

# save markers
echo "#$(date +'%s') SORT $(date +'%a %b %d %Y %R:%S %Z') using markers ${TS_MARKER} ${OR_MARKER} (LC_ALL = ${LC_ALL})" >> ${hist_out}

cp -Lpv ${hist_out} ${hist_ref}

echo "list del = ${list_del}"

if [[ ! -z ${list_del} ]]; then
    echo "${TAB}removing merged files..."
    for file in ${list_del}
    do
	rm -vf $file{,~} 2>/dev/null | sed "s/^/${TAB}/"
    done
fi

# print time at exit
echo -en "$(date +"%R") ${BASH_SOURCE##*/} "
if command -v sec2elap &>/dev/null; then
    echo "$(sec2elap $SECONDS)"
else
    echo "elapsed time is ${SECONDS} sec"
fi

echo -e "\nto compare changes"
echo "${TAB}en ${hist_ref} ${hist_bak}"
