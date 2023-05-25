#!/bin/bash
curl wttr.in 2>/dev/null | sed 's/^/\x1B[40;37m/;s/\x1B\[0m/\x1B[40;37m/g;s/46/0;46/'
echo -e "\x1b[0m"
