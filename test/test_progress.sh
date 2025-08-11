#!/bin/bash

# Progress Report Function
# This file contains a reusable progress reporting function that can be sourced by other scripts.

# Color definitions (with fallbacks if not set)
WHITE=${WHITE:-'\033[37m'}
YELLOW=${YELLOW:-'\033[33m'}
GRAY=${GRAY:-'\033[90m'}
RESET=${RESET:-'\033[0m'}

# Global calibration constants
readonly MS_CALIB_LVL1=343 # do_nothing() loop iterations
readonly MS_CALIB_LVL2=107       # millisecond delay calibration

NOTHING_DELAY=0

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

GET_ELAP_TIME() {
    # Calculate elapsed time in nanoseconds from global start_time
    # Sets global variable: elap_time
    # Returns: 0 on success, 1 on error

    if [[ -z "${start_time:-}" ]]; then
        echo "Error: start_time is not defined." >&2
        return 1
    fi

    if [[ ! "$start_time" =~ ^[0-9]+$ ]]; then
        echo "Error: start_time is not a valid number." >&2
        return 1
    fi

    local -i end_time
    end_time=$(date +%s%N)
    elap_time=$((end_time - start_time))

    # Validate result
    if [[ "$elap_time" -lt 0 ]]; then
        echo "Warning: Negative elapsed time detected. Clock may have changed." >&2
        elap_time=0
    fi
}

function calibrate_time_lvl1() {
    # Suggest calibration constant to achieve target duration
    # Usage: calibrate_time_lvl1_ms <target_seconds>

    if [[ "$#" -ne 1 ]]; then
        echo "Error: calibrate_time_lvl1_ms requires exactly one argument (target seconds)" >&2
        return 1
    fi

    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: Target seconds must be a positive integer" >&2
        return 1
    fi

    if [[ -z "${start_time:-}" ]]; then
        echo "Error: start_time is not defined. Cannot calibrate." >&2
        return 1
    fi

    if ! GET_ELAP_TIME; then
        return 1
    fi

    if [[ "$elap_time" -gt 0 ]]; then
        local -i target_ns=$((1000000000 * $1))  # Convert seconds to nanoseconds
        local -i suggested_calibration=$((MS_CALIB_LVL1 * target_ns / elap_time))

        if [[ "$suggested_calibration" -eq "$MS_CALIB_LVL1" ]]; then
            echo -e "${YELLOW}Calibration is already optimal.${RESET}" >&2
        else
            echo -e "${YELLOW}Current MS_CALIB_LVL1 is ${MS_CALIB_LVL1}.${RESET}" >&2
            echo -e "Suggested MS_CALIB_LVL1 for ~${1}s: ${WHITE}${suggested_calibration}${RESET}" >&2
        fi
    else
        echo "Error: Invalid elapsed time for calibration" >&2
        return 1
    fi
}

function calibrate_time_lvl2() {
    # Suggest calibration constant to achieve target duration
    # Usage: calibrate_time_lvl2 <target_seconds>

    if [[ "$#" -ne 1 ]]; then
        echo "Error: calibrate_time_lvl2 requires exactly one argument (target seconds)" >&2
        return 1
    fi

    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: Target seconds must be a positive integer" >&2
        return 1
    fi

    if [[ -z "${start_time:-}" ]]; then
        echo "Error: start_time is not defined. Cannot calibrate." >&2
        return 1
    fi

    if ! GET_ELAP_TIME; then
        return 1
    fi

    if [[ "$elap_time" -gt 0 ]]; then
        local -i target_ns=$((1000000000 * $1))  # Convert seconds to nanoseconds
        local -i suggested_calibration=$((MS_CALIB_LVL2 * target_ns / elap_time))

        if [[ "$suggested_calibration" -eq "$MS_CALIB_LVL2" ]]; then
            echo -e "${YELLOW}Calibration is already optimal.${RESET}" >&2
        else
            echo -e "${YELLOW}Current MS_CALIB_LVL2 is ${MS_CALIB_LVL2}.${RESET}" >&2
            echo -e "Suggested MS_CALIB_LVL2 for ~${1}s: ${WHITE}${suggested_calibration}${RESET}" >&2
        fi
    else
        echo "Error: Invalid elapsed time for calibration" >&2
        return 1
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

function do_nothing() {
    # CPU-based delay function for timing calibration
    # Performs empty loop iterations based on MS_CALIB_LVL1
    # Usage: do_nothing

    local -i i
    for ((i = 0; i < NOTHING_DELAY; i++)); do
        : # No-op command
    done
}

function milli_sleep() {
    # Sleep for specified milliseconds using CPU-based delay
    # Usage: milli_sleep <milliseconds>
    local -i msecs=${1:-1}  # Default to 1 if no argument provided

    # Validate input
    if [[ ! "$1" =~ ^[0-9]+$ ]] && [[ -n "$1" ]]; then
        echo "Error: milli_sleep requires a positive integer" >&2
        return 1
    fi

    NOTHING_DELAY=${MS_CALIB_LVL2}

    for ((i = 0; i <= msecs; i++)); do
        do_nothing
    done
}

# =============================================================================
# MAIN EXECUTION - Performance Testing
# =============================================================================

# Test configuration
readonly count_max=1000
echo "Starting performance tests with $count_max iterations each..."
echo "Target: ~1 second per test"
echo

# Test 1: CPU-based delay with do_nothing()
echo -n "Test 1/2: Counting to $count_max using do_nothing... "
NOTHING_DELAY=${MS_CALIB_LVL1}
start_time=$(date +%s%N)
for ((count = 0; count <= count_max; count++)); do
     progress_report "$count" "$count_max"
    do_nothing
done
calibrate_time_lvl1 1
print_time
#exit
#echo

# Quick timing test
echo "Timing overhead test..."
start_time=$(date +%s%N)
print_time
#echo

# Test 2: CPU-based delay with milli_sleep()
echo -n "Test 2/2: Counting to $count_max using milli_sleep... "
start_time=$(date +%s%N)
for ((count = 0; count <= count_max; count++)); do
     progress_report "$count" "$count_max"
    milli_sleep 1
done
calibrate_time_lvl2 1
print_time
#echo


# Test 3: CPU-based delay with milli_sleep()
count_max=100
echo -n "Test 3/2: Counting to $count_max using milli_sleep... "
start_time=$(date +%s%N)
for ((count = 0; count <= count_max; count++)); do
     progress_report "$count" "$count_max"
    milli_sleep 10
done
calibrate_time_lvl2 1
print_time

echo "All performance tests completed successfully!"

# Clean exit for both sourced and executed contexts
return 2>/dev/null || exit 0
