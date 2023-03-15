#!/bin/bash
TAB="   "

# set source and target directories
SRCDIR=$PWD
TGTDIR=$HOME/bin

# check target directory
echo -n "target directory $TGTDIR... "
if [ -d $TGTDIR ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv $TGTDIR
fi

echo "--------------------------------------"
echo "------ Start Linking Repo Files-------"
echo "--------------------------------------"

# list files to be linked
for prog in bell sec2elap whatsup rmbin fix_bad_extensions \
		 unfix_bad_extensions test_file update_repos update_packages \
		 untar clean_mac add_path log ls_test
do
    echo -n "program $SRCDIR/$prog.sh... "
    if [ -e $SRCDIR/$prog.sh ]; then
	echo -n "exists and is "
	if [ -x $SRCDIR/$prog.sh ]; then
	    echo "executable"
	    echo -n "${TAB}link $TGTDIR/${prog}... "
	    if [ -e $TGTDIR/${prog} ] ; then
		echo -n "exists and "
		if [[ $SRCDIR/$prog.sh -ef $TGTDIR/$prog ]]; then
		    echo "already points to ${prog}"
		    echo "${TAB}skipping..."
		    continue
		else
		    echo -n "will be backed up..."
		    mv -v $TGTDIR/${prog} $TGTDIR/${prog}_$(date +'%Y-%m-%d-t%H%M')
		fi
	    else
		echo "does not exist"
	    fi
	    echo -n "${TAB}making link... "
	    ln -sv $SRCDIR/$prog.sh $TGTDIR/$prog
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
