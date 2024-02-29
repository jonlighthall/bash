# set tab
if [ ! -z $TAB ]; then
    fTAB="   "
    TAB+=$fTAB
fi

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    if [ -z ${fpretty_loaded+dummy} ];then
        source $fpretty
    fi
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    set -eE
    trap 'echo -e "${BAD}ERROR${NORMAL}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch set for current branch"
else
    branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${blue}${branch_tracking}${NORMAL}"
    name_remote=${branch_tracking%%/*}
    echo "remote is name $name_remote"
    url_remote=$(git remote -v | grep ${name_remote} | awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote=${branch_tracking#*/}
    echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${green}${branch_local}${NORMAL}"

branch_list=$(git branch -va | sed 's/^*/ /' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

git filter-repo $@ --partial --commit-callback '
    # define correct name
    correct_name = b"Jon Lighthall"

    # list emails to replace
    auth_list = [b"jlighthall@fsu.edu",b"jon.lighthall@gmail.com",b"lighthall@lsu.edu",b"jonlighthall@gmail.com"]
    auth_list.append(b"jonlighthall@users.noreply.github.com")
    auth_list.append(b"jon.lighthall@ygmail.com")

    # load url from file
    text_file = open(os.path.expanduser("~/utils/bash/git/url.txt"), "r")
    url = text_file.read()
    text_file.close()

    # add emails with url from files
    email_str="jonathan.c.lighthall@"+url.strip()
    email_bin=email_str.encode("ascii")	
    auth_list.append(email_bin)
    email_str="jlighthall@snuffleupagus."+url.strip()
    email_bin=email_str.encode("ascii")	
    auth_list.append(email_bin)   

    # define correct email
    email_str="jonathan.lighthall@"+url.strip()
    email_bin=email_str.encode("ascii")	
    auth_list.append(email_bin)
    correct_email = email_bin

    # conditionally replace author email and name
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
'

TAB=${TAB#$fTAB}

# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
