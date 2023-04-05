#!/bin/bash
echo $BASH_SOURCE
TAB="   "

# set source and target directories
source_dir=$PWD
user_bin=$HOME/bin

# check directories
echo "source directory $source_dir..."
if [ -d $source_dir ]; then
    echo "exists"
else
    echo "does not exist"
    return 1
fi

echo -n "target directory $user_bin... "
if [ -d $user_bin ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv $user_bin
fi

echo "--------------------------------------"
echo "------ Start Linking Repo Files-------"
echo "--------------------------------------"

# list files to be linked
ext=.sh
for prog in \
    add_path \
    bell \
    clean_mac \
    find_matching \
    find_missing_and_empty \
    fix_bad_extensions \
    log \
    ls_test \
    merge_history \
    rmbin \
    sec2elap \
    test_file \
    undel_repo \
    unfix_bad_extensions \
    untar \
    update_packages \
    update_repos \
    whatsup \
    xtest \

do
    target=${source_dir}/${prog}${ext}
    link=${user_bin}/${prog}

    echo -n "program $target... "
    if [ -e $target ]; then
        echo -n "exists and is "
        if [ -x $target ]; then
            echo "executable"
            echo -n "${TAB}link $link... "
            # first, backup existing copy
            if [ -L $link ] || [ -f $link ] || [ -d $link ]; then
                echo -n "exists and "
                if [[ $target -ef $link ]]; then
                    echo "already points to ${prog}"
                    echo -n "${TAB}"
                    ls -lhG --color=auto $link
                    echo "${TAB}skipping..."
                    continue
                else
                    echo -n "will be backed up..."
                    mv -v $link ${link}_$(date +'%Y-%m-%d-t%H%M')
                fi
            else
                echo "does not exist"
            fi
            # then link
            echo -n "${TAB}making link... "
            ln -sv $target $link
        else
            echo "not executable"
        fi
    else
        echo "does not exist"
    fi
done
echo "--------------------------------------"
echo "--------- Done Making Links ----------"
echo "--------------------------------------"
# print time at exit
echo -e "\n$(date +"%R) ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"