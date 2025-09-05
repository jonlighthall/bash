#!/bin/bash

# Progress Report Function
# This file contains a reusable progress reporting function that can be sourced
# by other scripts.

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
