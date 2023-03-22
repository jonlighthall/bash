#!/bin/bash
echo $BASH_SOURCE
TAB="   "

# set source and target directories
source_dir=$PWD
user_bin=$HOME/bin

# check target directory
echo -n "target directory $user_bin... "
if [ -d $user_bin ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv $user_bin
fi

echo "source directory $source_dir"

echo "--------------------------------------"
echo "------ Start Linking Repo Files-------"
echo "--------------------------------------"

# list files to be linked
ext=.sh
for prog in bell sec2elap whatsup rmbin fix_bad_extensions \
		 unfix_bad_extensions test_file update_repos update_packages \
		 untar clean_mac add_path log ls_test xtest
do
    target=${source_dir}/${prog}${ext}
    link=${user_bin}/$prog

    echo -n "program $target... "
    if [ -e $target ]; then
	echo -n "exists and is "
	if [ -x $target ]; then
	    echo "executable"
	    echo -n "${TAB}link $link... "
	    if [ -e $link ] || [ -L $link ] || [ -d $link ] ; then
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
	    echo -n "${TAB}making link... "
	    ln -sv $target $link
	else
	    echo "not executable"
	fi
    else
	echo "does not exist"
    fi
    echo
done
echo "--------------------------------------"
echo "--------- Done Making Links ----------"
echo "--------------------------------------"
