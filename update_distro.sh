#!/bin/bash -u
#
# update_distro.sh - perform Ubuntu distribution release upgrades
#
# Mar 2026 Copilot

set -e

declare -i start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
fi

# print source name at start
print_source

if ! command -v do-release-upgrade >/dev/null 2>&1; then
    echo "do-release-upgrade is not available. Install with: sudo apt-get install ubuntu-release-upgrader-core"
    exit 1
fi

bar "checking distribution release availability..."
check_output="$(do-release-upgrade -c 2>&1 || true)"
echo "$check_output"
print_time

if ! echo "$check_output" | grep -qi "New release"; then
    echo "No new distribution release found."
    exit 0
fi

read -r -p "Proceed with distribution upgrade now? [y/N] " answer
case "$answer" in
    y|Y|yes|YES)
        ;;
    *)
        echo "Aborted by user."
        exit 0
        ;;
esac

bar "starting distribution upgrade..."
sudo do-release-upgrade
print_time
