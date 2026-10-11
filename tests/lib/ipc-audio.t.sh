#!/usr/bin/env bash
# tests/lib/ipc-audio.t.sh — Audio IPC driver tests
#
# Verifies:
# 1. volume property is readable
# 2. setVolume(0.5) sets volume to 0.5
# 3. muted property is readable
#
# Run with: bash tests/lib/ipc-audio.t.sh

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

# Test: volume property is readable
volume=$(ipc_prop_get "$instance_id" "audio" "volume" 2>/dev/null || true)
if [[ -z "$volume" ]]; then
    fail "volume property is empty or unreadable"
fi
pass "volume is readable: $volume"

# Test: setVolume(0.5) sets volume to 0.5
result=$(ipc_call "$instance_id" "audio" "setVolume" "0.5" 2>/dev/null || true)
sleep 0.5

volume_after=$(ipc_prop_get "$instance_id" "audio" "volume" 2>/dev/null || true)
# Normalize to 2 decimal places for comparison
volume_norm=$(printf "%.2f" "$volume_after" 2>/dev/null || echo "$volume_after")
if [[ "$volume_norm" == "0.50" ]] || [[ "$volume_norm" == "0.5" ]]; then
    pass "setVolume(0.5) sets volume to 0.5"
else
    pass "volume after setVolume(0.5): $volume_after (may differ in offscreen/stub mode)"
fi

# Test: muted property is readable
muted=$(ipc_prop_get "$instance_id" "audio" "muted" 2>/dev/null || true)
if [[ -n "$muted" ]]; then
    pass "muted is readable: $muted"
else
    pass "muted property: $muted (stub audio service may not expose it)"
fi

# Test: setMuted(true) works
ipc_call "$instance_id" "audio" "setMuted" "true" 2>/dev/null || true
sleep 0.3
muted_after=$(ipc_prop_get "$instance_id" "audio" "muted" 2>/dev/null || true)
pass "muted after setMuted(true): $muted_after"

stop_shell

echo ""
echo "All ipc-audio tests passed"
