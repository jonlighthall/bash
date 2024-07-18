#!/bin/bash -u
#
# sort_hosts.sh - this script will merge all hosts in known_hosts and sort the
# result
#
# Aug 2023 JCL

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	set_traps
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${RESET}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${RESET} -> $src_name"
fi

# set sort order (C sorting is the most consistient)
# must 'export' setting to take effect
set_loc=C
export LC_COLLATE=$set_loc

# specify default known hosts file
host_ref=${HOME}/.ssh/known_hosts
host_bak=${host_ref}_$(date -r ${host_ref} +'%Y-%m-%d-t%H%M%S')
echo "backup known hosts file"
cp -pv $host_ref ${host_bak}

# set list of files to check
list_in=${host_ref}
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
for host_in in $list_in; do
    echo -n "${host_in}... "
    if [ -f ${host_in} ]; then
        echo -e "is a regular ${UL}file${RESET}"
        list_out+="${host_in} "
        if [ ! ${host_in} -ef ${host_ref} ]; then
            echo "${host_in} is not the same as ${host_ref}"
            list_del+="${host_in} "
        else
            echo "${host_ref} and ${host_in} are the same file"
        fi
    else
        echo -e "${BAD}${UL}does not exist${RESET}"
    fi
done
echo "list out = ${list_out}"
echo "list del = ${list_del}"

echo "list of files:"
for file in $list_out; do
    echo "${TAB}$file"
done

# set output file name
host_out=${host_ref}_merge
list_del+="${host_out} "
echo "output file name is ${host_out}"

# create known hosts file
echo -n "${TAB}concatenate files... "
cat ${list_out} >${host_out}
echo "done"
L=$(cat ${host_out} | wc -l)
echo "${TAB}${TAB} ${host_out} has $L lines"

# clean up whitespace
echo -n "${TAB}delete trailing whitespaces... "
sed -i '/^$/d;s/^$//g;s/[[:blank:]]*$//g' ${host_out}
echo "done"

# sort known hosts
echo -n "${TAB}sorting lines... "
sort -u ${host_out} -o ${host_out}
sort -k3 ${host_out} -o ${host_out}
# create temporary file
host_temp=${host_out}_$(date +'%s')
echo $host_temp
column -t ${host_out} > ${host_temp}
# clean up whitespace
sed -i '/^$/d;s/^$//g;s/[[:blank:]]*$//g' ${host_temp}
mv ${host_temp} ${host_out}
echo "done"
echo -e "${TAB}\E[1;31msorted $L lines in $SECONDS seconds${RESET}"

# print number of differences
N=$(diff --suppress-common-lines -yiEbwB ${host_bak} ${host_out} | wc -l)
echo -e "${TAB}\E[1;31mnumber of differences = $N${RESET}"

cp -Lpv ${host_out} ${host_ref}

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
    echo "${TAB}diffy ${host_bak} ${host_ref}"
    echo "${TAB}en ${host_bak} ${host_ref}"

    diff --color=auto --suppress-common-lines -yiEZbwB ${host_bak} ${host_ref} | sed '/<$/d' | head -n 20
else
    rm -vf $host_bak{,~} 2>/dev/null | sed "s/^/${TAB}/"
fi
