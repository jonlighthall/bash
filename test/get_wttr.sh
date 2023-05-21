#!/bin/bash
curl wttr.in 2>/dev/null | sed "s/^/\x1B[40;37m/" | sed 's/\x1B\[0m/\x1B[40;37m/g'
#curl wttr.in 2>/dev/null | sed 's/\x1B\[0m/\x1B[40m/g'
echo -e "\x1b[0m"
