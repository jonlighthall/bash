#!/bin/bash

# Define the NTP server
NTP_SERVER="pool.ntp.org"

# Get the date and time from the NTP server
ntpdate -q $NTP_SERVER | grep -oP '(?<=server ).*?(?= offset)'

# Check if ntpdate command was successful
if [ $? -eq 0 ]; then
    echo "Time synchronized successfully."
else
    echo "Failed to synchronize time."
fi