#!/bin/bash
rm -r ens*
find -type f -not -path "./.git/*" -not -name ".git*" -not -name "*.nc" -not -name "*.dat" -exec rm {} \;
