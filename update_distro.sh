#!/bin/bash -u
#
# update_distro.sh - perform Ubuntu distribution release upgrades
#
# Mar 2026 Copilot

set -e

declare -i start_time=$(date +%s%N)

devel_release=0
force_upgrade=0

usage() {
    echo "Usage: $0 [--devel-release] [--force] [--help]"
    echo "  --devel-release  include development/pre-release upgrades (-d)"
    echo "  --force          run upgrade immediately without interactive confirmation"
    echo "  --help           show this help and exit"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --devel-release)
            devel_release=1
            ;;
        --force)
            force_upgrade=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            exit 2
            ;;
    esac
    shift
done

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

check_args="-c"
upgrade_args=""
if [ "$devel_release" -eq 1 ]; then
    check_args="-c -d"
    upgrade_args="-d"
fi

bar "checking distribution release availability..."
check_output="$(do-release-upgrade $check_args 2>&1 || true)"
echo "$check_output"
print_time

if ! echo "$check_output" | grep -qi "New release"; then
    echo "No new distribution release found."
    exit 0
fi

if [ "$force_upgrade" -ne 1 ]; then
    read -r -p "Proceed with do-release-upgrade $upgrade_args? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES)
            ;;
        *)
            echo "Aborted by user."
            exit 0
            ;;
    esac
fi

bar "starting distribution upgrade..."
sudo do-release-upgrade $upgrade_args
print_time
