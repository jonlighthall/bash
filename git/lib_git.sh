#!/bin/bash -u
#
# git/check_repos.sh
#
# METHOD -
#
# USAGE - the remote name and branch can be optionally specified by the first and second
# arguments, respectively. The default remote branch is the current tracking branch.
#
# Apr 2023 JCL

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
            return 1
        fi
    fi
    echo "git v${git_ver}"
}

function print_remotes() {
    local DEBUG=1
    rtab
    check_git
    echo -n "${TAB}checking repository status... "
    old_opts=$(echo "$-")
    # exit on errors must be turned off; otherwise shell will exit when not inside a repository
    set +e
    git rev-parse --is-inside-work-tree &>/dev/null
    RETVAL=$?
    reset_shell $old_opts
    if [[ $RETVAL -eq 0 ]]; then
        echo -e "${GOOD}OK${RESET} "        

        # get number of remotes
        local -i n_remotes=$(git remote | wc -l)
        local r_names=$(git remote)
        echo "${TAB}remotes found: ${n_remotes}"
        local -i i=0
        for remote_name in ${r_names}; do
            if [ "${n_remotes}" -gt 1 ]; then
                ((++i))
                echo -n "${TAB}${fTAB}$i) "
                itab
            fi
            # get URL
            echo "$remote_name"
            local remote_url
            if [ $git_ver_maj -lt 2 ]; then
                remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
            else
                remote_url=$(git remote get-url ${remote_name})
            fi
            dtab
        done
    else
        echo "not a Git repository"
        return 0
    fi
}

function check_repos() {
    # get starting time in nanoseconds
    local -i start_time=$(date +%s%N)

    # set tab
    called_by=$(ps -o comm= $PPID)
    if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ] || [[ "${called_by}" == "Relay"* ]]; then
        TAB=''
        : ${fTAB:='   '}
    else
        itab
    fi

    # set debug level
    local -i DEBUG=${DEBUG:=0} # default value if DEBUG is unset or null

    # load formatting and functions
    local fpretty=${HOME}/config/.bashrc_pretty
    if [ -e $fpretty ]; then
        source $fpretty
        set_traps
    fi

    # determine if script is being sourced or executed and add conditional behavior
    local RUN_TYPE
    if (return 0 2>/dev/null); then
        RUN_TYPE="sourcing"
        #set +e
    else
        RUN_TYPE="executing"
        #set -e
    fi

    # show good hosts
    decho -n "existing good hosts: "
    if [ -z "${host_OK:+dummy}" ]; then
        decho "none"
        export host_OK=''
    else
        host_OK=$(echo "${host_OK}" | sort -n)
        decho
        decho -e "${GOOD}${host_OK}${RESET}" | sed "$ ! s/^/${fTAB}/"
    fi

    # show bad hosts
    decho -n "existing  bad hosts: "
    if [ -z "${host_bad:+dummy}" ]; then
        decho "none"
        export host_bad=''
    else
        host_bad=$(echo "${host_bad}" | sort -n)
        decho
        decho -e "${BAD}${host_bad}${RESET}" | sed "$ ! s/^/${fTAB}/"
    fi

    # check if git is defined and get version number
    check_git
    
    # get number of remotes
    local -i n_remotes=$(git remote | wc -l)
    local r_names=$(git remote)
    echo "remotes found: ${n_remotes}"
    local -i i=0
    for remote_name in ${r_names}; do
        if [ "${n_remotes}" -gt 1 ]; then
            ((++i))
            echo -n "${TAB}${fTAB}$i) "
            itab
        fi
        # get URL
        echo "$remote_name"
        local remote_url
        if [ $git_ver_maj -lt 2 ]; then
            remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
        else
            remote_url=$(git remote get-url ${remote_name})
        fi

        # parse protocol
        local remote_pro
        local remote_host
        remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
        if [[ "${remote_pro}" == "git" ]]; then
            remote_pro="SSH"
            remote_host=$(echo ${remote_url} | sed 's/\(^[^:]*\):.*$/\1/')
        else
            remote_host=$(echo ${remote_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
            if [[ "${remote_pro}" == "http"* ]]; then
                # warn about HTTP remotes
                remote_pro=${GRH}${remote_pro}${RESET}
                remote_repo=$(echo ${remote_url} | sed 's,^[a-z]*://[^/]*/\(.*\),\1,')
                echo "  repo: ${remote_repo}"
                # change remote to SSH
                remote_ssh="git@${remote_host}:${remote_repo}"
                echo " change URL to ${remote_ssh}..."
                echo " ${fTAB}git remote set-url ${remote_name} ${remote_ssh}"
                git remote set-url ${remote_name} ${remote_ssh}
            else
                remote_pro="local"
            fi
        fi
        if [[ "${remote_pro}" == "SSH" ]]; then
            # default to checking host
            local do_connect=true
            host_stat=$(echo -e "${yellow}CHECK${RESET}")
            decho "do_connect = $do_connect"
            itab
            # check remote host name against list of checked hosts
            if [ ! -z ${host_OK:+dummy} ] || [ ! -z ${host_bad:+dummy} ]; then
                decho "${TAB}checking $remote_host against list of checked hosts..."
                if [ ! -z ${host_OK:+dummy} ]; then
                    for good_host in ${host_OK}; do
                        if [[ $remote_host =~ $good_host ]]; then
                            decho "${TAB}${remote_host} matches $good_host"
                            host_stat=$(echo -e "${GOOD}OK${RESET}")
                            do_connect=false
                            break
                        fi
                    done
                fi

                if [ ! -z ${host_bad:+dummy} ]; then
                    for bad_host in ${host_bad}; do
                        if [[ "$remote_host" == "$bad_host" ]]; then
                            decho "${TAB}${remote_host} matches $bad_host"
                            host_stat=$(echo -e "${BAD}FAIL${RESET}")
                            do_connect=false
                            break
                        fi
                    done
                fi
            fi
        else
            do_connect=false
            host_stat=$(echo -e "${gray}CHECK${RESET}")
        fi # SSH

        (
            echo    "${TAB}url+ ${remote_url}"
            echo -e "${TAB}host+ ${remote_host} ${host_stat}"
            echo -e "${TAB}proto+ ${remote_pro}"
        ) | column -t -s+ -o : -R 1
        decho "do_connect = $do_connect"
        dtab
        # check connection before proceeding
        set -ET
        unset_traps
        if [ ${do_connect} = 'true' ]; then
            echo -n "${TAB}${fTAB}checking connection... "

            ssh_cmd_base="ssh -o ConnectTimeout=3 -o ConnectionAttempts=1 -T ${remote_host}"
            if [[ "${remote_host}" == *"navy.mil" ]]; then
                $ssh_cmd_base -o LogLevel=error 2> >(sed $'s,.*,\e[31m&\e[m,' >&2) 1> >(sed $'s,.*,\e[32m&\e[m,' >&1)
            else
                if [[ ${remote_host} =~ "github.com" ]]; then
                    set +e
                    $ssh_cmd_base -o LogLevel=info 2> >(sed $'s,^.*success.*$,\e[32m&\e[m,;s,.*,\e[31m&\e[m,' >&2)
                    set -e
                else
                    $ssh_cmd_base -o LogLevel=info 2> >(sed $'s,.*,\e[31m&\e[m,' >&2)
                fi
            fi
            RETVAL=$?
            set_traps
            if [[ $RETVAL == 0 ]]; then
                echo -e "${TAB}${fTAB}${GOOD}OK${RESET} ${gray}RETVAL=$RETVAL${RESET}"
                # add to list
                if [ ! -z ${host_OK:+dummy} ]; then
                    host_OK+=$'\n'
                fi
                host_OK+=${remote_host}
            else
                if [[ $RETVAL == 1 ]]; then
                    echo -e "${TAB}${fTAB}${yellow}FAIL${RESET} ${gray}RETVAL=$RETVAL${RESET}"
                    if [[ $remote_host =~ "github.com" ]]; then
                        decho "host is github"
                        # Github will return 1 if everything is working
                        # add to list
                        if [ ! -z ${host_OK:+dummy} ]; then
                            host_OK+=$'\n'
                        fi
                        host_OK+=${remote_host}
                    else
                        decho "host is not github"
                        # add to list
                        if [ ! -z ${host_bad:+dummy} ]; then
                            host_bad+=$'\n'
                        fi
                        host_bad+=${remote_host}
                    fi
                else
                    echo -e "${TAB}${fTAB}${BAD}FAIL${RESET} ${gray}RETVAL=$RETVAL${RESET}"
                    # add to list
                    if [ ! -z ${host_bad:+dummy} ]; then
                        host_bad+=$'\n'
                    fi
                    host_bad+=${remote_host}
                fi # retval 1
            fi # retval 0
        else
            decho "skipping connection check..."
            continue
        fi # do check

        if [ "${n_remotes}" -gt 1 ]; then
            dtab
        fi
    done
    unset remote_url
    unset remote_pro
    unset remote_host

    # print good hosts
    if [ $DEBUG -gt 0 ]; then
        echo -n "${TAB}good hosts: "
        if [ -z "${host_OK:+dummy}" ]; then
            echo "none"
        else
            host_OK=$(echo "${host_OK}" | sort -n)
            echo
            echo -e "${GOOD}${host_OK}${RESET}" | sed "s/^/${fTAB}/"
        fi

        # print bad hosts
        echo -n "${TAB} bad hosts: "
        if [ -z "$host_bad" ]; then
            echo "none"
        else
            host_bad=$(echo "${host_bad}" | sort -n)
            echo
            echo -e "${BAD}${host_bad}${RESET}" | sed "s/^/${fTAB}/"
        fi
    fi

    export host_OK
    export host_bad

    decho "done"
    # add return code for parent script
    trap 'print_return $?; trap - RETURN' RETURN
    return 0
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
