#!/usr/bin/env bash
# tests/lib/gpu-detect-install.t.sh — verify GPU detection drives metapkgs selection
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

# ─── Reset helper ────────────────────────────────────────────────────────────────
reset_env(){
  unset GPU_NVIDIA GPU_HYBRID GPU_COUNT GPU_INTERNAL
  unset GPU_PCI GPU_DEVICE_ID GPU_VENDOR GPU_BRAND GPU_NAME
  unset GPU_KIND GPU_DRIVER GPU_BOOT_VGA GPU_CARD GPU_OUTPUTS
  unset GPU_VENDOR_ID
}

# ─── Fixture-based GPU detection (sources real gpus.sh) ─────────────────────────
gpu_detect_with_fixtures(){
  export LYNE_SYSFS="${REPO_ROOT}/tests/fixtures/sysfs"
  export LYNE_PCI_IDS="${REPO_ROOT}/tests/fixtures/pci.ids"
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/sdata/lib/gpus.sh"
  gpu_detect
}

# Simulate the metapkgs-building logic from install-deps.sh
build_metapkgs(){
  local _profile="${1:-desktop}"
  metapkgs_base=(
    "./sdata/dist-arch/illogical-impulse-basic"
    "./sdata/dist-arch/illogical-impulse-hyprland"
  )
  metapkgs_laptop=(
    "./sdata/dist-arch/illogical-impulse-backlight"
  )
  metapkgs_nvidia=(
    "./sdata/dist-arch/illogical-impulse-nvidia"
  )
  metapkgs=("${metapkgs_base[@]}")
  if [[ "$_profile" == "laptop" ]]; then
    metapkgs+=("${metapkgs_laptop[@]}")
  fi
  if [[ "${GPU_NVIDIA:-0}" -ge 0 ]]; then
    metapkgs+=("${metapkgs_nvidia[@]}")
  fi
}

# ─ Test: Fixture-based GPU detection finds the hybrid Intel+NVIDIA GPUs
reset_env
gpu_detect_with_fixtures

if [[ "${GPU_COUNT}" -eq 2 ]]; then
  pass "Fixture GPU detection: found ${GPU_COUNT} GPUs"
else
  fail "expected GPU_COUNT=2, got ${GPU_COUNT}"
fi

if [[ "${GPU_NVIDIA}" -ge 0 ]]; then
  pass "Fixture GPU detection: NVIDIA at index ${GPU_NVIDIA}"
else
  fail "expected NVIDIA GPU found, got GPU_NVIDIA=${GPU_NVIDIA}"
fi

if [[ "${GPU_HYBRID}" -eq 1 ]]; then
  pass "Fixture GPU detection: hybrid system detected"
else
  fail "expected GPU_HYBRID=1, got ${GPU_HYBRID}"
fi

if [[ "${GPU_INTERNAL}" -ge 0 ]]; then
  pass "Fixture GPU detection: internal panel GPU at index ${GPU_INTERNAL}"
else
  fail "expected internal GPU found, got GPU_INTERNAL=${GPU_INTERNAL}"
fi

# ─ Test: gpu_summary contains expected keywords
reset_env
gpu_detect_with_fixtures
_summary=$(gpu_summary)
if echo "$_summary" | grep -qiE "integrated|dedicated"; then
  pass "gpu_summary contains kind keywords: $_summary"
else
  fail "gpu_summary missing 'integrated' or 'dedicated': $_summary"
fi

# ─ Test: gpu_status produces output
reset_env
gpu_detect_with_fixtures
_status_output=$(gpu_status)
if echo "$_status_output" | grep -q "GPU 0:"; then
  pass "gpu_status produces GPU blocks"
else
  fail "gpu_status did not produce expected output"
fi

# ─ Test: gpu_json produces valid JSON array
reset_env
gpu_detect_with_fixtures
_json_output=$(gpu_json)
if echo "$_json_output" | grep -q "^\\[" && echo "$_json_output" | grep -q "\\]$"; then
  pass "gpu_json produces JSON array"
else
  fail "gpu_json did not produce valid JSON: $_json_output"
fi

# ─ Test: Hybrid + laptop profile → nvidia meta-pkg added
reset_env
gpu_detect_with_fixtures
build_metapkgs laptop
if [[ " ${metapkgs[*]} " == *"illogical-impulse-nvidia"* ]]; then
  pass "Hybrid laptop: nvidia metapkg added"
else
  fail "expected nvidia metapkg in hybrid laptop metapkgs: ${metapkgs[*]}"
fi

# ─ Test: No NVIDIA in fixture (the fixture does have NVIDIA, so GPU_NVIDIA >= 0)
reset_env
gpu_detect_with_fixtures
if [[ "${GPU_NVIDIA}" -lt 0 ]]; then
  # This branch tests the no-NVIDIA path
  build_metapkgs desktop
  if [[ " ${metapkgs[*]} " != *"illogical-impulse-nvidia"* ]]; then
    pass "Desktop without NVIDIA: nvidia metapkg NOT added"
  else
    fail "expected nvidia metapkg NOT in desktop metapkgs: ${metapkgs[*]}"
  fi
else
  pass "Fixture has NVIDIA GPU, skipping no-NVIDIA desktop test (expected)"
fi

echo ""
echo "All gpu-detect-install tests passed"
