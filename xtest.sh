#!/bin/bash -u
#
# xtest.sh - test if X11 is working by opening a list of default programs. The
# status of the programs is printed. The program waits for the user to hit any
# key in the terminal window and the opened programs are subsequently closed.

echo "${0##*/}"

# test X11
export LC_ALL=C
declare -a list_test
list_test=( "xeyes" "xclock -chime -update 1" "xcalc" "xman" "xlogo" "xterm" "xmessage hello")

declare -i DEBUG=${DEBUG-0}
declare -i i
if [ $DEBUG -gt 0 ]; then
    echo "elements:"
    for ((i=0; i<${#list_test[@]}; i++)); do
        echo "  $i: ${list_test[i]}"
    done
fi

declare -i len=0
declare -i ilen
declare -a list_prog

[ $DEBUG -gt 0 ] && echo "programs:"
for ((i=0; i<${#list_test[@]}; i++)); do
    list_prog[i]=${list_test[i]%% *}

    ilen=${#list_prog[i]}
    [ $DEBUG -gt 0 ] && echo "  $i: ${list_prog[i]} $ilen"

    if [ $ilen -gt $len ]; then
        len=ilen
    fi
done

if [ $DEBUG -gt 0 ]; then
    echo "arguments:"
    for ((i=0; i<${#list_test[@]}; i++)); do
        echo -n "  $i: "
        if [[ "${list_test[i]}" == *" "*  ]]; then
            echo "${list_test[i]#* }"
        else
            echo
        fi
    done
fi

function fill_dots() {
    echo -en "\E[${spp}G"
    for ((j=0; j<((dsp-1)); j++)); do
        echo -n "."
    done
    echo -en "\r"
}

# find programs
declare -a list_found

# lenght of prefix
declare -i spp
spp=$((9))
# length of argument
declare -i dsp
dsp=$((len + 5))
# total lenght
declare -i sp
sp=$((spp + dsp))

if [ $DEBUG -gt 0 ]; then
    echo "which:"
    sp=$((sp+16))
fi

for ((i=0; i<${#list_test[@]}; i++)); do
    [ $DEBUG -gt 0 ] && echo -en "  $i: ${list_test[i]%% *}\t"
	  which "${list_test[i]%% *}" &>/dev/null
	  RETVAL=$?
    fill_dots
    if [ $RETVAL = 0 ]; then
		    [ $DEBUG -gt 0 ] && echo -e "\E[${sp}G\E[32mOK\E[0m"
		    list_found+=("${list_test[i]}")
	  else
        echo -e "locating ${list_test[i]%% *}...\r\E[${sp}G\c"
		    echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	  fi
done

if [ -z "${list_found}" ]; then
	  echo -e "\E[31mFAIL\E[0m: no X11 programs found!"
    exit
fi

if [ $DEBUG -gt 0 ]; then
    echo "found"
    for ((i=0; i<${#list_found[@]}; i++)); do
        echo "  $i: ${list_found[i]%% *}"
    done
fi

[ $DEBUG -gt 0 ] && echo "open"
# open programs
declare -a list_open
for ((i=0; i<${#list_found[@]}; i++)); do
    [ $DEBUG -gt 0 ] && echo -en "  $i: ${list_found[i]%% *}\t"
	  ${list_found[i]} 2>/dev/null &
	  RETVAL=$?
    fill_dots
	  if [ $RETVAL = 0 ]; then
        [ $DEBUG -gt 0 ] && echo -e "\E[${sp}G\E[32mOK\E[0m"
		    list_open+=( "${list_found[i]}")
	  else
		    echo -e " opening ${list_found[i]}... \r\E[${sp}G\c"
		    echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	  fi
done

if [ -z "${list_open}" ]; then
    echo -e "\E[31mFAIL\E[0m: no X11 programs opened!"
    exit
fi

if [ $DEBUG -gt 0 ]; then
    echo "open"
    for ((i=0; i<${#list_open[@]}; i++)); do
        echo "  $i: ${list_open[i]}"
    done
fi

# check if programs are running
declare -a list_run
for ((i=0; i<${#list_open[@]}; i++)); do
    echo -en " opening ${list_open[i]%% *}..."
    echo -en "\E[${sp}G"
	  ps | grep "${list_open[i]%% *}" >/dev/null
	  RETVAL=$?
	  if [ $RETVAL = 0 ]; then
		    echo -e "\E[32mOK\E[0m"
		    list_run+=("${list_found[i]}")
	  else
		    echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	  fi
done

if [ -z "${list_run}" ]; then
    echo -e "\E[31mFAIL\E[0m: no X11 programs running!"
    exit
fi

# close windows
read -n 1 -s -r -p $'\E[32m> \E[0mPress any key to continue'
echo
for ((i=0; i<${#list_run[@]}; i++)); do
    fill_dots
    echo -en " closing ${list_run[i]%% *}..."
    echo -en "\E[${sp}G"
    pkill ${list_run[i]%% *}
	  RETVAL=$?
	  if [ $RETVAL = 0 ]; then
		    echo -e "\E[90mOK\E[0m"
	  else
		    echo -e "\E[31mFAIL \E[90mRETVAL=$RETVAL\E[0m"
	  fi
done
