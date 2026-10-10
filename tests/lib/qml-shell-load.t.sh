#!/usr/bin/env bash
# tests/lib/qml-shell-load.t.sh - Quickshell ii config load regression test
#
# Verifies that the ii Quickshell config loads without "Failed to load
# configuration" errors. Run with: bash tests/run.sh --filter qml-shell-load

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"

# Check qs is available
if ! command -v qs &>/dev/null; then
    echo "qs not in PATH, skipping"
    exit 0
fi

# Capture startup output with a short timeout
# Use offscreen platform to avoid needing a display
output=$(env QT_QPA_PLATFORM=offscreen timeout 10 qs -c ii 2>&1) || true

# Assert no "Failed to load configuration" error
if echo "$output" | grep -q "Failed to load configuration"; then
    fail "shell failed to load: $(echo "$output" | grep "Failed to load" | head -1)"
else
    pass "shell loaded without 'Failed to load configuration' errors"
fi

# Assert no "Non-existent attached object" cascade
if echo "$output" | grep -q "Non-existent attached object"; then
    fail "shell has 'Non-existent attached object' errors: $(echo "$output" | grep "Non-existent attached object" | head -1)"
else
    pass "no 'Non-existent attached object' errors"
fi

# Assert no "Type unavailable" cascade (the Qt 6.12 metatype issue)
if echo "$output" | grep -q "Type unavailable"; then
    fail "shell has 'Type unavailable' errors (Qt metatype issue): $(echo "$output" | grep "Type unavailable" | head -1)"
else
    pass "no 'Type unavailable' metatype errors"
fi
