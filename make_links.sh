#!/bin/bash

# print source name at start
echo -n "source: $BASH_SOURCE"
src_name=$(readlink -f $BASH_SOURCE)
if [ "$BASH_SOURCE" = "$src_name" ]; then
    echo
else
    echo " -> $src_name"
fi

# source formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# set source and target directories
source_dir=$(dirname "$src_name")
user_bin=$HOME/bin

# check directories
echo "source directory $source_dir..."
if [ -d "$source_dir" ]; then
    echo "exists"
else
    echo -e "${BAD}does not exist${NORMAL}"
    exit 1
fi

echo -n "target directory $user_bin... "
if [ -d $user_bin ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv $user_bin
fi

bar 38 "------ Start Linking Repo Files-------"

# list files to be linked
ext=.sh
for prog in \
    add_path \
    bell \
    clean_mac \
    find_matching \
    find_missing_and_empty \
    fix_bad_extensions \
    git/filter-repo-author \
    git/force_pull \
    git/gita \
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
    xtest 

do
    target=${source_dir}/${prog}${ext}
    sub_dir=$(dirname "$prog")
    if [ ! $sub_dir = "." ]; then
	prog=$(basename "$prog")
    fi
    link=${user_bin}/${prog}

    echo -n "program $target... "
    if [ -e "$target" ]; then
	echo -n "exists and is "
	if [ -x "$target" ]; then
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
	    echo -en "${TAB}${GRH}";hline 72;
	    echo "${TAB}making link... "
	    ln -sv $target $link | sed "s/^/${TAB}/"
	    echo -ne "${TAB}";hline 72;echo -en "${NORMAL}"
        else
            echo -e "${BAD}not executable${NORMAL}"
        fi
    else
        echo -e "${BAD}does not exist${NORMAL}"
    fi
done
bar 38 "--------- Done Making Links ----------"
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
