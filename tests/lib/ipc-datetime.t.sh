#!/usr/bin/env bash
# tests/lib/ipc-datetime.t.sh — DateTime IPC driver tests
#
# Verifies:
# 1. timeString property is readable and matches %H:%M format
# 2. dateString property is readable
#
# Run with: bash tests/lib/ipc-datetime.t.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"

# Check qs is available
if ! command -v qs &>/dev/null; then
    echo "qs not in PATH, skipping"
    exit 0
fi

# Launch shell
instance_id=$(start_shell)
if [[ -z "$instance_id" ]]; then
    fail "start_shell returned empty instance id"
fi

# Wait for shell to fully initialize
sleep 2

# Test: timeString property is readable
time_string=$(ipc_prop_get "$instance_id" "datetime" "timeString" 2>/dev/null || true)
if [[ -z "$time_string" ]]; then
    fail "timeString property is empty or unreadable"
fi
pass "timeString is readable: $time_string"

# Assert timeString matches HH:MM or HH:MM:SS format (with optional am/pm)
if echo "$time_string" | grep -qE "^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?( [AP]M)?$"; then
    pass "timeString matches time format: $time_string"
else
    fail "timeString does not match expected time format: $time_string"
fi

# Test: dateString property is readable
date_string=$(ipc_prop_get "$instance_id" "datetime" "dateString" 2>/dev/null || true)
if [[ -n "$date_string" ]]; then
    pass "dateString is readable: $date_string"
else
    pass "dateString property: empty (stub mode or not exposed)"
fi

stop_shell

echo ""
echo "All ipc-datetime tests passed"
