#!/bin/bash -eu
# -----------------------------------------------------------------------------------------------
#
# update_repos.sh - push and pull a specified list of git repositories and print summaries
#
# Apr 2022 JCL
#
# -----------------------------------------------------------------------------------------------

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set debug level
# substitue default value if DEBUG is unset or null
declare -i DEBUG=${DEBUG:-0}

# load formatting and functions
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "${fpretty}" ]; then
    source "${fpretty}"
    print_debug
else
    # ignore undefined variables
    set +u 
    # do not exit on errors
    set +e
fi

# number of commits threshold for git operations
# set to 0 for normal operation
# set to -1 to pull, push, and gc on every repo
declare -i GIT_OP_THRESH=0

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    # exit on errors
    set -e
    
    # print note
    echo "NB: ${BASH_SOURCE##*/} has not been sourced"
    echo "    user SSH config settings MAY not be loaded??"
fi
print_source

# save and print starting directory
start_dir="$PWD"
echo "${TAB}starting directory = ${start_dir}"

# load git utils
for library in git; do
    # use the canonical (physical) source directory for reference; this is important if sourcing
    # this file directly from shell
    fname="${src_dir_phys}/lib_${library}.sh"
    if [ -e "${fname}" ]; then
        if [[ "$-" == *i* ]] && [ ${DEBUG:-0} -gt 0 ]; then
            echo "${TAB}loading $(basename ${fname})"
        fi
        source "${fname}"
    else
        echo "${fname} not found"
    fi
done

# list repository paths, relative to home
# settings
list="config "
if [[ ! ("$(hostname -f)" == *"navy.mil") ]]; then
    list+=" config/private "
fi

# scripting utilities
dir_script="utils/"
list+="${dir_script}bash \
   ${dir_script}batch \
   ${dir_script}powershell "
list_remote=${HOME}/${dir_script}bash/git/list_remote_url.txt

# programming utilities
dir_prog="utils/"
list+="${dir_prog}fortran_utilities "

# tutorial examples
dir_examp="examp/"
list+="${dir_examp}cpp \
   ${dir_examp}hello \
   ${dir_examp}fortran \
   ${dir_examp}nrf \
   ${dir_examp}nrf77 \
   ${dir_examp}python "

# matlab
dir_matlab="matlab/"
list+="${dir_matlab} \
   ${dir_matlab}macros "

# private
fname_private=${HOME}/${dir_script}bash/git/list_private_dir.txt
if [ -f ${fname_private} ]; then
    while IFS= read -r line; do
        # evaluate each line to expand defined variable names
        eval line2=$line
        if [[ $line == $line2 ]]; then
            list+=" ${line}"
        else
            list+=" ${line2}"
        fi
    done <${fname_private}
fi

# project
fname_project=${HOME}/${dir_script}bash/git/list_project_dir.txt
if [ -f ${fname_project} ]; then
    while IFS= read -r line; do
        # evaluate each line to expand defined variable names
        eval line2=$line
        if [[ $line == $line2 ]]; then
            list+=" ${line}"
        else
            list+=" ${line2}"
        fi
    done <${fname_project}
fi

# declare counting variables
declare -i n_fetch=0
declare -i n_fetch_fail=0
declare -i n_found=0
declare -i n_fpull=0
declare -i n_git=0
declare -i n_loops=0
declare -i n_match=0
declare -i n_pull=0
declare -i n_push=0

# reset SSH status list
if [ -z ${host_bad:+dummy} ]; then
    export host_bad=''
fi
if [ -z ${host_OK:+dummy} ]; then
    export host_OK=''
fi

# list failures
loc_fail=''
unset upstream_fail
fetch_fail=''
pull_fail=''
push_fail=''

# list successes
loc_OK=''
git_OK=''
fetch_OK=''
pull_OK=''
push_OK=''
declare -a fpull_init=''

# list modifications
mod_repos=''
mod_files=''

# list stash
stash_list=''

# track push/pull times (ns)
t_fetch_max=0
t_pull_max=0
t_push_max=0

# track push/pull times (s)
fetch_max=0

# define timeout command
timeout_ver=$(timeout --version | head -1 | sed 's/^.*) //')
declare -i timeout_ver_maj=$(echo $timeout_ver | awk -F. '{print $1}')
declare -i timeout_ver_min=$(echo $timeout_ver | awk -F. '{print $2}')
to_base0="timeout"
if [[ $timeout_ver_min -gt 4 ]]; then
    to_base0+=" --foreground --preserve-status"
fi
to_base0+=" -s 9"
declare to_base="${to_base0}"

# beautify settings
GIT_HIGHLIGHT='\E[7m'

check_git

for repo in $list; do
    start_new_line
    hline 70
    #------------------------------------------------------
    # find
    #------------------------------------------------------
    echo -e "locating ${PSDIR}$repo${RESET}... \c"
    if [ -e ${HOME}/$repo ]; then
        echo -e "${GOOD}OK${RESET}"
        ((++n_found))
    else
        echo -e "${BAD}FAIL${RESET}"
        if [ ! -z ${loc_fail:+dummy} ]; then
            loc_fail+=$'\n'"$repo"
        else
            loc_fail+="$repo"
        fi
        unset_traps
        bash test_file ${HOME}/$repo
        reset_traps
        continue
    fi
    #------------------------------------------------------
    # check
    #------------------------------------------------------
    cd ${HOME}/$repo
    unset_traps
    check_repo
    RETVAL=$?
    reset_traps
    if [[ $RETVAL -gt 0 ]]; then
        if [ ! -z ${loc_fail:+dummy} ]; then
            loc_fail+=$'\n'"$repo"
        else
            loc_fail+="$repo"
        fi
        continue
    fi

    # increment git counter
    ((++n_git))
    
    # parse remote
    echo -n "${TAB}checking remote tracking branch... "
    # set shell options
    if [[ "$-" == *e* ]]; then
        # exit on errors must be turned off; otherwise shell will exit no remote branch found
        old_opts=$(echo "$-")
        set +e
    fi
    unset_traps
    git rev-parse --abbrev-ref @{upstream} &>/dev/null
    RETVAL=$?
    reset_shell ${old_opts-''}
    reset_traps
    if [[ $RETVAL -ne 0 ]]; then
        echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
        do_cmd git rev-parse --abbrev-ref @{upstream}
        echo "${TAB}no remote tracking branch set for current branch"
        decho "skipping..."
        upstream_fail+=( "${repo}" )
        check_mod                
        continue
    fi            
    remote_tracking_branch=$(git rev-parse --abbrev-ref @{upstream})
    echo "$remote_tracking_branch"
    
    upstream_repo=${remote_tracking_branch%%/*}
    if [ $git_ver_maj -lt 2 ]; then
        upstream_url=$(git remote -v | grep ${upstream_repo} | awk '{print $2}' | uniq)
    else
        upstream_url=$(git remote get-url ${upstream_repo})
    fi
    # add remote to list
    echo "${upstream_url}" >>${list_remote}
    
    # check against argument    
    if [ $# -gt 0 ]; then
        for arg in $@; do
            echo -en "${TAB}checking argument \x1b[36m$arg\x1b[m... "
            if [[ $upstream_url =~ $arg ]]; then
                echo -e "${GOOD}OK${RESET}"
                ((++n_match))
                do_skip=false
                break
            else
                echo -e "${GRAY}SKIP${RESET}"
                do_skip=true
            fi
        done
        if [ ${do_skip} = 'true' ]; then
            continue
        fi
    fi

    # add to list
    if [ ! -z ${git_OK:+dummy} ]; then
        git_OK+=$'\n'
    fi
    git_OK+=${upstream_url}

    # check remotes
    if [ $DEBUG -gt 0 ]; then
        cbar "${BOLD}check remotes...${RESET}"
    fi

    check_remotes $@

    # parse remote
    upstream_refspec=${remote_tracking_branch#*/}
    # print remote parsing
    if [ $DEBUG -gt 0 ]; then
        cbar "${BOLD}parse remote tracking branch...${RESET}"
        (
            echo -e "${TAB}remote tracking branch+ ${BLUE}${remote_tracking_branch}${RESET}"
            echo "${TAB}${fTAB}remote name+ $upstream_repo"
            echo "${TAB}${fTAB}remote refspec+ $upstream_refspec"
        ) | column -t -s+ -o : -R 1

    fi

    # parse protocol
    upstream_pro=$(echo ${upstream_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
    if [[ "${upstream_pro}" == "git" ]]; then
        upstream_pro="SSH"
        upstream_host=$(echo ${upstream_url} | sed 's/\(^[^:]*\):.*$/\1/')
    else
        upstream_host=$(echo ${upstream_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
        if [[ ! "${upstream_pro}" == "http"* ]]; then
            upstream_pro="local"
        fi
    fi

    # check remote host name against list of checked hosts
    decho "checking $upstream_host against list of checked hosts"
    if [ ! -z ${host_OK:+dummy} ]; then
        for OK_host in ${host_OK}; do
            if [[ "$upstream_host" == "$OK_host" ]]; then
                decho -e "$upstream_host matches ${GOOD}$OK_host${RESET}"
                host_stat=$(echo -e "${GOOD}OK${RESET}")
                break
            fi
        done
    fi

    if [ ! -z ${host_bad:+dummy} ]; then
        for bad_host in ${host_bad}; do
            if [[ "$upstream_host" == "$bad_host" ]]; then
                decho -e "$upstream_host matches ${BAD}$bad_host${GOOD}"
                ((++n_fetch_fail))
                fetch_fail+="$repo ($upstream_repo) "$'\n'
                host_stat=$(echo -e "${BAD}FAIL${RESET}")
                continue 2
            fi
        done
    fi

    # print host parsing
    if [ $DEBUG -gt 0 ]; then
        cbar "${BOLD}parse remote host...${RESET}"
        (
            echo "${TAB}upsream url+ ${upstream_url}"
            echo -e "${TAB}${fTAB} host+ $upstream_host ${host_stat}"
            echo -e "${TAB}${fTAB}proto+ ${upstream_pro}"
        ) | column -t -s+ -o : -R 1
    fi

    if [[ "$host_stat" =~ *"FAIL"* ]]; then
        decho "skipping fetch..."
        exit_on_fail
        continue
    else
        decho "proceeding with fetch..."
    fi

    #------------------------------------------------------
    # fetch
    #------------------------------------------------------
    echo -n "${TAB}fetching... "
    # specify number of seconds before kill
    nsec=3
    if [ $fetch_max -gt $nsec ]; then
        nsec=$fetch_max
    fi
    to="${to_base} ${nsec}s "
    # concat commands
    cmd_base="git fetch"
    if [ $DEBUG -gt 0 ]; then
        cmd_base+=" --verbose"
    else
        cmd_base+=" --quiet"
    fi
    cmd="${to}${cmd_base}"
    RETVAL=137
    n_loops=0
    while [ $n_loops -lt 5 ]; do
        ((++n_loops))
        if [ $n_loops -gt 1 ]; then
            echo -n "${TAB}FETCH attempt $n_loops..."
        fi
        declare -i x1
        declare -i y1
        get_curpos x1 y1        
        t_start=$(date +%s%N)
        do_cmd_stdbuf ${cmd}        
        RETVAL=$?        
        t_end=$(date +%s%N)
        declare -i x2
        declare -i y2
        get_curpos x2 y2
        # check if cursor moved
        if [ $x1 = $x2 ] && [ $y1 == $y2 ]; then
            :
        else
            echo -ne "${GIT_HIGHLIGHT} fetch ${RESET} "
        fi       
        dt_fetch=$((${t_end} - ${t_start}))
        if [[ $RETVAL == 0 ]]; then
            echo -e "${GOOD}OK${RESET}"
            ((++n_fetch))
            break
        else
            echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
            #itab
            echo "${TAB}failed to fetch remote"
            if [[ $RETVAL == 137 ]]; then
                if [ $nsec -gt $fetch_max ]; then
                    fetch_max=$nsec
                    echo "${TAB}increasing fetch_max to $fetch_max"
                fi
                nsec=$((nsec * 2))
                echo "${TAB}increasing fetch timeout to ${nsec}"
                to="${to_base} ${nsec}s "
                cmd="${to}${cmd_base} --verbose --all"
            fi
            dtab
        fi
    done

    # update maximum fetch time
    if [[ ${dt_fetch} -gt ${t_fetch_max} ]]; then
        t_fetch_max=${dt_fetch}
        # print maximum fetch time (in ns)
        decho "${TAB}${fTAB}new maximum fetch time"
        decho "${TAB}${fTAB}   raw time: $t_fetch_max ns"
        declare -i nd=${#t_fetch_max}

        # define number of "decimals" for ns timestamp
        declare -i nd_max=9

        # pad timestamp with leading zeros
        if [ $nd -lt $nd_max ]; then
            fmt="%0${nd_max}d"
            declare time0=$(printf "$fmt" ${t_fetch_max})
            ddecho "${TAB}${fTAB}zero-padded: $time0"
            declare -i nd=${#time0}
            if [ $nd -eq ${nd_max} ]; then
                ddecho "${TAB}${fTAB}change in length"
                ddecho "${TAB}${fTAB}${nd} numbers long"
            else
                ddecho "${TAB}${fTAB}no change"
                exit 1
            fi
        else
            declare -i time0=t_fetch_max
        fi

        # format timestamp in s
        if [ $nd -gt $nd_max ]; then
            ni=$(($nd - $nd_max))
            ddeci=${time0:0:$ni}.${time0:$ni}
        else
            ddeci="0.${time0}"
        fi
        decho "${TAB}${fTAB}decimalized: $ddeci "

        # round timestamp to nearest second
        fmt="%.0f"
        deci=$(printf "$fmt" ${ddeci})
        decho "${TAB}${fTAB}integerized: $deci "
        if [ $deci -gt $fetch_max ]; then
            fetch_max=$deci
        fi
        decho "     fetch_max: $fetch_max"
    fi
    if [ $RETVAL -ne 0 ]; then
        fetch_fail+="$repo "
        echo -e "\E[32m> \E[0mWSL may need to be restarted"
        exit_on_fail
        echo -e "\e[7;33mPress Ctrl-C to cancel\e[0m"
        read -e -i "shutdown_wsl" -p $'\e[0;32m$\e[0m ' -t 10 && eval $REPLY
    fi

    #------------------------------------------------------
    # pull
    #------------------------------------------------------
    decho -n "leading remote commits: "
    N_remote=$(git rev-list HEAD..${remote_tracking_branch} | wc -l)
    if [ ${N_remote} -le ${GIT_OP_THRESH} ]; then
        decho "none"
        decho "${fTAB}no need to pull"
    else
        decho "${N_remote}"

        echo -n "${TAB}pulling... "
        cmd_base="git pull --all --progress --tags --verbose" #--prune"
        if [ $git_ver_maj -ge 2 ]; then
            cmd_base+=" --ff-only --ipv4"
        fi
        # specify number of seconds before kill
        nsec=4
        to="${to_base} ${nsec}s "
        # concat commands
        cmd="${to}${cmd_base}"
        RETVAL=137
        n_loops=0
        while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
            ((++n_loops))
            if [ $n_loops -gt 1 ]; then
                echo -n "${TAB}PULL attempt $n_loops..."
            fi
            t_start=$(date +%s%N)
            do_cmd_safe ${cmd}
            RETVAL=$?
            t_end=$(date +%s%N)
            dt_pull=$((${t_end} - ${t_start}))

            echo -en "${GIT_HIGHLIGHT} pull ${RESET} "
            if [[ $RETVAL != 0 ]]; then
                echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
                if [[ $RETVAL == 1 ]]; then
                    itab
                    echo -e "${TAB}merge conflicts found!"
                    itab
                    if [ $(git diff --name-only --diff-filter=M | wc -l) -gt 0 ]; then
                        echo -en "${TAB}modified files found, "
                        if [ $(git diff -w --diff-filter=M | wc -l) -gt 0 ]; then
                            echo "modifications are non-trivial: "
                            git diff --name-only --diff-filter=M 2>&1 | sed "s/.*/${TAB}${fTAB}\x1b[31m&\x1b[m/"
                            dtab 2
                            check_mod                
                            exit_on_fail
                        else
                            echo "modifications are trivial: "
                            git diff --name-only --diff-filter=M 2>&1 | sed "s/.*/${TAB}${fTAB}\x1b[33m&\x1b[m/"

                            echo "${TAB}checking out modified files..."
                            git diff --name-only --diff-filter=M | xargs -L 1 git checkout
                            
                            # reset RETVAL to stay in loop
                            RETVAL=137
                            dtab 2
                            continue                                    
                        fi
                    else
                        echo -e "${TAB}no modified files found"
                    fi

                    if [ $(git diff --name-only --diff-filter=U | wc -l) -gt 0 ]; then
                        echo -e "${TAB}unmerged files found"
                        git diff --name-only --diff-filter=U | sed "s/^/${fTAB}/"
                        dtab
                        exit_on_fail
                    else
                        echo -e "${TAB}no unmerged files found"
                    fi

                    if [ $(git ls-files -v | grep ^[[:lower:]] | awk '{print $2}' | wc -l) -gt 0 ]; then
                        echo -e "${TAB}ignored files found"
                        unchanged=$(git ls-files -v | grep ^[[:lower:]] | awk '{print $2}')
                        echo "$unchanged" | sed "s/^/${fTAB}/"
                        for file in $unchanged; do
                            git update-index --verbose --no-assume-unchanged $file
                        done
                        do_update=true
                        git stash -m "adding assume-unchanged files to stash"
                        echo "n_loops = $n_loops"
                        # reset RETVAL to stay in loop
                        RETVAL=137
                        dtab
                        continue
                    else
                        echo -e "${TAB}no untracked files found"
                    fi
                    dtab
                fi

                # increase time
                if [[ $RETVAL == 137 ]]; then
                    nsec=$((nsec * 2))
                    echo "${TAB}increasing pull timeout to ${nsec}"
                    to="${to_base} ${nsec}s "
                    cmd="${to}${cmd_base}"
                fi
                # force pull
                if [[ $RETVAL == 128 ]]; then
                    cbar "${GRH}force pull...${RESET}"
                    echo "${TAB}leading remote commits: ${N_remote}"
                    echo -n "${TAB}trailing local commits: "
                    N_local=$(git rev-list ${remote_tracking_branch}..HEAD | wc -l)
                    echo "${N_local}"
                    if [ $N_local -gt 0 ] && [ $N_remote -gt 0 ]; then
                        local_branch=$(git branch | grep \* | sed 's/^\* //')
                        echo -e "${fTAB}${YELLOW}local '${local_branch}' and remote '${remote_tracking_branch}' have diverged${RESET}"
                    fi
                    echo -e "${TAB}source directory = $src_dir_logi"
                    prog=${src_dir_logi}/force_pull
                    if [ -f ${prog} ]; then
                        ${prog}
                        RETVAL2=$?
                        dtab
                        echo -en "${GIT_HIGHLIGHT} force pull ${RESET} "
                        if [[ ${RETVAL2} != 0 ]]; then
                            echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL2${RESET}"
                            exit || return 1
                        else
                            echo -e "${GOOD}OK${RESET}"
                            ((++n_fpull))
                            fpull_init+=( "$repo" )
                            RETVAL=$RETVAL2
                        fi
                    fi
                fi
            else
                echo -e "${GOOD}OK${RESET}"
                ((++n_pull))
                if [ ! -z ${pull_OK:+dummy} ]; then
                    pull_OK+=$'\n'"$repo"
                else
                    pull_OK+="$repo"
                fi
            fi
        done

        # check if assume-unchanged files were stashed
        if [ -z ${do_update+dummy} ]; then
            decho "do_update is unset"
        else
            decho "do_update is set"
            if [[ ${do_update} == true ]]; then
                decho "do_update is true"
                echo "applying stash for assume-unchanged files..."
                do_cmd git stash pop
                unset do_update
                echo "updating index for assume-unchanged files..."
                for file in $unchanged; do
                    do_cmd git update-index --verbose --assume-unchanged $file
                done
            else
                echo "$do_update is not true"
                echo "$do_update = $do_update"
                exit 1
            fi
            dtab
        fi

        # check if maximum pull time increased
        if [[ ${dt_pull} -gt ${t_pull_max} ]]; then
            t_pull_max=${dt_pull}
        fi

        # check if pull was successful
        if [[ $RETVAL != 0 ]]; then
            # add to failure list
            pull_fail+="$repo "
            exit_on_fail
        else
            # update links after pull
            prog=make_links.sh
            echo -ne "${TAB}${prog}... \x1b[0m"
            if [ -f ${prog} ] || [ -f "bin/${prog}" ]; then
                if [[ ! (("$(hostname -f)" == *"navy.mil") && ($repo =~ "private")) ]]; then
                    echo "found"
                    if [ -f "bin/${prog}" ]; then
                        prog=bin/${prog}
                    fi
                    bash ${prog}
                else
                    echo "skip"
                fi
            else
                echo "not found"
            fi
        fi
    fi
    dtab

    #------------------------------------------------------
    # push
    #------------------------------------------------------
    decho -n "trailing local commits: "
    N_local=$(git rev-list ${remote_tracking_branch}..HEAD | wc -l)
    if [ ${N_local} -le ${GIT_OP_THRESH} ]; then
        decho "none"
        decho "${fTAB}no need to push"
    else
        decho "${N_local}"

        echo -n "${TAB}pushing... "
        cmd_base="git push --progress --verbose"
        if [ $git_ver_maj -ge 2 ]; then
            cmd_base+=" --ipv4"
        fi
        # specify number of seconds before kill
        nsec=2
        to="${to_base} ${nsec}s "
        # concat commands
        cmd="${to}${cmd_base}"
        RETVAL=137
        n_loops=0
        while [ $RETVAL -eq 137 ] && [ $n_loops -lt 5 ]; do
            ((++n_loops))
            if [ $n_loops -gt 1 ]; then
                echo -n "${TAB}PUSH attempt $n_loops..."
            fi
            t_start=$(date +%s%N)
            do_cmd ${cmd}
            RETVAL=$?
            t_end=$(date +%s%N)
            dt_push=$((${t_end} - ${t_start}))

            echo -en "${GIT_HIGHLIGHT} push ${RESET} "
            if [[ $RETVAL != 0 ]]; then
                echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
                if [[ $RETVAL == 137 ]]; then
                    nsec=$((nsec * 2))
                    echo "${TAB}increasing push timeout to ${nsec}"
                    to="${to_base} ${nsec}s "
                    cmd="${to}${cmd_base}"
                fi
            else
                echo -e "${GOOD}OK${RESET}"
                ((++n_push))
                if [ ! -z ${push_OK:+dummy} ]; then
                    push_OK+=$'\n'"$repo"
                else
                    push_OK+="$repo"
                fi

            fi
        done
        if [[ ${dt_push} -gt ${t_push_max} ]]; then
            t_push_max=${dt_push}
        fi
        if [[ $RETVAL != 0 ]]; then
            # add to failure list
            push_fail+="$repo "
            exit_on_fail
        fi
    fi

    check_mod

    echo -n "stash... "
    # check for stash entries
    N_stash=$(git stash list | wc -l)
    if [ $N_stash -gt 0 ]; then
        # get color index
        declare -i idx
        dbg2idx 4 idx
        # set color
        echo -ne "${dcolor[$idx]}"        
        echo -e "$repo has $N_stash entries in stash${RESET}"
        if [ ! -z ${stash_list:+dummy} ]; then
            stash_list+=$'\n'
        fi
        stash_list+=$(printf '%2d %s' $N_stash $repo)
    else
        echo -e "${GOOD}OK${RESET}"
    fi

    # to speed things up, only clean if repo has changed
    if [ ${N_remote} -gt ${GIT_OP_THRESH} ] || [ ${N_local} -gt ${GIT_OP_THRESH} ]; then 
        echo -n "${TAB}cleaning up... "
        unset_traps
        cmd="git gc"
        declare -i x1
        declare -i y1
        get_curpos x1 y1
        #DEBUG=1
        if [ $DEBUG -gt 0 ]; then
            echo
            # show command buffer
            do_cmd "${cmd}"
        else
            do_cmd ${cmd} -q
        fi
        RETVAL=$?
        #DEBUG=0
        reset_traps
        declare -i x2
        declare -i y2
        get_curpos x2 y2
        # check if cursor moved
        if [ $x1 = $x2 ] && [ $y1 == $y2 ]; then
            :
        else
            echo -en "${GIT_HIGHLIGHT} gc ${RESET} "
        fi       
        if [[ $RETVAL != 0 ]]; then
            echo -e "${BAD}FAIL${RESET} ${GRAY}RETVAL=$RETVAL${RESET}"
            exit_on_fail
            continue
        else
            echo -e "${GOOD}OK${RESET}"
        fi
    fi
done

cbar "done updating repositories"
echo "returning to starting directory ${start_dir}..."
cd ${start_dir}

# sort and uniquify remotes list
sort -u ${list_remote} -o ${list_remote}

# print list of remotes
echo -n "   all remotes: "
head -n 1 ${list_remote}
list_indent='                '
tail -n +2 ${list_remote} | sed "s/^/${list_indent}/"
echo
echo -n " these remotes: "
if [ -z "$git_OK" ]; then
    echo "none"
else
    git_OK=$(echo ${git_OK} | sed 's/ /\n/g' | sort -n)
    echo "${git_OK}" | head -n 1
    echo "${git_OK}" | tail -n +2 | sed "s/^/${list_indent}/"
    echo
fi

rtab
# print good hosts
if [ $DEBUG -ge 0 ]; then
    echo -n "${TAB}    good hosts: "
    if [ -z "${host_OK:+dummy}" ]; then
        echo "none"
    else
        host_OK=$(echo "${host_OK}" | sort -n)
        echo -e "${GOOD}${host_OK}${RESET}" | head -n 1
        echo -e "${GOOD}${host_OK}${RESET}" | tail -n +2 | sed "s/^/${list_indent}/"
        echo
    fi

    # print bad hosts
    echo -ne "${TAB}     bad hosts: "
    if [ -z "$host_bad" ]; then
        echo "none"
    else
        host_bad=$(echo "${host_bad}" | sort -n)
        echo -e "${BAD}${host_bad}${RESET}" | head -n 1
        echo -e "${BAD}${host_bad}${RESET}" | tail -n +2 | sed "s/^/${list_indent}/"
    fi
fi

echo

# print push/pull summary
# all
echo "    dirs found: ${n_found}"
echo "   repos found: ${n_git}"
echo -n "     not found: "
if [ -z "$loc_fail" ]; then
    echo "none"
else
    echo -ne "${BAD}"
    echo "${loc_fail}" | head -n 1
    echo "${loc_fail}" | tail -n +2 | sed "s/^/${list_indent}/"
    echo -ne "${RESET}"
fi

# matched
if [ $n_match -gt 0 ]; then
    echo "       matched: ${n_match} ($1)"
fi

# check if upstream fail is still unset
if [ -n "${upstream_fail+dummy}" ]; then
    echo -en "   no upstream: ${YELLOW}"
    (
        for repo in ${upstream_fail[@]}; do 
            echo "${repo}"
        done
    ) | sed "1! {s/^/${list_indent}/}"
fi
echo -en "${RESET}"

# fetched
echo -n "       fetched: "
if [ ${n_fetch} -eq 0 ]; then
    echo "none"
else
    echo "$n_fetch"
    echo -n "fetch max time: ${t_fetch_max} ns"
    if command -v bc &>/dev/null; then
        echo " or $(bc <<<"scale=3;$t_fetch_max/1000000000") sec"
    else
        echo
    fi
fi
echo -n "fetch failures: "
if [ -z "$fetch_fail" ]; then
    echo "none"
else
    echo -ne "${BAD}"
    echo "$n_fetch_fail"    
    echo "${fetch_fail}" \
        | sed "/^[[:space:]]*$/d" \
        | sed "s/^/${list_indent}/"
    echo -ne "${RESET}"
fi

# pull
echo -n "  repos pulled: "
if [ ${n_pull} -eq 0 ]; then
    echo "none"
else
    echo "${n_pull}"

    echo -ne "${GREEN}"
    echo "${pull_OK}" | sed "s/^/${list_indent}/"
    echo -ne "${RESET}"

    echo -n " pull max time: ${t_pull_max} ns"
    if command -v bc &>/dev/null; then
        echo " or $(bc <<<"scale=3;$t_pull_max/1000000000") sec"
    else
        echo
    fi
fi

echo -n " pull failures: "
if [ -z "$pull_fail" ]; then
    echo "none"
else
    echo -e "${GRH}$pull_fail${RESET}"
fi

echo -n "   force pulls: "
if [ $n_fpull -eq 0 ]; then
    echo "none"
else
    echo -e "${YELLOW}$n_fpull"
    for rep in ${fpull_init[@]}; do
        echo "${list_indent}${rep}"
    done
    echo -en "${RESET}"
fi

# push
echo -n "  repos pushed: "
if [ $n_push -eq 0 ]; then
    echo "none"
else
    echo "${n_push}"

    echo -ne "${GREEN}"
    echo "${push_OK}" | sed "s/^/${list_indent}/"
    echo -ne "${RESET}"

    echo -n " push max time: ${t_push_max} ns"
    if command -v bc &>/dev/null; then
        echo " or $(bc <<<"scale=3;$t_push_max/1000000000") sec"
    else
        echo
    fi
fi
echo -n " push failures: "
if [ -z "$push_fail" ]; then
    echo "none"
else
    echo -e "${GRH}$push_fail${RESET}"
fi

# modified
echo -n "      modified: "
if [ -z "$mod_repos" ]; then
    echo "none"
else
    echo "$mod_repos"
    echo -e "${YELLOW}$mod_files${RESET}" | sed "s/^/${list_indent}/"
fi

# stash
echo -n " stash entries: "
if [ -z "$stash_list" ]; then
    echo "none"
else
    # get color index
    declare  -i idx
    dbg2idx 4 idx
    # set color
    echo -ne "${dcolor[$idx]}"           
    stash_list=$(echo "${stash_list}" | sort -n)
    echo "${stash_list}" | head -n 1
    echo "${stash_list}" | tail -n +2 | sed "s/^/${list_indent}/"
    echo -ne "${RESET}"           
fi

set_traps
