#!/bin/bash
rm -r ens*
find -type f -not -name "reset.sh" -not -name "*.nc" -not -name "*.dat" -exec rm {} \;
