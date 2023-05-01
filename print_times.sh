#!/bin/sh
echo -n "UTC:   "; TZ='UTC' date
echo -n "GPS:   "; TZ='UTC' date --date='TZ="../leaps/UTC" now -9 seconds'
echo -n "LORAN: "; TZ='UTC' date --date='TZ="../leaps/UTC" now'
echo -n "TAI:   "; TZ='UTC' date --date='TZ="../leaps/UTC" now 10 seconds'
