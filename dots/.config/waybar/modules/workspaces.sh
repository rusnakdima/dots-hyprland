#!/bin/bash
# Waybar workspace module — reads hyprctl directly for workspace state.
# Output: one JSON object per line, waybar-compatible.
#
# State values:
#   "active"   — the currently focused workspace
#   "persistent" — a workspace that exists and has windows
#   "empty"    — a workspace that exists but is empty
#   "visible"  — a workspace visible on the current monitor (not in use here)
#
# Special workspaces are marked with name stripped of "special:" prefix.

set -euo pipefail

# Fetch all data in parallel
workspaces_json=$(hyprctl workspaces -j 2>/dev/null || echo '[]')
active_json=$(hyprctl activeworkspace -j 2>/dev/null || echo '{}')
monitors_json=$(hyprctl monitors -j 2>/dev/null || echo '[]')

# Extract active workspace id
active_id=$(printf '%s' "$active_json" | jq -r '.id // 0')

# Extract special workspace names per monitor
# monitors_json is an array: [{ "name": "eDP-1", "specialWorkspace": { "name": "special:foo" } }, ...]
special_names=$(printf '%s' "$monitors_json" | jq -r '
    [.[] | select(.specialWorkspace and .specialWorkspace.name != "") |
        { monitor: .name, name: .specialWorkspace.name }]
    | if length > 0 then . else [] end
')

# Build a lookup: for each workspace id, is it occupied?
# occupied_ids = workspaces that have windows (from hyprctl workspaces -j, the "windows" field)
# We'll parse the workspaces json to build a quick set of occupied ids
occupied_set=$(printf '%s' "$workspaces_json" | jq -r '[.[] | select(.windows > 0) | .id] | @sh')

# Iterate over workspaces 1-10 (the default shown count)
for i in $(seq 1 10); do
    # Check if this workspace id exists in the workspaces list
    ws_data=$(printf '%s' "$workspaces_json" | jq --argjson id "$i" '.[] | select(.id == $id) | { id: .id, name: .name, windows: .windows }' 2>/dev/null)

    if [ -z "$ws_data" ] || [ "$ws_data" = "null" ]; then
        # Workspace doesn't exist — skip it (don't render a button for non-existent ws)
        continue
    fi

    ws_id=$(printf '%s' "$ws_data" | jq -r '.id')
    ws_name=$(printf '%s' "$ws_data" | jq -r '.name // empty')
    ws_windows=$(printf '%s' "$ws_data" | jq -r '.windows // 0')

    # Determine state
    if [ "$ws_id" = "$active_id" ]; then
        state="active"
    elif [ "$ws_windows" -gt 0 ]; then
        state="persistent"
    else
        state="empty"
    fi

    # Determine CSS class
    css_class=""
    if [ "$state" = "active" ]; then
        css_class="active"
    elif [ "$state" = "persistent" ]; then
        css_class="persistent"
    fi

    # Special workspace: strip prefix
    display_name="$ws_name"
    if [ -n "$display_name" ] && [[ "$display_name" == special:* ]]; then
        display_name="${display_name#special:}"
        css_class="${css_class:+$css_class }special"
    fi

    # Emit JSON for this workspace (compact, one object per line)
    jq -nc \
        --argjson id "$ws_id" \
        --arg state "$state" \
        --arg name "$display_name" \
        --arg cls "$css_class" \
        '{ id: $id, state: $state, name: $name, class: $cls }'
done
