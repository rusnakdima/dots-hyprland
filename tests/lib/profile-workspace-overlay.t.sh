#!/usr/bin/env bash
# tests/lib/profile-workspace-overlay.t.sh — verify profile workspace overlay loading
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

# Create profile workspace files
PROFILES_DIR="${THOME}/.config/hypr/profiles"
mkdir -p "$PROFILES_DIR/laptop" "$PROFILES_DIR/desktop"

# Laptop profile: creates LAPTOP_LOADED marker
cat > "$PROFILES_DIR/laptop/workspaces.lua" << 'LUA'
LAPTOP_LOADED=1
-- laptop profile: single screen
LUA

# Desktop profile: creates DESKTOP_LOADED marker
cat > "$PROFILES_DIR/desktop/workspaces.lua" << 'LUA'
DESKTOP_LOADED=1
-- desktop profile: multi-monitor
LUA

# Mock os.getenv that returns the profile name
os.getenv(){
  case "$1" in
    MACHINE_PROFILE) echo "$MACHINE_PROFILE_VALUE" ;;
    HOME) echo "$HOME" ;;
    XDG_CONFIG_HOME) echo "${HOME}/.config" ;;
    *) echo "" ;;
  esac
}

# Mock is_file_exists
is_file_exists(){
  [[ -f "$1" ]]
}

# Mock require that simulates Lua's loadfile behavior
LOADED_PROFILE=""
require(){
  local _path="$1"
  if [[ "$_path" == "hypr.profiles."*"/workspaces.lua" ]]; then
    LOADED_PROFILE="${_path##hypr.profiles.}"
    LOADED_PROFILE="${LOADED_PROFILE%/workspaces.lua}"
    if [[ "$LOADED_PROFILE" == "laptop" ]]; then
      eval "$(cat "$PROFILES_DIR/laptop/workspaces.lua")"
    elif [[ "$LOADED_PROFILE" == "desktop" ]]; then
      eval "$(cat "$PROFILES_DIR/desktop/workspaces.lua")"
    fi
  fi
}

# Simulate the profile overlay loading logic from hyprland.lua
load_profile_workspace(){
  local _profile
  _profile=$(os.getenv MACHINE_PROFILE) || _profile="desktop"
  local _overlay_path="${HOME}/.config/hypr/profiles/${_profile}/workspaces.lua"
  if is_file_exists "$_overlay_path"; then
    require "hypr.profiles.${_profile}.workspaces"
  fi
}

# ─ Test 1: MACHINE_PROFILE=laptop → laptop overlay loads
MACHINE_PROFILE_VALUE="laptop"
unset LAPTOP_LOADED DESKTOP_LOADED
LOADED_PROFILE=""
load_profile_workspace
if [[ "$LOADED_PROFILE" == "laptop" ]] && [[ "$LAPTOP_LOADED" == "1" ]]; then
  pass "MACHINE_PROFILE=laptop: laptop workspaces.lua loaded"
else
  fail "expected laptop workspace overlay, loaded=$LOADED_PROFILE, LAPTOP=$LAPTOP_LOADED"
fi

# ─ Test 2: MACHINE_PROFILE=desktop → desktop overlay loads
MACHINE_PROFILE_VALUE="desktop"
unset LAPTOP_LOADED DESKTOP_LOADED
LOADED_PROFILE=""
load_profile_workspace
if [[ "$LOADED_PROFILE" == "desktop" ]] && [[ "$DESKTOP_LOADED" == "1" ]]; then
  pass "MACHINE_PROFILE=desktop: desktop workspaces.lua loaded"
else
  fail "expected desktop workspace overlay, loaded=$LOADED_PROFILE, DESKTOP=$DESKTOP_LOADED"
fi

# ─ Test 3: MACHINE_PROFILE unset → defaults to desktop
MACHINE_PROFILE_VALUE=""
unset LAPTOP_LOADED DESKTOP_LOADED
LOADED_PROFILE=""
load_profile_workspace
if [[ "$LOADED_PROFILE" == "desktop" ]]; then
  pass "MACHINE_PROFILE unset: defaults to desktop overlay"
else
  fail "expected desktop default, got: $LOADED_PROFILE"
fi

echo "All profile-workspace-overlay tests passed"
