#!/bin/bash

# Progress Report Function
# This file contains a reusable progress reporting function that can be sourced by other scripts.

# Color definitions (with fallbacks if not set)
WHITE=${WHITE:-'\033[37m'}
YELLOW=${YELLOW:-'\033[33m'}
GRAY=${GRAY:-'\033[90m'}
RESET=${RESET:-'\033[0m'}

progress_report() {
    # Function to report progress
    # Usage: progress_report <count> <total>
    # Example: progress_report 50 1000
    # This function prints dots and percentages to indicate the incremental
    # progress of a task.

    # The percent per line (typically 10) and the dots per line (typically 10)
    # are hardcoded to 10, but can be changed if needed.

    # It assumes count is the current count and total is the total number of items
    # Dots are printed based on dot_interval calculations
    # Percentages are printed based on percentage_interval calculations
    if [ "$#" -ne 2 ]; then
        echo "Usage: progress_report <count> <total>"
        return 1
    fi

    # Check if both arguments are numbers
    if ! [[ "$1" =~ ^[0-9]+$ && "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: Both arguments to progress_report must be numbers."
        return 1
    fi

    # Convert arguments to base 10 numbers to avoid octal interpretation
    local -i count=$((10#$1)) # numerator
    local -i total=$((10#$2)) # denominator

    if ((total == 0)); then
        echo "Error: total cannot be 0"
        return 1
    fi

    local -i dots_per_line=10                                    # number of dots per line
    local -i percentage_per_line=10                              # percentage per line
    local -i total_dots=$((dots_per_line * percentage_per_line)) # total number of dots

    local -i percentage_interval=$((total / percentage_per_line)) # percentage per line
    if ((percentage_interval == 0)); then
        percentage_interval=1
    fi
    local -i dot_interval=$((total / total_dots))                 # dots per line
    if ((dot_interval == 0)); then
        dot_interval=1
    fi

    # debugging flags
    local print_debug_perc=false
    local print_debug_dot=false

    if ((count % percentage_interval == 0)); then
        if ((count == 0)); then
            # Print a new line at the start
            # This assumes that the function is called after a prompt with no
            # new line, such as "working..."
            echo
            # indent each line if TAB is set
            echo -n "${TAB-}"
        else
            # Calculate the intended percentage (10%, 20%, 30%, etc.)
            # instead of the actual percentage to handle edge cases
            intended_perc=$((count / percentage_interval * 10))
            echo " ${intended_perc}%"
            echo -n "${TAB-}"
        fi

        if $print_debug_perc; then
            echo "1234567890 DEBUG: count=$count, total=$total, dot_int=$dot_interval, perc_int=$percentage_interval, count mod dot=$((count % dot_interval)), count mod perc=$((count % percentage_interval))"
            echo "perc_tot=$((percentage_interval * percentage_per_line)), dot_tot=$((dot_interval * total_dots)), dot perc int= $((dot_interval * dots_per_line))"

            last_percentage=$(((count / (total / 10)) - 1))
            last_count=$((last_percentage * (total / 10)))
            dcount=$((count - last_count))
            last_dot=$((last_count / dot_interval))
            this_dot=$((count / dot_interval))
            ddot=$((this_dot - last_dot))
            echo "Last percentage: $last_percentage, last count: $last_count"
            echo "dcount: $dcount"
            echo "Last dot: $last_dot"
            echo "This dot: $this_dot"
            echo "ddot: $ddot"
            # Print a newline after every 10% to keep the output clean
            echo
        fi
    else
        if (((count % dot_interval) == 0)); then
            # Time to print a dot...

            # But first, calculate how many dots have been printed so far on this line
            last_percentage=$(((count / (total / 10))))    # last percentage printed
            last_count=$((last_percentage * (total / 10))) # count at last percentage
            last_dot=$((last_count / dot_interval))        # last dot of last line
            this_dot=$((count / dot_interval))             # candidate dot (current dot)
            ddot=$((this_dot - last_dot))                  # Nth dot of this line (current dot)

            if [ "$print_debug_dot" = true ]; then
                dcount=$((count - last_count))
                echo "Last percentage: $last_percentage, last count: $last_count"
                echo "dcount: $dcount"
                echo "Last dot: $last_dot"
                echo "This dot: $this_dot"
                echo "ddot: $ddot"
            fi
            # ...and print exactly N dots per line
            if ((ddot <= dots_per_line)); then
                echo -n "."
            fi
        fi # end of if dot_interval
    fi # end of if percentage_interval
}

function print_time() {
    # check if start time is defined
    if [ -n "${start_time+alt}" ]; then
        # get the length of the execution stack
        local -i N_BASH=${#BASH_SOURCE[@]}
        # BASH_SOURCE counts from zero; get the bottom of the stack
        # print file name of the calling function
        echo -ne "${TAB}${GRAY}${BASH_SOURCE[(($N_BASH - 1))]##*/} "
        # print elapsed time and change color
        print_elap | sed 's/37m/90m/'
        echo
    fi
}

GET_ELAP_TIME() {
    # This function returns the elapsed time in nanoseconds
    # It assumes that start_time is set
    if [ -n "${start_time+alt}" ]; then
        local -i end_time=$(date +%s%N)
        elap_time=$((end_time - start_time))
        export elap_time
    else
        echo "Error: start_time is not defined."
        return 1
    fi
}

function calibrate_time() {
    # check if start time is defined
    if [ -n "${start_time+alt}" ]; then
       GET_ELAP_TIME
        # Suggest a new calibration constant to target 1e9 ns (1 second)

        # Ensure elap_time is set

        if [ "${elap_time}" -gt 0 ]; then
            local -i suggested_calibration=$((CALIBRATION_CONSTANT * 1000000000 / elap_time))
            if [ "$suggested_calibration" -eq "$CALIBRATION_CONSTANT" ]; then
                echo -e "${YELLOW}Calibration is already optimal.${RESET}" >&2
            else
                echo -e "${YELLOW}Current CALIBRATION_CONSTANT is ${CALIBRATION_CONSTANT}.${RESET}" >&2
            fi
            echo -e "Suggested CALIBRATION_CONSTANT for ~1s: ${WHITE}${suggested_calibration}${RESET}" >&2
        fi
    fi
}




function print_elap() {
    # check if start time is defined
    if [ -n "${start_time+alt}" ]; then
   GET_ELAP_TIME


        # convert to seconds
        local dT_sec
        if command -v bc &>/dev/null; then
            dT_sec=$(bc <<<"scale=9;$elap_time/10^9" | sed 's/^\./0./')
        else
            dT_sec=${elap_time::-9}.${elap_time:$((${#elap_time} - 9))}
            if [ ${#elap_time} -eq 9 ]; then
                dT_sec=$(echo "0.$elap_time")
            fi
        fi
        # set precision
        local -ir nd=3
        # format interval
        local fmt="%.${nd}f"
        dT_sec=$(printf "$fmt" $dT_sec)

        # print output
        if command -v sec2elap &>/dev/null; then
            bash sec2elap $dT_sec | tr -d "\n" >&2
        else
            echo -ne "elapsed time is ${WHITE}${dT_sec} sec${RESET}" >&2
        fi
    else
        echo -ne "${YELLOW:-}start_time not defined${RESET:-} " >&2
        # reset cursor position for print_done, etc.
        echo -en "\x1b[1D" >&2
    fi

    # print elap_time right-aligned, 9 spaces wide
        printf "\n   DEBUG elap: ${WHITE}%9d ns${RESET}\n" "$elap_time"
}

function nsleep() {
    # Check if the argument is only zeros and, optionally, a decimal point
    if [[ "$1" =~ ^0*\.?0*$ ]]; then
        #    echo "No sleep requested, returning immediately."
        return 0
    fi

    local -i start_sleep=$(date +%s%N)
    # echo "input: $1"
    if [ -z "$1" ]; then
        set -- 1.0
    fi
    in_duration="$1"
    duration_sec=$(echo "$in_duration" | sed 's/^\./0./') # add leading zero if needed
    if [[ ! "$duration_sec" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: sleep duration must be a non-negative number."
        return 1
    fi
    # echo "duration_sec: $duration_sec"

    # Convert input seconds (possibly floating point) to integer nanoseconds
    if command -v bc &>/dev/null; then
        duration_ns=$(echo "$1 * 1000000000 / 1" | bc)
    else
        duration_ns=$(awk "BEGIN {printf \"%d\", $1 * 1000000000}")
    fi
    # Check if the conversion was successful
    if [[ ! "$duration_ns" =~ ^[0-9]+$ ]]; then
        echo "Error: sleep duration must be a non-negative number."
        return 1
    fi
    #echo "duration_ns: $duration_ns"

    # Print duration_ns with thousands separators (groups of three from the right)
    #duration_ns_fmt=$(echo "$duration_ns" | rev | sed 's/\(...\)/\1,/g' | rev | sed 's/^_//;s/_$//;s/^,//')
    #echo "duration: $duration_ns_fmt ns"

    #echo "Sleeping for $1 ns..."

    local -i end_sleep=$(date +%s%N)
    local -i elap_time=$((${end_sleep} - ${start_sleep}))

    # calibration factor
    local -i cal_factor=9400000 # return time in ns

    if ((duration_ns < cal_factor)); then
        #echo "Duration is less than $cal_factor ns, returning immediately."
        return 0
    else
        duration_ns_cal=$((${duration_ns} - ${cal_factor}))
        #   echo "calibrated duration: $duration_ns_cal ns"
    fi

    while ((elap_time < duration_ns_cal)); do
        end_sleep=$(date +%s%N)
        elap_time=$((${end_sleep} - ${start_sleep}))
        #       echo $elap_time
    done
}

function no_sleep() {
    local -i start_sleep=$(date +%s%N)
    local -i end_sleep=$(date +%s%N)
    local -i elap_time=$((${end_sleep} - ${start_sleep}))
    echo "elap: $elap_time ns"
}

CALIBRATION_CONSTANT=330

function do_nothing() {
    # This function does nothing, but can be used to simulate work
    # It causes a delay of about 1 millisecond

    for ((i = 0; i < CALIBRATION_CONSTANT; i++)); do
        : # Do nothing
    done

}

function mili_sleep() {
    if [ -z "$1" ]; then
        msecs=1
    else
        msecs=$1
    fi

    for ((i = 0; i <= msecs; i++)); do
        do_nothing
    done
}

# Example usage
count_max=1000
# Count to 1,000 using various delay methods to try to acheive sub-second delays
# each loop iteration should take about 1 millisecond
# each test should take about 1 second


echo -n "Counting to $count_max using do_nothing... "
# get starting time in nanoseconds
start_time=$(date +%s%N)
for ((count = 0; count <= count_max; count++)); do
     progress_report "$count" "$count_max"
    # Simulate some work
    #sleep 0.001 # Simulate work with a sleep
    #sleep 1e-6
    do_nothing
done
calibrate_time

start_time=$(date +%s%N)
print_time

return 2>/dev/null || exit 0


    echo -n "Counting to $count_max (no delay)... "
    # reset start_time for the next test
    start_time=$(date +%s%N)
    for ((count = 0; count <= count_max; count++)); do
        progress_report "$count" "$count_max"

    done
    print_time

    echo -n "Counting to $count_max using null command... "
    # reset start_time for the next test
    start_time=$(date +%s%N)
    for ((count = 0; count <= count_max; count++)); do
        progress_report "$count" "$count_max"
        : # Simulate some work

    done
    print_time
print_time


echo -n "Counting to $count_max using do_nothing... "
# get starting time in nanoseconds
start_time=$(date +%s%N)
for ((count = 0; count <= count_max; count++)); do
     progress_report "$count" "$count_max"
    # Simulate some work
    #sleep 0.001 # Simulate work with a sleep
    #sleep 1e-6
    do_nothing
done
print_time



echo -n "Counting to $count_max using nsleep... "
declare -i start_time=$(date +%s%N)
for ((count = 0; count <= count_max; count++)); do
     progress_report "$count" "$count_max"
    # Simulate some work
    nsleep 1000000 # Simulate work with a sleep
done
print_time

echo -n "Counting to $count_max using mili_sleep... "
# reset start_time for the next test
start_time=$(date +%s%N)
for ((count = 0; count <= count_max; count++)); do
     progress_report "$count" "$count_max"
    # Simulate some work
    mili_sleep 1

done
echo "done"
print_time