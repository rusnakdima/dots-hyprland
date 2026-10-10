#!/usr/bin/env bash
# tests/lib/media-seek-command.t.sh — verify mediaNextCommand uses correct seek logic
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

# Read the keybinds.lua and find mediaNextCommand
KEYBINDS="$REPO_ROOT/dots/.config/hypr/hyprland/keybinds.lua"

# Extract the mediaNextCommand value
MEDIA_CMD=$(grep -A1 'local mediaNextCommand =' "$KEYBINDS" | tail -1)

# The old broken command computed: position = length (jumped to end)
# The fixed command uses: playerctl position 1%
if echo "$MEDIA_CMD" | grep -q 'position 1%'; then
  pass "mediaNextCommand uses playerctl position 1% (correct)"
else
  fail "mediaNextCommand does not use position 1%, got: $MEDIA_CMD"
fi

# Verify it does NOT have the broken length calculation:
# old: 100 * $(playerctl metadata mpris:length) / 1000000 / 100
# This computes: length / 1000000 (seconds) which jumps to end
if echo "$MEDIA_CMD" | grep -qE '100 \* \$\(playerctl metadata mpris:length\)'; then
  fail "mediaNextCommand still has broken '100 * length' calculation: $MEDIA_CMD"
else
  pass "mediaNextCommand does not have broken length calculation"
fi

# Verify it still has playerctl next as primary
if echo "$MEDIA_CMD" | grep -q 'playerctl next'; then
  pass "mediaNextCommand still calls playerctl next"
else
  fail "mediaNextCommand missing playerctl next"
fi

echo "All media-seek-command tests passed"
