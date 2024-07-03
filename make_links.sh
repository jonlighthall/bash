#!/bin/bash -u
#
# Jun 2020 JCL

# get starting time in nanoseconds
start_time=$(date +%s%N)

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
fi

# determine if script is being sourced or executed
if ! (return 0 2>/dev/null); then
    # exit on errors
    set -e
fi
print_source

# save and print starting directory
start_dir=$PWD
echo "${TAB}starting directory = ${start_dir}"

# set target and link directories
proj_name=$(basename "${src_dir_phys}")
echo " project directory = $proj_name"
target_dir="${HOME}/utils/${proj_name}"
link_dir=$HOME/bin

cbar "Start Linking Repo Files"
# list of files to be linked
ext=.sh
for my_link in \
    add_path \
    bell \
    clean_mac \
    datetime/cp_date \
    datetime/date_dir \
    datetime/file_age \
    datetime/mv_date \
    datetime/sec2elap \
    find/find_matching \
    find/find_matching_and_move \
    find/find_missing_and_empty \
    git/diff_stash \
    git/filter/filter-repo-author \
    git/force_pull \
    git/gita \
    git/pull_all_branches \
    git/undel_repo \
    git/update_repos \
    log \
    onedrive/fix_bad_extensions \
    onedrive/rm_tracked_bad_extensions \
    onedrive/unfix_bad_extensions \
    onedrive/unsync_repo \
    rm_broken_dupes \
    rmbin \
    sort/sort_history \
    sort/sort_hosts \
    test/get_wttr \
    test/test_file \
    test/test_ls_color \
    test/test_return \
    untar \
    update_packages \
    whatsup \
    xtest \

do
    # define target (source)
    target=${target_dir}/${my_link}${ext}
    # define link name (destination)
    sub_dir=$(dirname "$my_link")
    if [ ! $sub_dir = "." ]; then
        # strip target subdirectory from link name
        my_link=$(basename "$my_link")
    fi
    link=${link_dir}/${my_link}
    # create link
    do_link_exe "${target}" "${link}"
done
cbar "Done Linking Repo Files"

cd $target_dir

# update index
git update-index --skip-worktree git/filter/url.txt

# return to starting directory
cd "$start_dir"
