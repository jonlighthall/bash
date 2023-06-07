#!/bin/bash

# set tab
${TAB:=""}

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
echo -e "${TAB}running ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

TAB+=${fTAB:='   '}

# set source and target directories
source_dir=$(dirname "$src_name")
target_dir=$HOME/bin

# check directories
echo -n "source directory ${source_dir}... "
if [ -d "$source_dir" ]; then
    echo "exists"
else
    echo -e "${BAD}does not exist${NORMAL}"
    exit 1
fi

echo -n "target directory ${target_dir}... "
if [ -d $target_dir ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv $target_dir
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
	rmbin \
	sec2elap \
	sort_history \
	test/get_wttr \
	test/test_ls_color \
	test_file \
	unfix_bad_extensions \
	untar \
	update_packages \
	whatsup \
	add_path \
	xtest

do
    target=${source_dir}/${my_link}${ext}
    sub_dir=$(dirname "$my_link")
    if [ ! $sub_dir = "." ]; then
	my_link=$(basename "$my_link")
    fi
    link=${target_dir}/${my_link}

    echo -n "source file ${target}... "
    if [ -e "${target}" ]; then
	echo -n "exists and is "
	if [ -x "${target}" ]; then
	    echo "executable"
	echo -n "${TAB}link ${link}... "
	# first, backup existing copy
	if [ -L ${link} ] || [ -f ${link} ] || [ -d ${link} ]; then
	    echo -n "exists and "
	    if [[ "${target}" -ef ${link} ]]; then
                echo "already points to ${my_link}"
		echo -n "${TAB}"
		ls -lhG --color=auto ${link}
		echo "${TAB}skipping..."
		continue
	    else
		if [ $(diff "${target}" ${link} | wc -c) -eq 0 ]; then
		    echo "have the same contents"
		    continue
		else
		    echo -n "will be backed up..."
		    mv -v ${link} ${link}_$(date -r ${link} +'%Y-%m-%d-t%H%M')
		fi
	    fi
	else
	    echo "does not exist"
	fi
        # then link
	echo -en "${TAB}${GRH}";hline 72;
	echo "${TAB}making link... "
	ln -sv "${target}" ${link} | sed "s/^/${TAB}/"
	echo -ne "${TAB}";hline 72;echo -en "${NORMAL}"
        else
            echo -e "${BAD}not executable${NORMAL}"
        fi
    else
        echo -e "${BAD}does not exist${NORMAL}"
    fi
done
bar 38 "--------- Done Making Links ----------"
TAB=${TAB#$fTAB}
# print time at exit
echo -en "$(date +"%a %b %d %I:%M %p %Z") ${BASH_SOURCE##*/} "
if command -v sec2elap &>/dev/null; then
    echo "$(sec2elap $SECONDS)"
else
    echo "elapsed time is ${SECONDS} sec"
fi
