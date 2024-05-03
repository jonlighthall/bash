#!/bin/bash -u
#
# git/check_remotes.sh
#
# METHOD -
#
# USAGE - the remote name and branch can be optionally specified by the first and second
# arguments, respectively. The default remote branch is the current tracking branch.
#
# Apr 2023 JCL

function check_git() {
    # substitute default debug if unset or null
    local DEBUG=${DEBUG:-0}
    # manually set
    #local -i DEBUG=1

    # check if Git is defined
    ddecho -n "${TAB}checking Git... "
    if [ -z "${check_git:+dummy}" ]; then
        if command -v git &>/dev/null; then
            ddecho -en "${GOOD}OK${RESET} "
            # parse Git version
            export git_ver=$(git --version | awk '{print $3}')
            export git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
            export git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
            export git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')
            export check_git=false           
            decho -e "${GRAY}v${git_ver}${NORMAL}"
            return 0
        else
            ddecho -e "${BAD}FAIL${RESET} Git not defined"
            return 1
        fi
    fi
    ddecho -e "already checked "
    decho "${TAB}git v${git_ver}"
    return 0
}

function check_repo() {
    # substitute default debug if unset or null
    local DEBUG=${DEBUG:-0}
    # manually set
    #local -i DEBUG=1
    check_git
    echo -n "${TAB}checking repository status... "
    # set shell options
    if [[ "$-" == *e* ]]; then
        # exit on errors must be turned off; otherwise shell will exit no remote branch found
        old_opts=$(echo "$-")
        set +e
    fi
    git rev-parse --is-inside-work-tree &>/dev/null
    local -i RETVAL=$?
    reset_shell ${old_opts-''}
    if [[ $RETVAL -eq 0 ]]; then
        echo -e "${GOOD}OK${RESET} "
        return 0
    else
        echo -e "${BAD}FAIL${RESET} "        
        #echo "${TAB}not a Git repository"
        return 1
    fi    
}

function print_remotes() {
    local DEBUG=1
    rtab
    check_repo
    local -i RETVAL=$?
    if [[ $RETVAL -eq 0 ]]; then
        # get number of remotes
        local -i n_remotes=$(git remote | wc -l)
        local r_names=$(git remote)
        echo "${TAB}remotes found: ${n_remotes}"
        local -i i=0
        for remote_name in ${r_names}; do
            ((++i))
            itab
            echo "${TAB}$i) $remote_name"

            # get URL
            local remote_url
            if [ $git_ver_maj -lt 2 ]; then
                remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
            else
                remote_url=$(git remote get-url ${remote_name})
            fi
            dtab
        done
    fi
}

function check_remotes() {
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
    # automaticly set default value if DEBUG is unset or null
    local -i DEBUG=${DEBUG:=0}
    # manually set
    #local -i DEBUG=1

    # load formatting and functions
    local fpretty=${HOME}/config/.bashrc_pretty
    if [ -e $fpretty ]; then
        source $fpretty
        set_traps
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
        echo -en "\x1b[0;36m$remote_name\x1b[0m "
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
                echo -e "${YELLOW} change URL to ${remote_ssh}..."
                echo " ${fTAB}git remote set-url ${remote_name} ${remote_ssh}${RESET}"
                git remote set-url ${remote_name} ${remote_ssh}
            else
                remote_pro="local"
            fi
        fi
        if [[ "${remote_pro}" == "SSH" ]]; then
            # default to checking host
            local do_connect=true
            host_stat=$(echo -e "${YELLOW}CHECK${RESET}")
            itab
            decho -en "\n${TAB}do_connect = $do_connect"

            # check against argument
            if [ $# -gt 0 ]; then
                decho -en "\n"
                for arg in $@; do
                    decho -en "${TAB}checking $remote_url against argument \x1b[36m$arg\x1b[m... "
                    if [[ $remote_url =~ $arg ]]; then
                        echo -e "${GOOD}OK${RESET}"
                        url_stat=$(echo -e "${GOOD}OK${RESET}")
                        break
                    else
                        echo -e "${GRAY}SKIP${RESET}"
                        url_stat=$(echo -e "${GRAY}SKIP${RESET}")
                        do_connect=false
                    fi
                done
                if [ ${do_connect} = 'false' ]; then
                    dtab 2
                    continue
                fi
            else
                url_stat=''
            fi

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
            host_stat=$(echo -e "${GRAY}CHECK${RESET}")
        fi # SSH

        if [ $DEBUG = 0 ]; then
            echo
        fi

        (
            echo    "${TAB}url+ ${remote_url} ${url_stat}"
            echo -e "${TAB}host+ ${remote_host} ${host_stat}"
            decho -e "${TAB}proto+ ${remote_pro}"
        ) | column -t -s+ -o : -R 1
        decho "${TAB}do_connect = $do_connect"

        # check connection before proceeding       
        if [ ${do_connect} = 'true' ]; then
            echo -n "${TAB}checking connection... "

            ssh_cmd_base="ssh -o ConnectTimeout=3 -o ConnectionAttempts=1 -T ${remote_host}"
            if [[ "${remote_host}" == *"navy.mil" ]]; then
                $ssh_cmd_base -o LogLevel=error 2> >(sed -u $'s,.*,\e[31m&\e[m,' >&2) 1> >(sed -u $'s,.*,\e[32m&\e[m,' >&1)
                RETVAL=$?
            else
                if [[ ${remote_host} =~ "github.com" ]]; then
                    # set shell options
                    unset_traps
                    if [[ "$-" == *e* ]]; then
                        echo -n "${TAB}setting shell options..."    
                        old_opts=$(echo "$-")
                        # exit on errors must be turned off; otherwise shell will exit...
                        set +e
                        echo "done"
                    fi
                    $ssh_cmd_base -o LogLevel=info 2> >(sed -u $'s,^.*success.*$,\e[32m&\e[m,;s,.*,\e[31m&\e[m,' >&2)
                    RETVAL=$?
                    reset_shell $old_opts
                    reset_traps                   
                else
                    $ssh_cmd_base -o LogLevel=info 2> >(sed -u $'s,.*,\e[31m&\e[m,' >&2)
                    RETVAL=$?
                fi
            fi
            if [[ $RETVAL == 0 ]]; then
                echo -e "${TAB}${GOOD}OK${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
                # add to list
                if [ ! -z ${host_OK:+dummy} ]; then
                    host_OK+=$'\n'
                fi
                host_OK+=${remote_host}
            else
                if [[ $RETVAL == 1 ]]; then
                    echo -e "${TAB}${YELLOW}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
                    if [[ $remote_host =~ "github.com" ]]; then
                        decho "${TAB}host is github"
                        # Github will return 1 if everything is working
                        # add to list
                        if [ ! -z ${host_OK:+dummy} ]; then
                            host_OK+=$'\n'
                        fi
                        host_OK+=${remote_host}
                    else
                        decho "${TAB}host is not github"
                        # add to list
                        if [ ! -z ${host_bad:+dummy} ]; then
                            host_bad+=$'\n'
                        fi
                        host_bad+=${remote_host}
                    fi
                else
                    echo -e "${TAB}${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
                    # add to list
                    if [ ! -z ${host_bad:+dummy} ]; then
                        host_bad+=$'\n'
                    fi
                    host_bad+=${remote_host}
                fi # retval 1
            fi # retval 0
        else
            decho "${TAB}skipping connection check..."
            dtab 2
            continue
        fi # do check
        dtab

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

    decho "${TAB}done"
    # add return code for parent script
    if [ $DEBUG -gt 0 ]; then
        trap 'print_return $?; trap - RETURN' RETURN
    fi
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

# format command output
function do_cmd() {
    local -i DEBUG=0
    # save command as variable
    cmd=$(echo $@)
    # format output
    if [ $DEBUG -gt 0 ]; then
        itab
        start_new_line
    fi
    decho "${TAB}running command $cmd... " 
    
    # get color index
    local -i idx
    dbg2idx 3 idx
    # set color
    echo -ne "${dcolor[$idx]}"

    if command -v unbuffer >/dev/null; then
        ddecho "${TAB}printing unbuffered command ouput..."
        # set shell options
        set -o pipefail        
        # print unbuffered command output
        unbuffer $cmd \
            | sed -u '1 s/[A-Z]/\n&/' \
            | sed -u "s/\r$//g;s/.*\r/${TAB}/g;s/^/${TAB}/" \
            | sed -u "/^[^%|]*|/s/^/${dcolor[$idx+1]}/g; s/$/${dcolor[$idx]}/; /|/s/+/${GOOD}&/g; /|/s/-/${BAD}&/g; /modified:/s/^.*$/${BAD}&/g; /^\s*M\s/s/^.*$/${BAD}&/g" 
        local -i RETVAL=$?

        # reset shell options
        set +o pipefail
    else
        if command -v script >/dev/null; then
            ddecho "${TAB}printing command ouput typescript..."
            # print typescript command ouput
            do_cmd_script $cmd
        else        
            ddecho "${TAB}printing buffered command ouput..."
            # print buffered command output
            do_cmd_stdbuf $cmd
        fi
        local -i RETVAL=$?
        if [ $DEBUG -gt 0 ]; then
            dtab
        fi
    fi
    
    # reset formatting
    unset_color
    if [ $DEBUG -gt 0 ]; then
        dtab
    fi
    return $RETVAL
}

# format buffered command ouput
# save ouput to file, print file, delete file
function do_cmd_stdbuf() {    
    cmd=$(echo $@)
    # define temp file
    temp_file=temp
    if [ $DEBUG -gt 0 ]; then
        start_new_line
    fi
    ddecho "${TAB}redirecting command ouput to $temp_file..."
    # unbuffer command output and save to file    
    stdbuf -i0 -o0 -e0 $cmd &>$temp_file
    RETVAL=$?
    # colorize and indent command output
    if [ -s ${temp_file} ]; then
        # get color index
        local -i idx
        dbg2idx 3 idx
        # set color
        echo -ne "${dcolor[$idx]}"

        # format output
        start_new_line
        ddecho -e "${TAB}${IT}buffer:${NORMAL}"

        # print output
        \cat $temp_file \
            | sed "s/\r$//g;s/.*\r/${TAB}/g;s/^/${TAB}/" \
            | sed "/^[^%|]*|/s/^/${dcolor[$idx+1]}/g; /|/s/+/${GOOD}&/g; /|/s/-/${BAD}&/g; /modified:/s/^.*$/${BAD}&/g; /^\s*M\s/s/^.*$/${BAD}&/g" \
            | sed "s/^/${dcolor[$idx]}/"
        
        # reset formatting
        unset_color
    else
        itab
        ddecho "${TAB}${temp_file} empty"
        dtab
    fi
    # delete temp file
    if [ -f ${temp_file} ]; then
        rm ${temp_file}
    fi    
    return $RETVAL
}

function do_cmd_safe() {
    local -i DEBUG=1
    # save command as variable
    cmd=$(echo $@)
    # format output
    start_new_line
    itab
    decho "${TAB}SAFE: running command $cmd... " 

    # set shell options
    unset_traps
    if [[ "$-" == *e* ]]; then
        echo -n "${TAB}setting shell options..."    
        old_opts=$(echo "$-")
        # exit on errors must be turned off; otherwise shell will exit...
        set +e
        echo "done"
    fi

    dtab
    do_cmd $cmd
    RETVAL=$?
    
    itab
    reset_shell $old_opts
    reset_traps
    
    # reset formatting
    unset_color

    return $RETVAL
}

# format command output
function do_cmd_script() {
    local -i DEBUG=0
    # save command as variable
    cmd=$(echo $@)
    # format output
    itab
    if [ $DEBUG -gt 0 ]; then
        start_new_line
    fi
    decho "${TAB}SCRIPT: running command $cmd... " 
    
    # get color index
    local -i idx
    dbg2idx 5 idx
    # set color
    echo -ne "${dcolor[$idx]}"
    if command -v script >/dev/null; then
        ddecho "${TAB}printing command ouput typescript..."
        # set shell options
        set -o pipefail
        # print unbuffered command output <- only if "sed -u" is used!
        if true; then
            script -eq -c "$cmd" \
                | sed -u 's/$\r/\n\r/g'
        else
            script -eq -c "$cmd" \
                | sed "s/\r.*//g;s/.*\r//g" \
                | sed 's/^[[:space:]].*//g' \
                | sed "/^$/d;s/^/${TAB}${dcolor[$idx]}/"
        fi
        local -i RETVAL=$?
        # reset shell options
        set +o pipefail
        rm typescript
    else
        ddecho "${TAB}printing unformatted ouput..."
        dtab
        # print buffered command output
        $cmd
        local -i RETVAL=$?
    fi
    
    # reset formatting
    unset_color
    dtab    
    return $RETVAL
}

function exit_on_fail() {
    echo -e "${TAB}${YELLOW}\x1b[7m${BASH_SOURCE[1]##*/} failed\x1b[0m"
    # set behavior
    local do_exit=true
    if [[ $do_exit == true ]]; then
        print_stack
        set_traps
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
        echo -e "${TAB}modified: ${YELLOW}"
        itab
        echo "${list_mod}" | sed "s/^/${TAB}/"
        dtab
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
