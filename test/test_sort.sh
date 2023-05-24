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

# define random marker functions
function find_marker () {
    \grep -m 1 -n "${marker}" ${hist_out}
}

function add_marker () {
    start=48
    end=122
    span=$(( $end - $start + 1 ))
    bad_list=$(echo -n {58..64}; echo " "; echo {91..96})
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
	echo -ne "found\t\t"
	find_marker | sed "s/${marker}/\x1b[1;31m${marker}\x1b[0m/" | ( [[ -z ${TS_MARKER} ]] && cat || sed "s/${TS_MARKER}/\x1b[1;31m\x1b[4m${TS_MARKER}\x1b[0m/" )
	add_marker
    done
    echo -e "${TAB}${TAB}marker = ${marker}\tnot found"
}

# specify default history file
hist_out=${HOME}/.bash_history

mark_list=""
N=0
# find and mark timestamp lines
for ((i=1;i<=5;i++))
do
    gen_marker
    marker_list+="$marker "
    echo "${TAB}${TAB}marker list: $marker_list"
    iN=${#marker}
    # determine longest marker
    if [ $iN -gt $N ]; then
	N=${iN}
    fi
done

# generate login marker
echo "${TAB}${TAB}time stamp marker is $N long"
LI_MARKER="!"
LO_MARKER="Z"
for ((i=1;i<$N;i++))
do
    LI_MARKER+="$LI_MARKER"
    LO_MARKER+="$LO_MARKER"
done
echo "${TAB}${TAB}markers = '$LI_MARKER' '$LO_MARKER'"
bad_list="36 42 45 46 47 91 92 94"
echo
echo "bad list:"
for i in ${bad_list}
do
    echo -n "${TAB}${TAB}"
    printf "%03d: \\$(printf %03o "$i")\n" "$i"
done
echo
good_list=$(echo -n {32..48}; echo " "; echo {57..65}; echo " "; echo {90..97}; echo " "; echo {122..126})
echo "good list:"
for ((j=32;j<=126;j++))
do
    marker=""
    if [[ ! $bad_list =~ ${j} ]]; then
	for ((i=1;i<=$N;i++))
	do
	    marker+=$(printf "\\$(printf %03o "$j")")
	done
	echo -n "${TAB}${TAB}"
	printf "%03d: %s\t\t" "$j" "$marker"
	if [[ -z $(find_marker) ]]; then
	    echo "not found"
	else
	    echo -ne "grep:\t\t"
	    find_marker | sed "s/${marker}/\x1b[1;47;31m${marker}\x1b[0m/"
	    sed -n -e "s/${marker}/\x1b[1;47;31m${marker}\x1b[0m/p" ${hist_out} | sed "s/^/${TAB}${TAB}\t\t\tsed:\t\t/" | head -1
	fi
	if [[ $good_list =~ ${j} ]]; then
	    marker_list+=" $marker"
	fi
    fi
done

# check sort
echo "${TAB}check sort... "
marker_list+=" $LI_MARKER $LO_MARKER"
echo "${TAB}${TAB}unsorted:"
echo $marker_list | tr ' ' '\n'

k=0
loc_list=$(locale -a)
echo "list of locales:"
echo "$loc_list" | sed "s/^/${TAB}/"
set +e
for isort in $loc_list
do
    export LC_COLLATE=${isort}
    LCcol=$(locale -k LC_COLLATE | tail -1 | sed 's/^.*=//' | tr -d '"')
    ((k++))
    echo
    echo "k=$k"
    echo "${TAB}${TAB}LC_COLLATE = $(echo $loc_list | awk '{print $'$k'}') (${LCcol})"

    echo "${TAB}${TAB}sorted:"
    sort -u <( echo $marker_list | tr ' ' '\n' )
done

# print time at exit
echo -en "$(date +"%R") ${BASH_SOURCE##*/} "
if command -v sec2elap &>/dev/null; then
    echo "$(sec2elap $SECONDS)"
else
    echo "elapsed time is ${SECONDS} sec"
fi
