# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
print_source

# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch set for current branch"
else
    branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${BLUE}${branch_tracking}${RESET}"
    name_remote=${branch_tracking%%/*}
    echo "remote is name $name_remote"
    url_remote=$(git remote -v | grep ${name_remote} | awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote=${branch_tracking#*/}
    echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${GREEN}${branch_local}${RESET}"

branch_list=$(git branch -va | sed 's/^*/ /' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

git filter-repo $@ --partial --commit-callback '
    # define correct name
    correct_name = b"Jon Lighthall"

    # list emails to replace
    auth_list = [b"jon.lighthall@gmail.com",b"jonlighthall@gmail.com"]
    auth_list.append(b"jlighthall@fsu.edu",b"lighthall@lsu.edu")
    auth_list.append(b"lighthall@elwood.physics.fsu.edu")   
    auth_list.append(b"jonlighthall@users.noreply.github.com")
    auth_list.append(b"jon.lighthall@ygmail.com")

    # load url from file
    text_file = open(os.path.expanduser("~/utils/bash/git/filter/url.txt"), "r")
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
    correct_email = email_bin

    # conditionally replace author email and name
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
'

dtab

# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
