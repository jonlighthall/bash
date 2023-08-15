#!/bin/bash
for i in {1..3}
do
echo -e "$i beeps \a"
sleep 1
done
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"