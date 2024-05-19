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

function print_remote() {
    if [ "${n_remotes}" -gt 1 ]; then
        ((++i))
        echo -n "${TAB}${fTAB}$i) "
        itab
    else
        echo -n "${TAB}"
    fi
    echo -en "${PSBR}${remote_name}${RESET} "
    
    # get URL
    export remote_url
    if [ $git_ver_maj -lt 2 ]; then
        remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
    else
        remote_url=$(git remote get-url ${remote_name})
    fi

}

function print_remotes() {
    # set debug level
    local DEBUG=1
    check_repo
    local -i RETVAL=$?
    if [[ $RETVAL -eq 0 ]]; then
        # get number of remotes
        local -i n_remotes=$(git remote | wc -l)
        local r_names=$(git remote)
        echo "${TAB}remotes found: ${n_remotes}"
        local -i i=0
        for remote_name in ${r_names}; do
            print_remote
            echo
            dtab          
        done
    fi
}

function check_remotes() {
    # get starting time in nanoseconds
    local -i start_time=$(date +%s%N)

    # set debug level
    # automaticly set default value if DEBUG is unset or null
    local -i DEBUG=${DEBUG:=0}
    # manually set
    #local -i DEBUG=1

    # load formatting and functions
    local fpretty=${HOME}/config/.bashrc_pretty
    if [ -e $fpretty ]; then
        source $fpretty
    fi

    if [[ "$-" == *e* ]]; then
        # exit on errors must be turned off; otherwise shell will exit when not in a repo
        old_opts=$(echo "$-")
        set +e
    fi    
    check_repo
    local -i RETVAL=$?
    reset_shell ${old_opts-''}
    if [[ $RETVAL -eq 0 ]]; then
        decho "${TAB}proceeding to check hosts"
        set_traps
    else
        echo "${TAB}not a Git repository"
        return 1
    fi    
    
    # print list of hosts that have already been checked
    if [ $DEBUG -gt 0 ]; then
        print_hosts
    fi
    
    # get number of remotes
    local -i n_remotes=$(git remote | wc -l)
    export r_names=$(git remote)
    echo "${TAB}remotes found: ${n_remotes}"
    local -i i=0
    for remote_name in ${r_names}; do
        print_remote
        
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
            decho -e "\n${TAB}do_connect = $do_connect"

            # check against argument
            if [ $# -gt 0 ]; then
                # decho -en "\n"
                for arg in $@; do
                    decho -en "${TAB}checking $remote_url against argument ${ARG}${ARG}${RESET}... "
                    if [[ $remote_url =~ $arg ]]; then
                        echo -en "${GOOD}OK${RESET}"
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
            #printf '\e[0;90;40m\u21b5\n\e[m'
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
            unset_traps

            ssh_cmd_base="ssh -o ConnectTimeout=3 -o ConnectionAttempts=1 -T ${remote_host}"
            if [[ "${remote_host}" == *"navy.mil" ]]; then
                decho "${TAB}Navy host: ${remote_host}"
                do_cmd $ssh_cmd_base -o LogLevel=verbose
                #2> >(sed -u $'s,.*,\e[31m&\e[m,' >&2) 1> >(sed -u $'s,.*,\e[32m&\e[m,' >&1)
                RETVAL=$?
            else
                if [[ ${remote_host} =~ "github.com" ]]; then
                    decho "${TAB}GitHub host: ${remote_host}"
                    # set shell options
                    if [[ "$-" == *e* ]]; then
                        echo -n "${TAB}setting shell options..."    
                        old_opts=$(echo "$-")
                        # exit on errors must be turned off; otherwise shell will exit...
                        set +e
                        echo "done"
                    fi
                    do_cmd $ssh_cmd_base -o LogLevel=info
                    # 2> >(sed -u $'s,^.*success.*$,\e[32m&\e[m,;s,.*,\e[31m&\e[m,' >&2)
                    RETVAL=$?
                    reset_shell ${old_opts-''}
                else
                    decho "${TAB}host: ${remote_host}"
                    do_cmd $ssh_cmd_base -o LogLevel=info
                    #2> >(sed -u $'s,.*,\e[31m&\e[m,' >&2)
                    RETVAL=$?
                fi
            fi
            reset_traps

            # check cursor position
            local -i x1c
            get_curpos x1c
            if [ $x1c -eq 1 ]; then
                # beautify settings
                GIT_HIGHLIGHT='\E[7m'
                echo -en "${TAB}${fTAB}${GIT_HIGHLIGHT} auth ${RESET} "
            fi

            if [[ $RETVAL == 0 ]]; then
                echo -en "${GOOD}OK${RESET} "
                if [ $x1c -eq 1 ]; then
                    echo -e "${GRAY}RETVAL=$RETVAL${RESET}"
                else
                    echo
                fi  
                # add to list
                if [ ! -z ${host_OK:+dummy} ]; then
                    host_OK+=$'\n'
                fi
                host_OK+=${remote_host}
            else
                if [[ $RETVAL == 1 ]]; then
                    echo -e "${YELLOW}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
                    #dtab
                    if [[ $remote_host =~ "github.com" ]]; then
                        decho "${TAB}GitHub host: ${remote_host}"
                        # Github will return 1 if everything is working
                        # add to list
                        if [ ! -z ${host_OK:+dummy} ]; then
                            host_OK+=$'\n'
                        fi
                        host_OK+=${remote_host}
                    else
                        decho "${TAB}host: ${remote_host}"
                        # add to list
                        if [ ! -z ${host_bad:+dummy} ]; then
                            host_bad+=$'\n'
                        fi
                        host_bad+=${remote_host}
                    fi
                else
                    echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
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

    if [ $DEBUG -gt 0 ]; then
        print_hosts
    fi

    export host_OK
    export host_bad

    unset_traps

    # add return code for parent script
    if [ $DEBUG -gt 0 ]; then
        trap 'print_return $?; trap - RETURN' RETURN
    fi
    return 0
}

function print_hosts() {
    # print good hosts
    echo "${TAB}good hosts: "
    itab
    if [ -z "${host_OK:+dummy}" ]; then
        echo "${TAB}none"
    else
        host_OK=$(echo "${host_OK}" | sort -n)
        echo -e "${GOOD}${host_OK}${RESET}" | sed "s/^/${TAB}/"
    fi
    dtab

    # print bad hosts
    echo "${TAB} bad hosts: "
    itab
    if [ -z "${host_bad:+dummy}" ]; then
        echo "${TAB}none"
    else
        host_bad=$(echo "${host_bad}" | sort -n)
        echo -e "${BAD}${host_bad}${RESET}" | sed "s/^/${TAB}/"
    fi
    dtab
}

function check_mod() {
    check_repo
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

function print_branches() {
    # load git utils
    get_source
    for library in git; do
        fname="${src_dir_phys}/lib_${library}.sh"
        if [ -e "${fname}" ]; then
            if [[ "$-" == *i* ]] && [ ${DEBUG:-0} -gt 0 ]; then
                echo "${TAB}loading $(basename "${fname}")"
            fi
            source "${fname}"
        else
            echo "${fname} not found"
        fi
    done

    # before starting, fetch remote
    echo -n "${TAB}fetching ${pull_repo}..."
    do_cmd_stdbuf git fetch --all --verbose ${pull_repo}    

    check_remotes
    parse_remote_tracking_branch
    echo "remote tracking branches:"
    git branch -vvr --color=always | grep -v '\->'
    #    local branches=$(git branch -r | grep -v '\->')
    #    echo $branches
    for remote_name in ${r_names}; do
        echo -e "${PSBR}${remote_name}${RESET} "
        git branch -vvr --color=always -l ${remote_name}* | grep -v '\->' 
    done
}

function parse_remote_tracking_branch() {
    # parse remote tracking branch and local branch
    cbar "${BOLD}parse current settings...${RESET}"
    # set shell options
    if [[ "$-" == *e* ]]; then
        # exit on errors must be turned off; otherwise shell will exit no remote branch found
        old_opts=$(echo "$-")
        set +e
    fi
    check_repo
    local -i RETVAL=$?
    reset_shell ${old_opts-''}
    if [[ $RETVAL -eq 0 ]]; then
        decho "${TAB}proceeding to check hosts"
        set_traps
    else
        echo "${TAB}not a Git repository"
        return 1
    fi    

    # parse local
    local_branch=$(git branch | grep \* | sed 's/^\* //')
    # parse remote
    echo -n "${TAB}checking remote tracking branch... "
    unset_traps
    git rev-parse --abbrev-ref @{upstream} &>/dev/null
    RETVAL=$?
    reset_shell ${old_opts-''}
    if [[ $RETVAL -ne 0 ]]; then
        echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
        do_cmd git rev-parse --abbrev-ref @{upstream}
        reset_traps
        echo "${TAB}no remote tracking branch set for current branch"
    else
        reset_traps
        remote_tracking_branch=$(git rev-parse --abbrev-ref @{upstream})
        upstream_repo=${remote_tracking_branch%%/*}
        # parse branches
        upstream_refspec=${remote_tracking_branch#*/}
        if [ ${DEBUG:-0} -eq 0 ]; then
            echo
        fi
        (
            echo -e "remote tracking branch+${BLUE}${remote_tracking_branch}${RESET}"
            echo "remote name+$upstream_repo"
            echo "remote refspec+$upstream_refspec"
            echo -e "local branch+${GREEN}${local_branch}${RESET}"
        ) | column -t -s+ -o ": " -R1 | sed "s/^//"
    fi
}

function track_all_branches() {
    # DEBUG=1
    get_source
    # load git utils
    for library in git; do
        fname="${src_dir_phys}/lib_${library}.sh"
        if [ -e "${fname}" ]; then
            if [[ "$-" == *i* ]] && [ ${DEBUG:-0} -gt 0 ]; then
                echo "${TAB}loading $(basename "${fname}")"
            fi
            source "${fname}"
        else
            echo "${fname} not found"
        fi
    done

    check_remotes
    local RETVAL=$?
    reset_shell ${old_opts-''}
    if [[ $RETVAL -eq 0 ]]; then
        decho "${TAB}proceeding to check hosts"
        set_traps
    else
        return 1
    fi    
    parse_remote_tracking_branch

    # parse arguments
    cbar "${BOLD}parse arguments...${RESET}"
    if [ $# -ge 1 ]; then
        echo "${TAB}remote specified"
        unset remote_name
        pull_repo=$1
        echo -n "${TAB}${fTAB}remote name: ....... $pull_repo "
        git remote | grep $pull_repo &>/dev/null
        RETVAL=$?
        if [[ $RETVAL == 0 ]]; then
            echo -e "${GOOD}OK${RESET}"
        else
            echo -e "${BAD}FAIL${RESET}"
            echo "$pull_repo not found"
            return 1
        fi
    else
        echo "${TAB}no remote specified"
        if [ -z ${upstream_repo+dummy} ]; then
            echo "${TAB}no remote tracking branch set for current branch"
            echo "${TAB}exiting..."
            return 1
        else
            echo "${TAB}${fTAB}using $upstream_repo"
            pull_repo=${upstream_repo}
        fi
    fi

    # before starting, fetch remote
    echo -n "${TAB}fetching ${pull_repo}..."
    do_cmd_stdbuf git fetch --verbose --prune ${pull_repo}

    # print remote branches
    echo "${TAB}remote tracking branches:"
    git branch -vvr --color=always | grep -v '\->'
    
    echo "${TAB}${pull_repo} branches:"
    git branch -vvr --color=always -l ${pull_repo}* | grep -v '\->'

    # get branches of pull repo
    local pull_branches=$(git branch -rl ${pull_repo}* | grep -v '\->')

    # loop over branches
    echo "${TAB}checking branches..."
    
    for branch in ${pull_branches}; do
        # define (local) branch name
        branch_name=${branch#${pull_repo}/}
        itab
        echo -e "${TAB}${PSBR}${branch_name}${RESET} "
        itab

        # check if branch exists
        if git branch | grep "${branch_name}" &>/dev/null; then
            echo "${TAB}branch exists"
            # check if branch is current branch
            if git branch | grep "\* ${branch_name}" &>/dev/null; then
                echo -e "${TAB}* ${GREEN}current branch${NORMAL}"
            fi
            # set existing branch to track remote branch
            # dtab
            do_cmd git branch "${branch_name}" --set-upstream-to="${branch}"
        else
            echo -en "${TAB}${GRH}"
            hline 72
            echo "${TAB}branch does not exist"
            # create local branch to track remote branch
            dtab
            do_cmd git branch "${branch_name}" --track "$branch"
            itab
            echo -en "${TAB}${GRH}"
            hline 72
            echo -en "${RESET}"
            #dtab
        fi
        dtab
    done
    dtab
    echo "${TAB}list of local branches:"
    git branch -vv --color=always 
}
