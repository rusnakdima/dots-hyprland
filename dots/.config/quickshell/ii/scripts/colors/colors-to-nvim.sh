#!/usr/bin/env bash
# Converts Material You colors.json → nvim.json
# Feeds dots-hyprland's lyne colorscheme palette.
# Run by quickshell whenever the theme changes.

COLORS_JSON="${HOME}/.local/state/quickshell/user/generated/colors.json"
NVIM_JSON="${HOME}/.local/state/quickshell/user/generated/nvim.json"

# Fallback: Tokyo Night (matches lyne fallback)
FALLBACK='{
  "palette": {
    "background": "#1a1b26", "surface0": "#24283b", "surface1": "#292e42",
    "surface2": "#414868", "surface3": "#565f89", "text": "#c0caf5",
    "subtext": "#a9b1d6", "accent": "#7aa2f7", "success": "#9ece6a",
    "warning": "#e0af68", "error": "#f7768e", "muted": "#545c7e",
    "greyBlue": "#283457", "blueDark": "#16161e"
  },
  "terminal": {
    "color0": "#15161e", "color1": "#f7768e", "color2": "#9ece6a",
    "color3": "#e0af68", "color4": "#7aa2f7", "color5": "#bb9af7",
    "color6": "#7dcfff", "color7": "#c0caf5", "color8": "#414868",
    "color9": "#f7768e", "color10": "#9ece6a", "color11": "#e0af68",
    "color12": "#7aa2f7", "color13": "#bb9af7", "color14": "#7dcfff",
    "color15": "#c0caf5", "color16": "#ff9e64"
  }
}'

if [[ ! -f "$COLORS_JSON" ]]; then
    echo "$FALLBACK" > "$NVIM_JSON"
    exit 0
fi

# Map Material You keys to nvim palette keys
# colors.json keys: background, primary, secondary, tertiary, surface,
#                   surface_variant, error, on_background, on_surface, etc.
python3 -c "
import json, sys

with open('$COLORS_JSON') as f:
    c = json.load(f)

def h(key):
    val = c.get(key, '#1a1b26')
    if isinstance(val, dict): val = val.get('hex', val.get('default', '#1a1b26'))
    if isinstance(val, dict): val = '#1a1b26'
    return val

bg    = h('background')
fg    = h('on_background')
surf0 = h('surface')
surf1 = h('surface_variant')
surf2 = h('outline_variant')
surf3 = h('outline')
acc   = h('primary')
err   = h('error')
warn  = h('tertiary')
succ  = h('secondary')   # approximate
mute  = h('surface_container_high')

# Terminal ANSI colors (use Material You palette sensibly)
color0  = h('surface_container_lowest')   # near-black
color1  = h('error')
color2  = succ
color3  = warn
color4  = acc
color5  = h('tertiary_container')
color6  = h('primary_container')
color7  = fg
color8  = surf2
color9  = h('on_error')
color10 = h('on_secondary')
color11 = h('on_tertiary')
color12 = h('on_primary')
color13 = h('on_tertiary_container')
color14 = h('on_primary_container')
color15 = h('on_surface')

out = {
    'palette': {
        'background': bg,
        'surface0': surf0, 'surface1': surf1, 'surface2': surf2, 'surface3': surf3,
        'text': fg, 'subtext': h('on_surface_variant'),
        'accent': acc, 'success': succ, 'warning': warn, 'error': err,
        'muted': mute, 'greyBlue': surf3, 'blueDark': surf0
    },
    'terminal': {
        'color0': color0, 'color1': color1, 'color2': color2, 'color3': color3,
        'color4': color4, 'color5': color5, 'color6': color6, 'color7': color7,
        'color8': color8, 'color9': color9, 'color10': color10, 'color11': color11,
        'color12': color12, 'color13': color13, 'color14': color14, 'color15': color15,
        'color16': h('primary_fixed')
    }
}

with open('$NVIM_JSON', 'w') as f:
    json.dump(out, f, indent=2)
"
