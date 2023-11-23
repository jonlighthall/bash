#!/bin/bash
echo "   host:" $HOSTNAME
echo -n "display: "
if [ -z $DISPLAY ]; then
    echo -e "\x1b[31mnot set\x1b[0m"
fi
echo "$DISPLAY"
echo -n "     IP: "
hostname -i | sed 's/^[^\.]* //'
echo -n "     OS: "
if [ -f /etc/os-release ]; then
    \grep -i pretty /etc/os-release | sed 's/.*="\([^"].*\)"/\1/'
else
    if command -v lsb_release; then
        lsb_release -a 2>&1 | \grep "Description:" | sed -e 's/^Description:[\t]//'
    else
        cat /etc/*release | sort -u
    fi
fi
echo -n "   user: "
if [ -z $USER ]; then
    if [ -z $USERNAME ]; then
        echo -e "\x1b[31mnot set\x1b[0m"
        UNAME=''
    else
        UNAME=$USERNAME
    fi
else
    UNAME=$USER
fi
echo $UNAME
echo "user ID:" $UID
echo " groups:" $(id -nG 2>/dev/null)
echo "    pwd:" $PWD
echo -n "   date: "
date
echo "    PID: $PPID"
echo -n "   time: "
if (ps -o etimes) &>/dev/null; then
    if command -v sec2elap &>/dev/null; then
        bash sec2elap $(ps -p "$PPID" -o etimes | tail -n 1)
    else
        echo "elapsed time is $(ps -p "$PPID" -o etimes | tail -n 1 | sed 's/\s//g') sec"
    fi
else
    echo $(ps -p $PPID -o etime)
fi
echo -n "   path: $UNAME@"

for arg in a d f i I y ; do
    echo "$arg"
    timeout -s 9 1s hostname "-${arg}"
done

if [[ "$HOSTNAME" == *"."* ]]; then
    echo -n "$HOSTNAME"
else
    if [ -z $(hostname -d) ]; then
        echo -n  "$(hostname -I | sed 's/ .*$//')"
    else
        echo "fail"
    fi
fi
echo ":$PWD"
