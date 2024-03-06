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

# get starting time in nanoseconds
function check_repos() {
    trap 'print_return $?; trap - RETURN' RETURN
    local -i start_time=$(date +%s%N)

    # set tab
    called_by=$(ps -o comm= $PPID)
    if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ] || [[ "${called_by}" == "Relay"* ]]; then
        TAB=''
        : ${fTAB:='   '}
    else
        TAB+=${TAB+${fTAB:='   '}}
    fi

    # set debug level
    declare -i DEBUG=${DEBUG:=0}

    # load formatting and functions
    fpretty=${HOME}/config/.bashrc_pretty
    if [ -e $fpretty ]; then
        source $fpretty
        set_traps
        decho "DEBUG = $DEBUG"
    fi

    # determine if script is being sourced or executed and add conditional behavior
    if (return 0 2>/dev/null); then
        RUN_TYPE="sourcing"
        set -T +e
    else
        RUN_TYPE="executing"
        set -e
      
    fi

    # show good hosts
    decho -n "existing good hosts: "
    if [ -z "${host_OK:+dummy}" ]; then
        decho "none"
        export host_OK=''
    else
        host_OK=$(echo "${host_OK}" | sort -n)
        decho
        decho -e "${GOOD}${host_OK}${NORMAL}" | sed "s/^/${fTAB}/"
    fi

    # show bad hosts
    decho -n "existing bad hosts: "
    if [ -z "${host_bad:+dummy}" ]; then
        decho "none"
        export host_bad=''
    else
        host_bad=$(echo "${host_bad}" | sort -n)
        decho
        decho -e "${BAD}${host_bad}${NORMAL}" | sed "s/^/${fTAB}/"
    fi

    # check if Git is defined
    if [ -z "${check_git:+dummy}" ]; then
        echo -n "${TAB}Checking Git... "
        if command -v git &>/dev/null; then
            echo -e "${GOOD}OK${NORMAL} Git is defined"
            # get Git version
            git --version | sed "s/^/${fTAB}/"
            git_ver=$(git --version | awk '{print $3}')
            git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
            git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
            git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')
            export check_git=false
        else
            echo -e "${BAD}FAIL${NORMAL} Git not defined"
            if (return 0 2>/dev/null); then
                return 1
            else
                exit 1
            fi
        fi
    fi

    # get number of remotes
    n_remotes=$(git remote | wc -l)
    r_names=$(git remote)
    echo "remotes found: ${n_remotes}"
    declare -i i=0
    for remote_name in ${r_names}; do
        if [ "${n_remotes}" -gt 1 ]; then
            ((++i))
            echo -n "${TAB}${fTAB}$i) "
            TAB+=${fTAB:='   '}
        fi
        # get URL
        echo "$remote_name"
        if [ $git_ver_maj -lt 2 ]; then
            remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | uniq)
        else
            remote_url=$(git remote get-url ${remote_name})
        fi

        # parse protocol
        remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
        if [[ "${remote_pro}" == "git" ]]; then
            remote_pro="SSH"
            remote_host=$(echo ${remote_url} | sed 's/\(^[^:]*\):.*$/\1/')
        else
            remote_host=$(echo ${remote_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
            if [[ "${remote_pro}" == "http"* ]]; then
                # warn about HTTP remotes
                remote_pro=${GRH}${remote_pro}${NORMAL}
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
            do_check=true
            host_stat=$(echo -e "${yellow}CHECK${NORMAL}")
            decho "do_check = $do_check"

            # check remote host name against list of checked hosts
            if [ ! -z ${host_OK:+dummy} ] || [ ! -z ${host_bad:+dummy} ]; then
                decho "checking $remote_host against list of checked hosts..."
                if [ ! -z ${host_OK:+dummy} ]; then
                    for good_host in ${host_OK}; do
                        if [[ $remote_host =~ $good_host ]]; then
                            decho "${TAB}${remote_host} matches $good_host"
                            host_stat=$(echo -e "${GOOD}OK${NORMAL}")
                            do_check=false
                            break
                        fi
                    done
                fi

                if [ ! -z ${host_bad:+dummy} ]; then
                    for bad_host in ${host_bad}; do
                        if [[ "$remote_host" == "$bad_host" ]]; then
                            decho "${TAB}${remote_host} matches $bad_host"
                            host_stat=$(echo -e "${BAD}FAIL${NORMAL}")
                            do_check=false
                            break
                        fi
                    done
                fi
            fi
        else
            do_check=false
            host_stat=$(echo -e "${gray}CHECK{NORMAL}")
        fi # SSH

        (
            echo "${TAB}${fTAB}url+ ${remote_url}"
            echo -e "${TAB}${fTAB}host+ ${remote_host} ${host_stat}"
            echo -e "${TAB}${fTAB}proto+ ${remote_pro}"
        ) | column -t -s+ -o : -R 1
        decho "do_check = $do_check"

        # check connection before proceeding
        if [ ${do_check} = 'true' ]; then
            echo -n "${TAB}${fTAB}checking connection... "
            unset_traps
            ssh_cmd_base="ssh -o ConnectTimeout=3 -o ConnectionAttempts=1 -T ${remote_host}"
            if [[ "${remote_host}" == *"navy.mil" ]]; then
                $ssh_cmd_base -o LogLevel=error 2> >(sed $'s,.*,\e[31m&\e[m,' >&2) 1> >(sed $'s,.*,\e[32m&\e[m,' >&1)
            else
                if [[ ${remote_host} =~ "github.com" ]]; then
                    $ssh_cmd_base -o LogLevel=info 2> >(sed $'s,^.*success.*$,\e[32m&\e[m,;s,.*,\e[31m&\e[m,' >&2)
                else
                    $ssh_cmd_base -o LogLevel=info 2> >(sed $'s,.*,\e[31m&\e[m,' >&2)
                fi
            fi
            RETVAL=$?
            set_traps
            if [[ $RETVAL == 0 ]]; then
                echo -e "${TAB}${fTAB}${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
                # add to list
                if [ ! -z ${host_OK:+dummy} ]; then
                    host_OK+=$'\n'
                fi
                host_OK+=${remote_host}
            else
                if [[ $RETVAL == 1 ]]; then
                    echo -e "${TAB}${fTAB}${yellow}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
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
                    echo -e "${TAB}${fTAB}${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
                    # add to list
                    if [ ! -z ${host_bad:+dummy} ]; then
                        host_bad+=$'\n'
                    fi
                    host_bad+=${remote_host}
                fi # retval 1
            fi # retval 0
        fi # do check

        if [ "${n_remotes}" -gt 1 ]; then
            TAB=${TAB%$fTAB}
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
            echo -e "${GOOD}${host_OK}${NORMAL}" | sed "s/^/${fTAB}/"
        fi

        # print bad hosts
        echo -n "${TAB} bad hosts: "
        if [ -z "$host_bad" ]; then
            echo "none"
        else
            host_bad=$(echo "${host_bad}" | sort -n)
            echo
            echo -e "${BAD}${host_bad}${NORMAL}" | sed "s/^/${fTAB}/"
        fi
    fi

    export host_OK
    export host_bad

    decho "done"
    # add return code for parent script
return 0
}
