#!/bin/bash
echo "   host:" $HOSTNAME
echo "display: $DISPLAY"
echo -n "     IP: ";hostname -I
echo -n "     OS: "
lsb_release -a 2>&1 | \grep "Description:" | sed -e 's/^Description:[\t]//'
echo "   user:" $USER$USERNAME
echo " groups:" `id -nG 2>/dev/null`
echo "    pwd:" $PWD
echo -n "   date:"; date
echo "    PID: $PPID"
echo -n "   time: "
if (ps -o etimes) &>/dev/null; then
    if command -v sec2elap &>/dev/null; then
	echo "$(sec2elap $(ps -p "$PPID" -o etimes | tail -n 1))"
    else
	echo "elapsed time is $(ps -p "$PPID" -o etimes | tail -n 1 | sed 's/\s//g') sec"
    fi
else
    echo $(ps -p $PPID -o etime)
fi
echo "   path: $USER$USERNAME@$HOSTNAME:$PWD"
