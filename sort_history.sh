#!/bin/bash -u
#
# sort_history.sh - this script will merge all commands in .bash_history with their corresponding
# timestamps, sort the result, and unmerge the sorted list.
#
# Apr 2023 JCL

# get starting time in nanoseconds
start_time=$(date +%s%N)

# load formatting and functions
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	  set_traps
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
	  RUN_TYPE="sourcing"
	  set -T +e
else
	  RUN_TYPE="executing"
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

# print bad list
echo "${TAB}bad list:"
echo -n "${TAB}${fTAB}"
for i in ${bad_list}; do
    printf "\\$(printf %03o "$i")"
done
echo

# print good list
echo "${TAB}good list:"
echo -n "${TAB}${fTAB}"
for ((j = $m_start; j <= $m_end; j++)); do
    if [[ ! $bad_list =~ ${j} ]]; then
        printf "\\$(printf %03o "$j")"
    fi
done
echo

# specify default history file
hist_name=.bash_history
hist_ref=${HOME}/${hist_name}
save_dir=${HOME}/home
unset list_in

set -e

# check save directory
if [ -d "${save_dir}" ]; then
	  echo "save dir ${save_dir} found"

    # if the save directory exists, history should be saved there
    hist_save=${save_dir}/${hist_name}
    
    # check if the history file is a link
    echo -n "${hist_ref} is a "    
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
                echo "remove"
                #rm -v "${hist_ref}"
                # re-link
                
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
            #hist_temp1=${save_dir}/$(basename ${hist_ref})_$(date -r ${hist_ref} +'%Y-%m-%d-t%H%M%S')
            #list_in+=( "${hist_temp1}" )
            #mv -nv "${hist_ref}" "${hist_temp1}"

            # check if the target exists
            echo -n "intended link name file ${hist_save} "
            if [ -f ${hist_save} ]; then
                echo "exits"                
                hist_temp2=${save_dir}/$(basename ${hist_ref})_$(date -r ${hist_save} +'%Y-%m-%d-t%H%M%S')
                echo "$hist_temp2"
                if [ -e "${hist_temp2}" ]; then
                    echo "backup already exists"
                else
                    echo "does not exist"
                fi

                
                list_in+=( "${hist_temp2}" )
                # move the existing file out of the way
                echo "move link name"
                mv -nv ${hist_save} ${hist_temp2}                
            else
                echo "does not exit"
            fi

            # move and re-link
            echo "move link"
            mv -nv "${hist_ref}" "${hist_save}"
            echo "link target to link"
            ln -sv "${hist_save}" "${hist_ref}"
        else
		        echo -e "${YELLOW}is not a file or link${RESET}"
		        exit 1
	      fi
        
    fi

    hist_bak=${save_dir}/$(basename ${hist_ref})_$(date -r ${hist_ref} +'%Y-%m-%d-t%H%M%S')
    
else
	  echo "save dir ${save_dir} NOT found"

    if [ -f ${hist_ref} ]; then
		    echo -e "is a regular ${UL}file${RESET}"
        hist_bak=${hist_ref}_$(date -r ${hist_ref} +'%Y-%m-%d-t%H%M%S')
    else
		    echo -e "${YELLOW}is not a file or link${RESET}"
		    exit 1
	  fi
fi

echo " backup file is $hist_bak"

echo "backup history file"
cp -pv $hist_ref ${hist_bak} | sed "s/^/${TAB}${fTAB}/"

# set list of files to check
list_in+=( "${hist_ref}" )
echo "${#list_in[@]} files in list"
echo "${list_in[@]}"

if [ $# -gt 0 ]; then
    echo "${TAB}list of arguments:"
    for arg in "$@"; do
        echo "${TAB}${fTAB}$arg"
        list_in+=( "$arg" )
    done
fi

echo "${#list_in[@]} files in list"
echo "${list_in[@]}"
if [ ${#list_in[@]} -gt 0 ]; then
    echo "${TAB}list of files (input):"
    for file in ${list_in[@]}; do
        echo "${TAB}${fTAB}$file"
    done
fi

# check list of files
echo "${TAB}checking file list..."
list_out=''
list_del=''
set +eE
for hist_in in ${list_in[@]}; do
    echo -n "${TAB}${fTAB}${hist_in}... "
    if [ -f ${hist_in} ]; then
        echo -e "is a regular ${UL}file${RESET}"
        list_out+="${hist_in} "
        if [ ! ${hist_in} -ef ${hist_ref} ]; then
            echo "${TAB}${fTAB}${hist_in} is not the same as ${hist_ref}"
            list_del+="${hist_in} "
        else
            echo "${TAB}${fTAB}${hist_ref} and ${hist_in} are the same file"
        fi

        # add check for initial orphaned lines
        (head -n 1 ${hist_in} | grep "#[0-9]\{10\}") >/dev/null
        if [ $? -eq 0 ]; then
            echo "${TAB}${fTAB}${hist_in} starts with timestamp"
        else
            echo "${TAB}${fTAB}${hist_in} DOES NOT start with timestamp"
            # get next timestamp
            TS=$(grep "#[0-9]\{10\}" .bash_history -m 1 | sed 's/^#\([0-9]\{10\}\)[ \n].*/\1/')
            echo "${TAB}   TS = $TS"
            # generate preceeding timestamp
            preTS=$((TS - 1))
            echo "${TAB}preTS = $preTS"
            # create temporary file
            hist_temp=${hist_in}_$(date +'%s')
            echo "${TAB}$hist_temp"
            echo "#$preTS INSERT MISSING TIMESTAMP" | cat - ${hist_in} >${hist_temp}
            mv -v ${hist_temp} ${hist_in}
        fi
    else
        echo -e "${BAD}${UL}does not exist${RESET}"
    fi
done
set -eE
echo "list out = ${list_out}"
echo "list del = ${list_del}"

echo "list of files (checked):"
for file in $list_out; do
    echo "${TAB}${fTAB}$file"
done

# set output file name
hist_out=${hist_ref}_merge
list_del+="${hist_out} "
echo "${TAB}output file name is ${hist_out}"

# create history file
echo -n "${TAB}concatenate files... "
cat ${list_out} >${hist_out}
echo "done"

for hist_edit in ${hist_bak} ${hist_out}; do
    # get file length
    L=$(cat ${hist_edit} | wc -l)
    echo "${TAB}${fTAB}${hist_edit} has $L lines"

    # clean up whitespace
    echo -n "${TAB}delete trailing whitespaces... "
    sed -i '/^$/d;s/^$//g;s/[[:blank:]]*$//g' ${hist_edit}
    echo "done"

    marker_list=''
    # find and mark timestamp lines
    gen_marker "${hist_edit}"
    marker_list+="$marker "
    TS_MARKER=${marker}
    echo -n "${TAB}mark timestamp lines... "
    sed -i "s/^#[0-9]\{10\}.*/&${TS_MARKER}/" ${hist_edit}
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

    # mark orphaned lines
    gen_marker "${hist_edit}"
    marker_list+="$marker "
    OR_MARKER=${marker}
    echo -n "${TAB}mark orphaned lines... "
    sed -i "/^#[0-9]\{10\}.*$/!s/^.*$/${OR_MARKER}&/" ${hist_edit}
    echo "done"

    # merge commands with timestamps
    echo -n "${TAB}merge orphaned lines... "
    sed -i ":start;N;s/\n${OR_MARKER}/${OR_MARKER}/;t start;P;D" ${hist_edit}
    echo "done"

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

    # sort history
    echo -n "${TAB}sorting lines... "
    sort -u ${hist_edit} -o ${hist_edit}
    echo "done"
    echo -e "${TAB}\E[1;31msorted $L lines in $SECONDS seconds${RESET}"

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
        "bg"
        "cd \.\.\/"
        "exit"
        "git diff"
        "git log"
        "git pull"
        "git push"
        "git status"
        "gitb"
        "gitd"
        "gitl"
        "gitr"
        "gits"
        "history"
        "la"
        "ls"
        "lt"
        "make"
        "make clean"
        "make run"
        "pwd"
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
done

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

# save markers
N=$(diff --suppress-common-lines -yiEbwB ${hist_bak} ${hist_out} | wc -l)
echo -e "${TAB}\E[1;31mnumber of differences = $N${RESET}"
echo "#$(date +'%s') SORT   $(date +'%a %b %d %Y %R:%S %Z') using markers ${TS_MARKER} ${OR_MARKER} LC_COLLATE = ${set_loc} (${LCcol}) on ${HOSTNAME%%.*} NDIFF=${N}" >>${hist_out}

cp -Lpv ${hist_out} ${hist_ref}

echo "list del = ${list_del}"

if [[ ! -z ${list_del} ]]; then
    echo "${TAB}removing merged files..."
    for file in ${list_del}; do
        rm -vf $file{,~} 2>/dev/null | sed "s/^/${TAB}${fTAB}/"
    done
fi

# print time at exit
print_elap

echo -e "\nto compare changes"
echo "${TAB}${fTAB}diffy ${hist_bak} ${hist_ref}"
default=$(echo "emacs -nw --eval '(ediff-files ""${hist_bak}"" ""${hist_ref}"")'")
echo "${TAB}${fTAB}"${default}

if command -v diffy &>/dev/null; then
    diffy ${hist_bak} ${hist_ref} | sed '/<$/d' | head -n 20
fi

echo -e "\e[7;33mPress Ctrl-C to cancel\e[0m"
read -e -i "emacs -nw --eval '(ediff-files \"${hist_bak}\" \"${hist_ref}\")'" -p $'\e[0;32m$\e[0m ' && eval "$REPLY"

