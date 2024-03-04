#!/bin/bash -u

# get starting time in nanoseconds
start_time=$(date +%s%N)

utils_dir="${HOME}/utils"
bash_utils_dir="${utils_dir}/bash"

# load formatting
fpretty="${bash_utils_dir}/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
    # reset tab
    rtab
fi

# load linking scripts
flink="${bash_utils_dir}/.bash_links"
if [ -e "$flink" ]; then
    source "$flink"
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
# exit on errors
    set -e
fi
# print source name at start
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f "$BASH_SOURCE")
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# set target and link directories
src_dir_logi=$(dirname "$src_name")
proj_name=$(basename "$src_dir_logi")
target_dir="${utils_dir}/${proj_name}"
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

bar 38 "------ Start Linking Repo Files ------"

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

    # create link
    do_link_exe "$target" "$link"
done
bar 38 "--------- Done Making Links ----------"

# save and print starting directory
start_dir=$PWD
echo "starting directory = ${start_dir}"
cd $target_dir
git update-index --skip-worktree git/url.txt
cd $start_dir