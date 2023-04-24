#!/bin/bash
echo $BASH_SOURCE
TAB="   "
  GOOD='\033[0;32m'
   BAD='\033[0;31m'
NORMAL='\033[0m'

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

# deinfe horizontal line
hline() {
    for i in {1..38}; do echo -n "-"; done
    echo
}

hline
echo "------ Start Linking Repo Files-------"
hline

# list files to be linked
ext=.sh
for prog in \
    add_path \
    bell \
    clean_mac \
    find_matching \
    find_missing_and_empty \
    fix_bad_extensions \
    git/undel_repo \
    git/update_repos \
    log \
    ls_test \
    rmbin \
    sec2elap \
    sort_history \
    test_file \
    unfix_bad_extensions \
    untar \
    update_packages \
    whatsup \
    xtest \

do
    sub_dir=$(dirname "$prog")
    if [ $sub_dir = "." ]; then
	target=${source_dir}/${prog}${ext}
    else
	target=${source_dir}/${prog}${ext}
	prog=$(basename "$prog")
    fi
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
                    echo -e "${GOOD}already points to ${prog}${NORMAL}"
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
	    hline
	    echo -n "${TAB}making link... "
	    ln -sv $target $link
	    hline
        else
            echo -e "${BAD}not executable${NORMAL}"
        fi
    else
        echo -e"${BAD}does not exist${NORMAL}"
    fi
done
hline
echo "--------- Done Making Links ----------"
hline
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
