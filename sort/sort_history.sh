#!/bin/bash -u
#
# sort_history.sh - this script will merge all commands in .bash_history with their corresponding
# timestamps, sort the result, and unmerge the sorted list.
#
# Apr 2023 JCL

# get starting time in nanoseconds
start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	  set_traps
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
	  set -T +e
else
    set -e
fi

# print run type and source name
print_source

# define random marker functions
function find_marker() {
    \grep -m 1 -n "${marker}" "$1"
}

function add_marker() {
    valid=.false.
    while [ $valid == .false. ]; do
        N_dec=$(($RANDOM % m_span + m_start))
        if [[ ! $bad_list =~ ${N_dec} ]]; then
            valid=.true.
        fi
    done
    marker+=$(printf '%b' $(printf '\\%03o' ${N_dec}))
}

function gen_marker() {
    echo "${TAB}generating unique marker for $1..."
    marker=''
    add_marker
    line_width=$(($(tput cols) - 1))
    while [[ ! -z $(find_marker "$1") ]]; do
        echo -ne "${TAB}${fTAB}marker = ${marker}\t"
        echo -ne "found\t\t"
        find_marker "$1" | sed "s/${marker}/\x1b[1;31m${marker}\x1b[0m/" | ([[ -z ${TS_MARKER} ]] && cat || sed "s/${TS_MARKER}/\x1b[1;31m\x1b[4m${TS_MARKER}\x1b[0m/") | cut -c -$line_width
        add_marker
    done
    echo -e "${TAB}${fTAB}marker = ${marker}\tnot found"
}

function print_markers() {
    echo -e "${TAB}${UL}marker list${RESET}"
    itab
    # print bad list
    echo "${TAB}bad list:"
    itab
    echo -n "${TAB}"
    for i in ${bad_list}; do
        printf "\\$(printf %03o "$i")"
    done
    echo
    dtab

    # print good list
    echo "${TAB}good list:"
    itab
    echo -n "${TAB}"
    for ((j = $m_start; j <= $m_end; j++)); do
        if [[ ! $bad_list =~ ${j} ]]; then
            printf "\\$(printf %03o "$j")"
        fi
    done
    echo
    dtab 2
}

# set sort order (C sorting is the most consistient)
# must 'export' setting to take effect
set_loc=C
export LC_COLLATE=$set_loc

TS_MARKER=''

#-----------------#
# DON'T BE CLEVER #
#-----------------#

# define marker range
m_start=48
m_end=122
m_span=$(($m_end - $m_start + 1))

# specify forbidden characters
bad_list=$(echo {58..64} {91..96})

# specify default history file
hist_name=.bash_history
hist_ref=${HOME}/${hist_name}
save_dir=${HOME}/home

[ ! -d ${save_dir} ] && save_dir=${HOME}

# if the save directory exists, history should be saved there
hist_save=${save_dir}/${hist_name}

# set output file name
hist_out=${hist_save}_merge

declare hist_bak
unset list_in
set -e
echo -e "${TAB}${UL}check files${RESET}"
itab

if false; then
    # check if the history file is a link
    echo -n "${TAB}${hist_ref} is a "
    if [ -L ${hist_ref} ]; then
        echo -n "link and "
        # check if the link is valid
	      if [ -e ${hist_ref} ]; then
            # check if the link points where we want it
            if [[ "${hist_ref}" -ef "${hist_save}" ]];then
                echo "already points to ${hist_save}"
                # you're done!
            else
		            echo -en "$points to "
		            echo -en "${VALID}valid${RESET} link "
                hist_link=$(reaklink -f ${hist_ref})
                echo "${hist_link}"

                # add link to list
                list_in+=( "${hist_link}")
                # remove bad link
                echo "remove..."
                #rm -v "${hist_ref}"
                # re-link
                # ...
            fi
	      else
		        echo -e "${BROKEN}broken${RESET} ${UL}link${RESET}"
		        echo "${hist_ref} points to ${hist_link}"

            # if link points to the correct location, touch link to create dummy file
		        echo "touching ${hist_link}..."
		        #touch "${hist_link}"
            # otherwise delete link
	      fi
    else
        echo "not a link"
        # check if the original file exits
        if [ -f ${hist_ref} ]; then
		        echo -e "is a regular ${UL}file${RESET}"

            # move and re-link
            echo "linking ${hist_save} to ${hist_ref}"
            do_link "${hist_save}" "${hist_ref}"
        else
		        echo -e "${YELLOW}is not a file or link${RESET}"
		        exit 1
	      fi
    fi

    hist_bak=${save_dir}/$(basename ${hist_ref})_$(date -r ${hist_ref} +'%Y-%m-%d-t%H%M%S')

    echo "${TAB}backup history file..."
    cp -pv $hist_ref ${hist_bak} | sed "s/^/${TAB}${fTAB}/"

else
    # check save directory
    check_target ${save_dir}

    target="${hist_save}"
    link_name="${hist_ref}"

    do_link "${hist_save}" "${hist_ref}"

    source cp_date "${hist_save}" hist_bak

    echo "${TAB}full path: ${hist_bak}"
    echo "${TAB}file name: ${hist_bak##*/}"
    echo "${TAB} set path: ${save_dir}/${hist_bak##*/}"
    hist_bak="${save_dir}/${hist_bak##*/}"
    echo "${TAB}new value: ${hist_bak}"
fi

echo "${TAB}backup file is $hist_bak"

# set list of files to check
list_in+=( "${hist_save}" )
echo "${TAB}${#list_in[@]} files in list"
itab
for file in ${list_in[@]}; do
    echo "${TAB}${file}"
done
dtab

if [ $# -gt 0 ]; then
    echo "${TAB}list of arguments:"
    itab
    for arg in "$@"; do
        echo -n "${TAB}$arg "
        if [ -e $arg ]; then

            if [ $arg -ef $hist_out ]; then
                echo -e "${YELLOW}rename${RESET}"
                itab
                mv_date $arg
                dtab
            else
                echo -e "${GOOD}OK${RESET}"
                list_in+=( "$arg" )
            fi
        else
            echo -e "${BAD}FAIL${RESET}"
        fi
    done
    dtab
fi

if [ ${#list_in[@]} -gt 0 ]; then
    echo "${TAB}list of files (input):"
    itab
    (
        for file in ${list_in[@]}; do
            wc $file
        done
    ) | sort -k1 -n | column -t -N "lines,words,bytes,file" | sed "s/^/${TAB}/"
    dtab
fi

# check list of files
echo "${TAB}checking file list..."
list_out=''
list_del=''
set +e
unset_traps
itab
for hist_in in ${list_in[@]}; do
    echo -n "${TAB}${hist_in}... "
    itab
    if [ -f ${hist_in} ]; then
        echo -e "${GOOD}OK${RESET}"
        decho -e "${TAB}is a regular ${UL}file${RESET}"
        list_out+="${hist_in} "
        if [ ! ${hist_in} -ef ${hist_ref} ]; then
            decho "${TAB}is not the same as ${hist_ref##*/}"
            list_del+="${hist_in} "
        else
            decho -e "${TAB}${YELLOW}is the same file as ${hist_ref##*/}${RESET}"
        fi

        # add check for initial orphaned lines
        (head -n 1 ${hist_in} | grep "#[0-9]\{10\}") >/dev/null
        if [ $? -eq 0 ]; then
            decho "${TAB}starts with timestamp"
        else
            decho -e "${TAB}${YELLOW}DOES NOT start with timestamp${RESET}"
            itab
            decho "${TAB}inserting timestamp..."
            # get next timestamp
            declare -i TS=$(grep "#[0-9]\{10\}" "${hist_in}" -m 1 | sed 's/^#\([0-9]\{10\}\)[ \n].*/\1/' | sed 's/^#//' )
            decho "${TAB}   TS = $TS"
            # generate preceeding timestamp
            preTS=$((TS - 1))
            decho "${TAB}preTS = $preTS"
            # create temporary file
            hist_temp=${hist_in}_$(date +'%s')
            decho "${TAB}$hist_temp"
            echo "#$preTS INSERT MISSING TIMESTAMP" | cat - "${hist_in}" >${hist_temp}
            decho -ne "${TAB}"
            mv -v ${hist_temp} ${hist_in}
            decho "${TAB}done"
            dtab
        fi
    else
        echo -e "${TAB}${BAD}does not exist${RESET}"
    fi
    dtab
done
dtab
set -eE

echo "${TAB}checking for markers..."
declare -i print_ln=3
itab
for hist_in in ${list_in[@]}; do
    echo -n "${TAB}${hist_in}... "

    declare -i nmark=$(grep "^#[0-9]\{10\}[a-zA-Z0-9]\{1,3\}" "${hist_in}" | wc -l)

    if [ $nmark -eq 0 ]; then
        echo -e "${GOOD}OK${RESET}"
    else
        echo -e "${BAD}FAIL${RESET}"
        itab
        echo "${TAB}possible markers detected in $hist_in"
        grep "^#[0-9]\{10\}[a-zA-Z0-9]\{1,3\}" "${hist_in}" -m 1 --color=always | sed "s/^/${TAB}/"

        for ((n = 1; n < 5; n++)); do
            echo "${TAB}checking marker length $n..."
            itab
            declare -i n_mark=$(grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | sed "s/^#[0-9]\{10\}\([a-zA-Z0-9]\{$n\}\).*$/\1/" | sort -n | uniq -c | sort -k1 -n | wc -l)
            echo "${TAB}$n_mark candidates found"

            if [ $n_mark -eq 1 ]; then

                declare imark=$(grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | sed "s/^#[0-9]\{10\}\([a-zA-Z0-9]\{$n\}\).*$/\1/" | sort -n | uniq -c | sort -n | head -1 | awk '{print $2}')
                declare -i cmark=$(grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | sed "s/^#[0-9]\{10\}\([a-zA-Z0-9]\{$n\}\).*$/\1/" | sort -n | uniq -c | sort -n | head -1 | awk '{print $1}')
                echo -e "${TAB}marker candidate is ${GRH}$imark${RESET} with cout $cmark"
            else
                if [ $DEBUG -gt 0 ]; then
                    echo "${TAB}grep: matching lines"
                    itab
                    grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | head -${print_ln} | sed "s/^/${TAB}/"
                    dtab

                    echo "${TAB}sed: markers"
                    itab
                    grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | sed "s/^#[0-9]\{10\}\([a-zA-Z0-9]\{$n\}\).*$/\1/" | head -${print_ln}| sed "s/^/${TAB}/"
                    dtab

                    echo "${TAB}sort"
                    itab
                    grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | sed "s/^#[0-9]\{10\}\([a-zA-Z0-9]\{$n\}\).*$/\1/" | sort -n | head -${print_ln}| sed "s/^/${TAB}/"
                    dtab

                    echo "${TAB}uniq"
                    grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | sed "s/^#[0-9]\{10\}\([a-zA-Z0-9]\{$n\}\).*$/\1/" | sort -n | uniq -c | head -${print_ln}| sed "s/^/${TAB}/"

                    echo "${TAB}sort"
                    grep "^#[0-9]\{10\}[a-zA-Z0-9]\{$n\}" "${hist_in}" | sed "s/^#[0-9]\{10\}\([a-zA-Z0-9]\{$n\}\).*$/\1/" | sort -n | uniq -c | sort -k1 -n -r | head -${print_ln}| sed "s/^/${TAB}/"
                fi

            fi
            dtab
        done
        echo -e "${TAB}marker candidate is ${GRH}$imark${RESET} with cout $cmark in ${hist_in}"

        echo "${TAB}sed -i 's/$imark/\n/g' ${hist_in}"

        read -p "${TAB}Proceed with sed? (y/n) " -n 1 -r -t 15
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sed -i "s/$imark/\n/g" "${hist_in}"
            echo
            echo "done"
        else
            dtab
            echo
            echo "${TAB}exiting..."
            dtab
            exit
        fi
        dtab
    fi
done
dtab

echo "${TAB}list of files (checked):"
itab
for file in $list_out; do
    echo "${TAB}$file"
done
dtab

dtab
echo -e "${TAB}${UL}merge files${RESET}"
itab

# set output file name
list_del+="${hist_out} "
echo -e "${TAB}output file name is ${YELLOW}${hist_out}${RESET}"

# create history file
echo -n "${TAB}concatenate files... "
cat ${list_out} >${hist_out}
echo "done"

dtab

# print good/bad markers
print_markers

sort_TS=$(echo "#$(date +'%s') SORT   $(date +'%a %b %d %Y %R:%S %Z') insert ")

for hist_edit in ${hist_bak} ${hist_out}; do
    # get file length
    L=$(cat ${hist_edit} | wc -l)

    cbar "sorting ${YELLOW}${hist_edit##*/}${RESET}..."
    itab
    echo "${TAB}${hist_edit} has $L lines"
    # clean up whitespace
    echo -n "${TAB}delete trailing whitespaces... "
    sed -i '/^$/d;s/^$//g;s/[[:blank:]]*$//g' ${hist_edit}
    echo "done"

    echo -e "${TAB}${UL}mark timestamps${RESET}"
    itab
    marker_list=''
    # find and mark timestamp lines
    gen_marker "${hist_edit}"
    marker_list+="$marker "
    TS_MARKER=${marker}
    echo -n "${TAB}mark timestamp lines... "
    sed -i "s/^#[0-9]\{10\}.*/&${TS_MARKER}/" ${hist_edit}
    echo "${sort_TS}TS_MARKER ${TS_MARKER}" >>${hist_edit}
    echo "done"

    # remove marks from timestamp lines with no associated commands
    echo -n "${TAB}un-mark childless timestamp lines... "
    sed -i "/${TS_MARKER}/{N; /${TS_MARKER}\n#[0-9]\{10\}/{s/${TS_MARKER}\n#/\n#/}};P;D" ${hist_edit}
    echo "done"

    # merge commands with timestamps
    echo -n "${TAB}merge commands with timestamp lines... "
    sed -i "/${TS_MARKER}/{N; s/${TS_MARKER}\n/${TS_MARKER}/};P;D" ${hist_edit}
    echo "done"

    # find orphaned timestamps
    echo -n "${TAB}remove orphaned timestamp lines... "
    sed -i '/^#[0-9]\{10\}$/d' ${hist_edit}
    echo "done"
    dtab

    echo -e "${TAB}${UL}mark commands${RESET}"
    itab
    # mark orphaned lines
    gen_marker "${hist_edit}"
    marker_list+="$marker "
    OR_MARKER=${marker}
    echo -n "${TAB}mark orphaned lines... "
    sed -i "/^#[0-9]\{10\}.*$/!s/^.*$/${OR_MARKER}&/" ${hist_edit}
    echo "${sort_TS}OR_MARKER ${OR_MARKER}" >>${hist_edit}
    echo "done"

    # merge commands with timestamps
    echo -n "${TAB}merge orphaned lines... "
    sed -i ":start;N;s/\n${OR_MARKER}/${OR_MARKER}/;t start;P;D" ${hist_edit}
    echo "done"
    dtab

    echo -e "${TAB}${UL}mark comments${RESET}"
    itab
    # generate login marker
    echo "${TAB}generate superior/inferior markers... "
    N=${#TS_MARKER}
    echo "${TAB}${fTAB}time stamp marker is $N long"
    beg_mark="!"
    end_mark="~"
    LI_MARKER=$beg_mark
    LO_MARKER=$end_mark
    for ((i = 1; i < $N; i++)); do
        LI_MARKER+="$beg_mark"
        LO_MARKER+="$end_mark"
    done
    echo "${TAB}${fTAB}markers = '$LI_MARKER' '$LO_MARKER'"
    marker_list+=" $LI_MARKER $LO_MARKER"

    # check sort
    echo "${TAB}check sort... "
    LCcol=$(locale -k LC_COLLATE | tail -1 | sed 's/^.*=//' | tr -d '"')
    echo "${TAB}${fTAB}LC_COLLATE = ${set_loc} (${LCcol})"
    echo "${TAB}${fTAB}unsorted:"
    echo $marker_list | xargs -n1 | sed "s/^/${TAB}${fTAB}${fTAB}/"
    echo "${TAB}${fTAB}sorted:"
    echo $marker_list | xargs -n1 | sort -u | sed "s/^/${TAB}${fTAB}${fTAB}/"

    # mark log in/out lines
    echo -n "${TAB}mark superior/inferior lines... "
    head_list="CONTIN INSERT LOGIN"
    tail_list="INDIFF LOGOUT SHUTDN SORT"

    for head in ${head_list}; do
        sed -i "s/ ${head}/${LI_MARKER}${head}/" ${hist_edit}
    done

    for tail in ${tail_list}; do
        sed -i "s/ ${tail}/${LO_MARKER}${tail}/" ${hist_edit}
    done
    echo "done"
    dtab

    echo -e "${TAB}${UL}sort${RESET}"
    itab
    # sort history
    echo -n "${TAB}sorting lines... "
    sort -u ${hist_edit} -o ${hist_edit}
    echo "done"
    echo -e "${TAB}\E[1;31msorted $L lines in $SECONDS seconds${RESET}"
    dtab

    echo -e "${TAB}${UL}clean up ${hist_edit##*/}${RESET}"
    itab
    # unmark log in/out lines
    echo -n "${TAB}unmark login lines... "
    for head in ${head_list}; do
        sed -i "s/${LI_MARKER}${head}/ ${head}/" ${hist_edit}
    done
    for tail in ${tail_list}; do
        sed -i "s/${LO_MARKER}${tail}/ ${tail}/" ${hist_edit}
    done
    echo "done"

    ignore_list=(
        "[a-z]"
        "bg"
        "cd \.\.\/"
        "cd config"
        "cd home"
        "cd ~"
        "clicker"
        "exit"
        "git diff"
        "git fetch"
        "git log"
        "git pull"
        "git push"
        "git status"
        "gita"
        "gitb"
        "gitd"
        "gitl"
        "gitr"
        "gits"
        "gp3"
        "helmholtz"
        "history"
        "l[a-zA-z]"
        "load_libs"
        "make clean"
        "make run"
        "make"
        "pwd"
        "snuffy"
        "up"
        "update_repos"
    )

    for igno in "${ignore_list[@]}"; do
        echo -n "${TAB}${fTAB}deleting ${igno}... "
        sed -i "/${TS_MARKER}${igno}$/d" ${hist_edit}
        sed -i "s/${OR_MARKER}${igno}$//" ${hist_edit}
        echo "done"
    done

    # unmerge commands
    echo -n "${TAB}unmerge commands... "
    sed -i "s/${TS_MARKER}/\n/;s/${OR_MARKER}/\n/g" ${hist_edit}
    echo "done"

    # remove fail-safe marker saves
    sed -i "/^${sort_TS}/d" ${hist_edit}

    dtab 2
    echo -e "${TAB}done sorting ${hist_edit##*/}"
done

echo -e "${TAB}${UL}clean up ${hist_out##*/}${RESET}"
itab

# fix unmatched quotes
echo -n "${TAB}find unmatched quotes... "
sed -i 's/^[^\n\"]*\"[^\"]*$(?!\")/&;\" # unmatched quote SORT/' ${hist_out}
echo "done"

# fix unmatched graves
echo -n "${TAB}find unmatched graves... "
sed -i 's/^[^\n`"]*`[^\n`"]*$/&;` # unmatched grave SORT/' ${hist_out}
echo "done"

# fix unmatched apostrophes
echo -n "${TAB}find unmatched apostrophes... "
sed -i "s/^[^\n'\"\`]*'[^\n'\"\`]*$/&;' # unmatched apostrophe SORT/" ${hist_out}
#sed -i "s/^[^#][^\n'\"]*'[^\n'\"]*$/&;' # unmatched apostrophe SORT" ${hist_out}
#sed -i "s/^[^#\n'\"`]*(?<!\\)'[^\n'\"`]*$/&;' # unmatched apostrophe SORT" ${hist_out}
#sed -i "s/(?!^.*\".*'+.*\".*$)^[^\n']*'[^\n']*$/&;' # unmatched apostrophe SORT/" ${hist_out}
echo "done"

#(?!^.*".*'+.*".*$)^[^\n']*'[^\n']*$ works with quotes
#(?!^.*".*'+.*".*$)(?!^.*`.*'+.*`.*$)^[^\n']*'[^\n']*$ quotes and graves
#(?!^.*".*'+.*".*$)(?!^.*`.*'+.*`.*$)^[^\n']*(?<!\\)'[^\n']*$

# remove repeated lines
echo "${TAB}remove duplicate consecutive lines... "

itab
# set output file name
hist_uni=${hist_ref}_uniq
list_del+="${hist_uni} "
echo "${TAB}output file name is ${hist_uni}"
dtab
#sed '$!N; /^\(.*\)\n\1$/!P; D' ${hist_out}
#perl -0777 -pe 's/(.+\R.+\R)\1/$1/g' ${hist_out}

# select if remove repeated only
if true; then
    # remove consecutive repeated lines
    uniq ${hist_out} > ${hist_uni}
else
    # remove any duplicate lines
    awk '!a[$0]++' ${hist_out} > ${hist_uni}
fi

# check for repeated timestamps
echo "${TAB}reapeated timestamps in ${hist_uni}"
grep "#[0-9]\{10\}" ${hist_uni} | sed 's/ .*$//' | sort -n | uniq -c | sort -k1 -n -r | head -5

# save markers
N=$(diff --suppress-common-lines -yiEbwB ${hist_bak} ${hist_uni} | wc -l)
echo -e "${TAB}\E[1;31mnumber of differences = $N${RESET}"
if [ $N -gt 0 ]; then
    echo "#$(date +'%s') SORT   $(date +'%a %b %d %Y %R:%S %Z') LC_COLLATE = ${set_loc} (${LCcol}) on ${HOSTNAME%%.*} NDIFF=${N}" >>${hist_uni}
    sed -i '/^[[:space:][:blank:]/s/t ]*$/d' ${hist_bak}
    sed -i '/^[[:space:][:blank:]/s/t ]*$/d' ${hist_uni}
fi

echo -n "${TAB}"
cp -Lpv ${hist_uni} ${hist_ref}

dtab

if [[ ! -z ${list_del} ]]; then
    echo "${TAB}removing merged files..."
    for file in ${list_del}; do
        rm -vf $file{,~} 2>/dev/null | sed "s/^/${TAB}${fTAB}/"
    done
fi

# print time at exit
print_exit

if [ $N -gt 0 ]; then
    # show diff commands
    echo -e "\nto compare changes"
    echo "${TAB}${fTAB}diffy ${hist_bak} ${hist_ref}"
    default=$(echo "emacs -nw --eval '(ediff-files ""${hist_bak}"" ""${hist_ref}"")'")
    echo "${TAB}${fTAB}"${default}

    # show diff
    if command -v diffy &>/dev/null; then
        diffy ${hist_bak} ${hist_ref} | sed '/<$/d' | head -n 20
    fi

    # type emacs ediff command
    echo -e "\e[7;33mPress Ctrl-C to cancel\e[0m"
    read -e -i "emacs -nw --eval '(ediff-files \"${hist_bak}\" \"${hist_ref}\")'" -p $'\e[0;32m$\e[0m ' && eval "$REPLY"
fi
