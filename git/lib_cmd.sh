# format command output
# handling is included for a variety of commands
# conditionally calls do_cmd_script, and do_cmd_stdbuf
function do_cmd() {
    local -i DEBUG=0
    # save command as variable
    cmd=$(echo $@)
    # format output
    itab
    if [ $DEBUG -gt 0 ]; then
        start_new_line
    fi
    decho "${TAB}running command $cmd... " 
    
    # get color index
    local -i idx
    dbg2idx 3 idx
    # set color
    echo -ne "${dcolor[$idx]}"

    # the ideal solution is to use unbuffer
    # check if unbuffer is defined
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
        # check if script is defined
        if command -v script >/dev/null; then
            ddecho "${TAB}printing command ouput typescript..."
            # print typescript command ouput
            dtab
            do_cmd_script $cmd
        else            
            ddecho "${TAB}printing buffered command ouput..."
            # print buffered command output
            dtab
            do_cmd_stdbuf $cmd
        fi
        local -i RETVAL=$?
    fi
    dtab
    
    # reset formatting
    unset_color
    if [ $DEBUG -gt 0 ]; then
        dtab
    fi
    return $RETVAL
}

# format command output using typescript
# developed for use with the command "git gc"
# output of "git gc" is written to stderr, but not to the terminal (tty)
# script captures all output in a pseudo-terminal (pty)
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
    # check if typescript is defined
    if command -v script >/dev/null; then
        ddecho "${TAB}printing command ouput typescript..."
        # set shell options
        set -o pipefail
        # print command output
        if false; then
            # command output is unbuffered only if "sed -u" is used!
            # however, this interfers with formatting the output
            script -eq -c "$cmd" \
                | sed -u 's/$\r/\n\r/g'
        else
            script -eq -c "$cmd" \
                | sed "s/\r.*//g;s/.*\r//g" \
                | sed 's/^[[:space:]].*//g' \
                | sed "/^$/d;s/^/${TAB}${dcolor[$idx]}/" \
                | sed '1 s/^/\n/' 
        fi
        local -i RETVAL=$?
        # reset shell options
        set +o pipefail
        # remove temporary file
        local fname=typescript
        if [ -f $fname ]; then
            rm typescript
        fi
    else
        ddecho "${TAB}printing unformatted ouput..."
        echo "no wrapper"
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

# format buffered command ouput
# save ouput to file, print file, delete file
# developed for use when unbuffer and script are unavailable
function do_cmd_stdbuf() {    
    cmd=$(echo $@)
    # define temp file
    temp_file=temp
    # format output
    itab    
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
            | sed -u '1 s/[A-Z]/\n&/' \
            | sed -u "s/\r$//g;s/.*\r/${TAB}/g;s/^/${TAB}/" \
            | sed -u "/^[^%|]*|/s/^/${dcolor[$idx+1]}/g; s/$/${dcolor[$idx]}/; /|/s/+/${GOOD}&/g; /|/s/-/${BAD}&/g; /modified:/s/^.*$/${BAD}&/g; /^\s*M\s/s/^.*$/${BAD}&/g"  
        
        # reset formatting
        unset_color
        if [ $DEBUG -gt 0 ]; then
            dtab
        fi
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

# run command after adjusting shell options and un-setting traps
function do_cmd_safe() {
    local -i DEBUG=0
    # save command as variable
    cmd=$(echo $@)
    # format output
    itab
    if [ $DEBUG -gt 0 ]; then
        start_new_line
    fi
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
    reset_shell ${old_opts-''}
    reset_traps
    
    # reset formatting
    unset_color

    return $RETVAL
}
