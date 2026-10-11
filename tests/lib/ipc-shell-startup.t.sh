#!/usr/bin/env bash
# tests/lib/ipc-shell-startup.t.sh — shell startup smoke test + IPC socket
#
# Verifies:
# 1. Shell starts without ERROR lines
# 2. IPC socket exists
# 3. At least one IPC target registers in `qs ipc show`
#
# Run with: bash tests/lib/ipc-shell-startup.t.sh

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

# Wait a moment for IPC to settle
sleep 1

# Capture startup output (already done in start_shell, but re-run to check errors)
output=$(env QT_QPA_PLATFORM=offscreen timeout 10 qs -c "$REPO_ROOT/dots/.config/quickshell/ii" 2>&1) || true

# Assert no ERROR: lines
if ! assert_no_errors "$output"; then
    fail "shell startup had ERROR lines: $(echo "$output" | grep 'ERROR:' | head -1)"
fi
pass "no ERROR: lines in startup output"

# Assert IPC socket exists
# The socket is at /run/user/<uid>/quickshell/by-id/<instance_id>/ipc.sock
socket_path=$(qs ipc -i "$instance_id" socket-path 2>/dev/null || true)
if [[ -z "$socket_path" ]]; then
    # Fallback: try to find it
    socket_path="/run/user/$(id -u)/quickshell/by-id/${instance_id}/ipc.sock"
fi

if [[ -e "$socket_path" ]]; then
    pass "IPC socket exists at $socket_path"
else
    # Try alternative path
    alt_path="/tmp/quickshell-${instance_id}/ipc.sock"
    if [[ -e "$alt_path" ]]; then
        pass "IPC socket exists at $alt_path"
    else
        fail "IPC socket not found at $socket_path or $alt_path"
    fi
fi

# Assert at least one IPC target registers
targets=$(qs ipc -i "$instance_id" show 2>/dev/null || true)
if [[ -z "$targets" ]]; then
    fail "qs ipc show returned empty output"
fi

target_count=$(echo "$targets" | grep -c "^[a-z]" || echo 0)
if [[ "$target_count" -gt 0 ]]; then
    pass "IPC targets registered: $target_count target(s)"
else
    fail "no IPC targets registered in 'qs ipc show'"
fi

stop_shell

echo ""
echo "All ipc-shell-startup tests passed"
