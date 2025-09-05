# Color definitions (with fallbacks if not set)
WHITE=${WHITE:-'\033[37m'}
YELLOW=${YELLOW:-'\033[33m'}
GRAY=${GRAY:-'\033[90m'}
RESET=${RESET:-'\033[0m'}

# Global calibration constants
readonly MS_CALIB_LVL1=343 # do_nothing() loop iterations
readonly MS_CALIB_LVL2=107       # millisecond delay calibration

NOTHING_DELAY=0

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

function milli_sleep_max() {
    # Sleep for specified milliseconds using CPU-based delay,
    # but exit early if elapsed time exceeds max_msecs.
    # Usage: milli_sleep_max <milliseconds> <max_msecs>
    local -i msecs=${1:-1}

    # Validate input
    if [[ ! "$msecs" =~ ^[0-9]+$ ]]; then
        echo "Error: milli_sleep_max requires positive integer" >&2
        return 1
    fi

    NOTHING_DELAY=${MS_CALIB_LVL2}
    local start_ns=$(date +%s%N)

    for ((i = 0; i <= msecs; i++)); do
        :
        local now_ns=$(date +%s%N)
        local elapsed_ms=$(((now_ns - start_ns) / 1000000))
        echo "i = ${i} ${elapsed_ms}/${msecs} ms"
        if ((elapsed_ms >= msecs)); then
            break
        fi
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
exit
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
    milli_sleep_max 10
done
calibrate_time_lvl2 1
print_time

echo "All performance tests completed successfully!"

# Clean exit for both sourced and executed contexts
return 2>/dev/null || exit 0
