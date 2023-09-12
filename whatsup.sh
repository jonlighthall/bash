#!/bin/bash
echo "   host:" $HOSTNAME
echo "display: $DISPLAY"
echo -n "     IP: ";hostname -i
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
echo "   user:" $USER$USERNAME
echo "user ID:" $UID
echo " groups:" `id -nG 2>/dev/null`
echo "    pwd:" $PWD
echo -n "   date: "; date
echo "    PID: $PPID"
echo -n "   time: "
if (ps -o etimes) &>/dev/null; then
    if command -v sec2elap &>/dev/null; then
	sec2elap $(ps -p "$PPID" -o etimes | tail -n 1)
    else
	echo "elapsed time is $(ps -p "$PPID" -o etimes | tail -n 1 | sed 's/\s//g') sec"
    fi
else
    echo $(ps -p $PPID -o etime)
fi

if [ -z $(hostname -d) ]; then
    echo "   path: $USER$USERNAME@$(hostname -I | sed 's/[ ]//'):$PWD"
else
    echo "   path: $USER$USERNAME@$HOSTNAME:$PWD"
fi
   
