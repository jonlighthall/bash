#!/bin/bash -u
#
# whatsup.sh - show... what's up
#
# Mar 2019 JCL

# parse options
VERBOSE=false
while getopts "v" opt; do
    case $opt in
        v) VERBOSE=true ;;
        *) echo "Usage: $0 [-v]" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------- #
# Network / Host
# ---------------------------------------------------------------------------- #

# print host name
echo "    host: $HOSTNAME"

# print domain name if set
echo -n "  domain: "
hostname -y &>/dev/null
DOM_RET_VAL=$?
DOMAIN=$(hostname -d)
if [ $DOM_RET_VAL -ne 0 ] || [ -z "${DOMAIN}" ]; then
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

# ---------------------------------------------------------------------------- #
# User / Path (needed for SSH path)
# ---------------------------------------------------------------------------- #

if [ -z "${USER:-}" ]; then
    if [ -z "${USERNAME:-}" ]; then
        UNAME=''
    else
        UNAME=$USERNAME
    fi
else
    UNAME=$USER
fi
echo "    user: $UNAME"
echo "     pwd: $PWD"

# print full path for SSH, etc.
echo -n "SSH path: $UNAME@"
if [[ "$HOSTNAME" == *"."* ]]; then
    echo -n "$HOSTNAME"
else
    echo -n "${SSH_HOST}"
fi
echo ":$PWD"

# exit here unless verbose
if ! $VERBOSE; then
    exit 0
fi

# ---------------------------------------------------------------------------- #
# Display
# ---------------------------------------------------------------------------- #
echo
echo -n " display: "
if [ -z ${DISPLAY+dummy} ]; then
    echo -e "\E[31mnot set\E[0m"
else
    echo "$DISPLAY"
fi

# ---------------------------------------------------------------------------- #
# OS / Hardware
# ---------------------------------------------------------------------------- #

echo -n "      OS: "
if [ -f /etc/os-release ]; then
    \grep -i pretty /etc/os-release | sed 's/.*="\([^"].*\)"/\1/'
else
    if command -v lsb_release &>/dev/null; then
        lsb_release -a 2>&1 | \grep "Description:" | sed -e 's/^Description:[\t]//'
    else
        sort -u /etc/*release
    fi
fi
echo -n "  kernel: "
uname -srm
echo -n "     CPU: "
if [ -f /proc/cpuinfo ]; then
    grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //'
elif command -v lscpu &>/dev/null; then
    lscpu | grep -m1 'Model name' | sed 's/.*:\s*//'
else
    uname -p
fi
echo -n "   cores: "
nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "unknown"
echo -n "   clock: "
if command -v lscpu &>/dev/null; then
    MHZ=$(lscpu | grep -i 'max mhz' | sed 's/.*:\s*//')
    if [ -n "${MHZ}" ]; then
        echo "${MHZ} MHz (max)"
    else
        MHZ=$(lscpu | grep -i 'cpu mhz' | sed 's/.*:\s*//')
        if [ -n "${MHZ}" ]; then
            echo "${MHZ} MHz"
        else
            echo "unknown"
        fi
    fi
elif [ -f /proc/cpuinfo ]; then
    echo "$(grep -m1 'cpu MHz' /proc/cpuinfo | sed 's/.*: //') MHz"
else
    echo "unknown"
fi
echo -n "  memory: "
free -h 2>/dev/null | awk '/Mem/{print $2}' || echo "unknown"
echo -n "  uptime: "
uptime -p 2>/dev/null || uptime | sed 's/.*up /up /;s/,.*load.*//' || echo "unknown"

# ---------------------------------------------------------------------------- #
# User details
# ---------------------------------------------------------------------------- #
echo
echo "    user: $UNAME"
if [ -z "$UNAME" ]; then
    echo -e "          \E[31mnot set\E[0m"
fi
echo " user ID: $UID"
echo "  groups: $(id -nG 2>/dev/null)"

# ---------------------------------------------------------------------------- #
# Shell
# ---------------------------------------------------------------------------- #
echo
echo "   shell: $SHELL"
echo -n " version: "
case "$(basename "$SHELL")" in
    bash) echo "${BASH_VERSION}" ;;
    zsh)  echo "${ZSH_VERSION}" ;;
    *)    "$SHELL" --version 2>/dev/null | head -1 || echo "unknown" ;;
esac
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

# ---------------------------------------------------------------------------- #
# Paths
# ---------------------------------------------------------------------------- #
echo
echo "    home: $HOME"
echo "     pwd: $PWD"
# print full path for SSH, etc.
echo -n "SSH path: $UNAME@"
if [[ "$HOSTNAME" == *"."* ]]; then
    echo -n "$HOSTNAME"
else
    echo -n "${SSH_HOST}"
fi
echo ":$PWD"
