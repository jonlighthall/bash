#!/bin/bash -u
#
# whatsup.sh - show... what's up
#
# Mar 2019 JCL

# print host name
echo "    host:" $HOSTNAME

# print domain name if set
echo -n "  domain: "
$(hostname -y &>/dev/null)
DOM_RET_VAL=$?
DOMAIN=$(hostname -d)
if [ $DOM_RET_VAL -ne 0 ] || [ -z ${DOMAIN} ]; then
    echo -e "\E[31mnot set\E[0m"
else
    echo "${DOMAIN}"
fi

# print IP address
echo -n "      IP: "
IP=$(hostname -i | sed 's/^[^\.]* //')
echo -n "${IP}"
if [[ "${IP}" == "127.0.1.1" ]]; then
    echo -e " \E[31mnot set\E[0m"
else
    echo
fi

# select hostname or IP address for SSH path
if [ $DOM_RET_VAL -ne 0 ] || [ -z "${DOMAIN}" ]; then
    SSH_HOST=${IP}
else
    SSH_HOST=${DOMAIN}
fi

# print display
echo -n " display: "
if [ -z $DISPLAY ]; then
    echo -e "\E[31mnot set\E[0m"
fi
echo "$DISPLAY"

# print OS information
echo -n "      OS: "
if [ -f /etc/os-release ]; then
    \grep -i pretty /etc/os-release | sed 's/.*="\([^"].*\)"/\1/'
else
    if command -v lsb_release; then
        lsb_release -a 2>&1 | \grep "Description:" | sed -e 's/^Description:[\t]//'
    else
        cat /etc/*release | sort -u
    fi
fi
echo -n "  kernel: "
uname -srm

#
# Print user information
#
echo
echo -n "    user: "
if [ -z $USER ]; then
    if [ -z $USERNAME ]; then
        echo -e "\E[31mnot set\E[0m"
        UNAME=''
    else
        UNAME=$USERNAME
    fi
else
    UNAME=$USER
fi
echo $UNAME
echo " user ID:" $UID
echo "  groups:" $(id -nG 2>/dev/null)
#
# Print shell information
#
echo
echo "   shell: $SHELL"
echo "     PID: $PPID"
echo -n "    time: shell "
if (ps -o etimes) &>/dev/null; then
    if command -v sec2elap &>/dev/null; then
        bash sec2elap $(ps -p "$PPID" -o etimes | tail -n 1)
    else
        echo "elapsed time is $(ps -p "$PPID" -o etimes | tail -n 1 | sed 's/\s//g') sec"
    fi
else
    echo $(ps -p $PPID -o etime)
fi
echo -n "    date: "
date
#
# Print path information
#
echo
echo "    home:" $HOME
echo "     pwd:" $PWD
# print full path for SSH, etc.
echo -n "SSH path: $UNAME@"
if [[ "$HOSTNAME" == *"."* ]]; then
    echo -n "$HOSTNAME"
else
    echo -n "${SSH_HOST}"
fi
echo ":$PWD"
