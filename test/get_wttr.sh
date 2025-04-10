#!/bin/bash -u
curl wttr.in/30.4278,-90.0911?u1 2>/dev/null | sed 's/^/\x1B[40;37m/;s/\E\[0m/\E[40;37m/g;s/46/0;46/'
echo -e "\E[0m"
