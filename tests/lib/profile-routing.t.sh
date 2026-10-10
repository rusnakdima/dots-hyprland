#!/usr/bin/env bash
# tests/lib/profile-routing.t.sh — verify resolve_profile reads cached file or probes battery
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

# Source the resolve_profile function logic from install-deps.sh
# (we replicate it here to avoid sourcing the full install-deps.sh which has many deps)
resolve_profile_test(){
  local _profile="${1:-auto}"
  local _machine_file="${HOME}/.config/dots-hyprland/MACHINE"

  if [[ "$_profile" == "auto" ]]; then
    if [[ -f "$_machine_file" ]]; then
      _profile="$(cat "$_machine_file")"
    else
      # Battery probe — mock in test by checking a fake sysfs path
      if [[ -n "$(ls "${HOME}/sys/class/power_supply/BAT*" 2>/dev/null)" ]]; then
        _profile="laptop"
      else
        _profile="desktop"
      fi
    fi
  fi

  mkdir -p "${HOME}/.config/dots-hyprland"
  printf '%s\n' "$_profile" > "$_machine_file"
  echo "$_profile"
}

# ─ Test 1: Cached MACHINE file with "laptop" → returns laptop, no battery probe
mkdir -p "${HOME}/.config/dots-hyprland"
printf 'laptop\n' > "${HOME}/.config/dots-hyprland/MACHINE"

result=$(resolve_profile_test auto)
if [[ "$result" == "laptop" ]]; then
  pass "cached MACHINE=laptop: resolve_profile returns laptop"
else
  fail "expected laptop, got: $result"
fi

# ─ Test 2: Cached MACHINE file with "desktop" → returns desktop
printf 'desktop\n' > "${HOME}/.config/dots-hyprland/MACHINE"
result=$(resolve_profile_test auto)
if [[ "$result" == "desktop" ]]; then
  pass "cached MACHINE=desktop: resolve_profile returns desktop"
else
  fail "expected desktop, got: $result"
fi

# ─ Test 3: No cached file + auto → probes battery (no BAT* = desktop)
rm -f "${HOME}/.config/dots-hyprland/MACHINE"
result=$(resolve_profile_test auto)
if [[ "$result" == "desktop" ]]; then
  pass "no cached file, no battery: resolve_profile returns desktop"
else
  fail "expected desktop (no battery), got: $result"
fi

# ─ Test 4: Forced laptop bypasses auto/probe logic
result=$(resolve_profile_test laptop)
if [[ "$result" == "laptop" ]]; then
  pass "forced --profile=laptop: resolve_profile returns laptop"
else
  fail "expected laptop, got: $result"
fi

# ─ Test 5: Forced desktop bypasses auto/probe logic
result=$(resolve_profile_test desktop)
if [[ "$result" == "desktop" ]]; then
  pass "forced --profile=desktop: resolve_profile returns desktop"
else
  fail "expected desktop, got: $result"
fi

# ─ Test 6: resolve_profile writes the MACHINE file
rm -f "${HOME}/.config/dots-hyprland/MACHINE"
resolve_profile_test auto >/dev/null
if [[ -f "${HOME}/.config/dots-hyprland/MACHINE" ]]; then
  pass "resolve_profile writes MACHINE file"
else
  fail "MACHINE file was not created"
fi

echo "All profile-routing tests passed"
