# get canonical source name
src_name=$(readlink -f "${BASH_SOURCE[0]}")

# get canonical (physical) source path
src_dir_phys=$(dirname "$src_name")

# load git utils
for util in check_repos.sh; do
    # use the canonical (physical) source directory for reference; this is important if sourcing
    # this file directly from shell
    fname="${src_dir_phys}/${util}"
    echo "${TAB}loading $(basename "${fname}")... "    
    if [ -e "${fname}" ]; then
        source "${fname}"
    else
        echo "${BAD}not found"
    fi
done

function check_git() {
    # check if Git is defined
    if [ -z "${check_git:+dummy}" ]; then
        echo -n "${TAB}Checking Git... "
        if command -v git &>/dev/null; then
            echo -e "${GOOD}OK${RESET} Git is defined"
            # parse Git version
            export git_ver=$(git --version | awk '{print $3}')
            export git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
            export git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
            export git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')
            export check_git=false
        else
            echo -e "${BAD}FAIL${RESET} Git not defined"
            if (return 0 2>/dev/null); then
                return 1
            else
                exit 1
            fi
        fi
    fi
    echo "git v${git_ver}"
}

# set DEBUG color
function set_dcolor() {
    # get value of DEBUG
    # if unset or NULL, substitue default
    local -i DEBUG=${DEBUG-0}
    define index
    local -i idx
    # get color index
    dbg2idx $DEBUG idx
    # set color
    echo -ne "${dcolor[$idx]}"
}

# set BASH color
function set_bcolor() {
    # get length of call stack
    local -i N_BASH=${#BASH_SOURCE}
    define index
    local -i idx
    # get color index
    dbg2idx $N_BASH idx
    # set color
    echo -ne "${dcolor[$idx]}"
}

function set_color() {
    # get color index
    local -i idx
    dbg2idx 3 idx
    # set color
    echo -ne "${dcolor[$idx]}"
}

function unset_color() {
    echo -ne "\e[0m"
}

function do_cmd() {
    cmd=$(echo $@)
    itab
    set_color
    $cmd 2> >(sed "s/.*/${TAB}&/")
    RETVAL=$?
    unset_color
    dtab
    return $RETVAL
}

function exit_on_fail() {
    echo -e "       ${yellow}\x1b[7m${BASH_SOURCE[1]##*/} failed\x1b[0m"
    local do_exit=true
    if [[ $do_exit == true ]]; then
        exit 1 || return 1
    else
        return 0
    fi
}

function check_mod() {
    # check for modified files
    local list_mod=$(git diff --name-only --diff-filter=M)
    if [[ ! -z "${list_mod}" ]]; then
        # print file list
        echo -e "modified: ${yellow}"
        echo "${list_mod}" | sed "s/^/${fTAB}/"
        echo -en "${RESET}"
        # add repo to list
        mod_repos+="$repo "
        # add to files to list
        if [ ! -z ${mod_files:+dummy} ]; then
            mod_files+=$'\n'
        fi
        mod_files+=$(echo "${list_mod}" | sed "s;^;${repo}/;")
    fi
}

check_git
