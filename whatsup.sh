#!/bin/bash
echo "   host:" $HOSTNAME
echo -n "     IP: ";hostname -I
echo -n "     OS: "
lsb_release -a 2>&1 | \grep "Description:" | sed -e 's/^Description:[\t]//'
echo "   user:" $USER$USERNAME
echo " groups:" `id -nG`
echo "    pwd:" $PWD
echo "   date:" $(date)
echo "    PID: $PPID"
echo -n "   time: "
if (ps -o etimes) &>/dev/null; then
    echo "$(sec2elap $(ps -p "$PPID" -o etimes | tail -n 1))"
else
    echo $(ps -p $PPID -o etime)
fi
echo "   path: $USER$USERNAME@$HOSTNAME:$PWD"
