#!/bin/bash -u

# get starting time in nanoseconds
start_time=$(date +%s%N)

# set tab
:${TAB:=''}

# load formatting
fpretty="${HOME}/utils/bash/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
# print source name at start
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f "$BASH_SOURCE")
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# set target and link directories
target_dir=$(dirname "$src_name")
link_dir=$HOME/bin

# check directories
echo -n "target directory ${target_dir}... "
if [ -d "$target_dir" ]; then
    echo "exists"
else
    echo -e "${BAD}does not exist${NORMAL}"
    exit 1
fi

echo -n "link directory ${link_dir}... "
if [ -d "$link_dir" ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv "$link_dir"
fi

bar 38 "------ Start Linking Repo Files-------"

# list of files to be linked
ext=.sh
for my_link in \
    bell \
    clean_mac \
    file_age \
    find_matching \
    find_matching_and_move \
    find_missing_and_empty \
    fix_bad_extensions \
    git/filter-repo-author \
    git/force_pull \
    git/gita \
    git/pull_all_branches \
    git/undel_repo \
    git/update_repos \
    log \
    mv_date \
    rmbin \
    sec2elap \
    sort_history \
    sort_hosts \
    test/get_wttr \
    test/test_ls_color \
    test_file \
    unfix_bad_extensions \
    untar \
    update_packages \
    whatsup \
    add_path \
    xtest; do
    # define target (source)
    target=${target_dir}/${my_link}${ext}
    # define link (destination)
    sub_dir=$(dirname "$my_link")
    if [ ! $sub_dir = "." ]; then
        # strip target subdirectory from link name
        my_link=$(basename "$my_link")
    fi
    link=${link_dir}/${my_link}

    # check if target exists
    echo -n "target file ${target}... "
    if [ -e "${target}" ]; then
        echo "exists "

        # next, check file permissions
        if true; then
            echo -n "${TAB}${target##*/} requires specific permissions: "
            permOK=500
            echo "${permOK}"
            TAB+=${fTAB:='   '}
            echo -n "${TAB}checking permissions... "
            perm=$(stat -c "%a" "${target}")
            echo ${perm}
            # the target files will have the required permissions added to the existing permissions
            if [[ ${perm} -le ${permOK} ]] || [[ ! (-f "${target}" && -x "${target}") ]]; then
                echo -en "${TAB}${GRH}adding permissions${NORMAL} to ${permOK}... "
                chmod +${permOK} "${target}" || chmod u+rx "${target}"
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    echo -e "${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
                else
                    echo -e "${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
                fi
            else
                echo -e "${TAB}permissions ${GOOD}OK${NORMAL}"
            fi
            TAB=${TAB%$fTAB}
        fi

        # begin linking...
        echo -n "${TAB}link ${link}... "
        TAB+=${fTAB:='   '}
        # first, check for existing copy
        if [ -L "${link}" ] || [ -f "${link}" ] || [ -d "${link}" ]; then
            echo -n "exists and "
            if [[ "${target}" -ef "${link}" ]]; then
                echo "already points to ${my_link}"
                echo -n "${TAB}"
                ls -lhG --color=auto "${link}"
                echo "${TAB}skipping..."
                TAB=${TAB%$fTAB}
                continue
            else
                # next, delete or backup existing copy
                if [ $(diff -ebwB "${target}" "${link}" 2>&1 | wc -c) -eq 0 ]; then
                    echo "has the same contents"
                    echo -n "${TAB}deleting... "
                    rm -v "${link}"
                else
                    if [ -e "${link}" ]; then
                        echo "will be backed up..."
                        mdate=$(date -r "${link}" +'%Y-%m-%d-t%H%M')
                    else
                        echo -n "is a broken link..."
                        mdate=$(stat -c '%y' ${in_file} | sed 's/\(^[0-9-]*\) \([0-9:]*\)\..*$/\1-t\2/' | sed 's/://g')
                    fi
                    link_copy="${link}_${mdate}"
                    mv -v "${link}" "${link_copy}" | sed "s/^/${TAB}/"
                fi
            fi
        else
            echo "does not exist"
        fi
        # then link
        echo -en "${TAB}${GRH}"
        hline 72
        echo "${TAB}making link... "
        ln -sv "${target}" "${link}" | sed "s/^/${TAB}/"
        echo -ne "${TAB}"
        hline 72
        echo -en "${NORMAL}"
        TAB=${TAB%$fTAB}
    else
        echo -e "${BAD}does not exist${NORMAL}"
    fi
done
bar 38 "--------- Done Making Links ----------"

git update-index --skip-worktree git/url.txt
