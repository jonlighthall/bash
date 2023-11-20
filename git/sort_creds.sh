#!/bin/bash
#
# sort_creds.sh - this script will merge all credentials in .git_credentials and sort the result
#
# Aug 2023 JCL

set -e
# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

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

# set sort order (C sorting is the most consistient)
# must 'export' setting to take effect
set_loc=C
export LC_COLLATE=$set_loc

# specify default known creds file
cred_ref=${HOME}/.git-credentials
cred_bak=${cred_ref}_$(date -r ${cred_ref} +'%Y-%m-%d-t%H%M%S')
echo "backup known creds file"
cp -pv $cred_ref ${cred_bak}

# set list of files to check
list_in=${cred_ref}
if [ $# -gt 0 ]; then
    list_in+=" $@"
    echo "list of arguments:"
    for arg in "$@"; do
        echo "${TAB}$arg"
    done

    echo "list of files:"
    for file in $list_in; do
        echo "${TAB}$file"
    done
fi

# check list of files
list_out=''
list_del=''
for cred_in in $list_in; do
    echo -n "${cred_in}... "
    if [ -f ${cred_in} ]; then
        echo -e "is a regular ${UL}file${NORMAL}"
        list_out+="${cred_in} "
        if [ ! ${cred_in} -ef ${cred_ref} ]; then
            echo "${cred_in} is not the same as ${cred_ref}"
            list_del+="${cred_in} "
        else
            echo "${cred_ref} and ${cred_in} are the same file"
        fi
    else
        echo -e "${BAD}${UL}does not exist${NORMAL}"
    fi
done
echo "list out = ${list_out}"
echo "list del = ${list_del}"

echo "list of files:"
for file in $list_out; do
    echo "${TAB}$file"
done

# set output file name
cred_out=${cred_ref}_merge
list_del+="${cred_out} "
echo "output file name is ${cred_out}"

# create known creds file
echo -n "${TAB}concatenate files... "
cat ${list_out} >${cred_out}
echo "done"
L=$(cat ${cred_out} | wc -l)
echo "${TAB}${TAB} ${cred_out} has $L lines"

# clean up whitespace
echo -n "${TAB}delete trailing whitespaces... "
sed -i '/^$/d;s/^$//g;s/[[:blank:]]*$//g' ${cred_out}
echo "done"

# sort known creds
echo -n "${TAB}sorting lines... "
sort -u ${cred_out} -o ${cred_out}
echo "done"
echo -e "${TAB}\x1b[1;31msorted $L lines in $SECONDS seconds${NORMAL}"

# print number of differences
N=$(diff --suppress-common-lines -yiEbwB ${cred_bak} ${cred_out} | wc -l)
echo -e "${TAB}\x1b[1;31mnumber of differences = $N${NORMAL}"

cp -Lpv ${cred_out} ${cred_ref}

echo "list del = ${list_del}"

if [[ ! -z ${list_del} ]]; then
    echo "${TAB}removing merged files..."
    for file in ${list_del}; do
        rm -vf $file{,~} 2>/dev/null | sed "s/^/${TAB}/"
    done
fi

# delete backup if no changes were made
if [ "${N}" -gt 0 ]; then
    echo -e "\nto compare changes"
    echo "${TAB}diffy ${cred_bak} ${cred_ref}"
    echo "${TAB}en ${cred_bak} ${cred_ref}"

    diff --color=auto --suppress-common-lines -yiEZbwB ${cred_bak} ${cred_ref} | sed '/<$/d' | head -n 20
else
    rm -vf $cred_bak{,~} 2>/dev/null | sed "s/^/${TAB}/"
fi

# print time at exit
echo -en "$(date +"%a %b %d %-l:%M %p %Z") ${BASH_SOURCE##*/} "
if command -v sec2elap &>/dev/null; then
    sec2elap ${SECONDS}
else
    echo "elapsed time is ${white}${SECONDS} sec${NORMAL}"
fi
