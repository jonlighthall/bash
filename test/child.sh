#!/bin/bash
set -e # exit on non-zero status
echo "running ${0##*/}"
echo "in ${0%/*}"
echo "called by $(ps -o comm= $PPID)"
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"