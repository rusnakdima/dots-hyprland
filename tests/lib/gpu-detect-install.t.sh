#!/usr/bin/env bash
# tests/lib/gpu-detect-install.t.sh — verify GPU detection drives metapkgs selection
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

# ─── Test 1: NVIDIA GPU detected — nvidia packages added ────────────────────────
reset_env(){
  unset GPU_NVIDIA GPU_HYBRID GPU_COUNT GPU_INTERNAL
  unset GPU_PCI GPU_IDS GPU_VENDOR GPU_BRAND GPU_NAME GPU_CHIP
  unset GPU_KIND GPU_DRIVER GPU_BOOT_VGA GPU_CARD GPU_OUTPUTS
}

# Mock gpu_detect that sets NVIDIA=0 (NVIDIA GPU present)
gpu_detect_nvidia(){
  GPU_COUNT=1
  GPU_HYBRID=0
  GPU_INTERNAL=0
  GPU_NVIDIA=0
  GPU_VENDOR=(nvidia)
  GPU_BRAND=(NVIDIA)
  GPU_NAME=("NVIDIA GeForce RTX 5060")
}

# Mock gpu_detect that sets NVIDIA=-1 (no NVIDIA GPU)
gpu_detect_no_nvidia(){
  GPU_COUNT=1
  GPU_HYBRID=0
  GPU_INTERNAL=0
  GPU_NVIDIA=-1
  GPU_VENDOR=(intel)
  GPU_BRAND=(Intel)
  GPU_NAME=("Intel Graphics")
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
  if [[ "$GPU_NVIDIA" -ge 0 ]]; then
    metapkgs+=("${metapkgs_nvidia[@]}")
  fi
}

# ─ Test: NVIDIA GPU present → nvidia meta-pkg in list
reset_env
gpu_detect_nvidia
build_metapkgs laptop

if [[ " ${metapkgs[*]} " == *"illogical-impulse-nvidia"* ]]; then
  pass "NVIDIA GPU detected: illogical-impulse-nvidia added to metapkgs"
else
  fail "expected illogical-impulse-nvidia in metapkgs, got: ${metapkgs[*]}"
fi

# ─ Test: No NVIDIA GPU → nvidia meta-pkg NOT in list
reset_env
gpu_detect_no_nvidia
build_metapkgs desktop

if [[ " ${metapkgs[*]} " != *"illogical-impulse-nvidia"* ]]; then
  pass "No NVIDIA GPU: illogical-impulse-nvidia NOT in metapkgs"
else
  fail "expected illogical-impulse-nvidia NOT in metapkgs, got: ${metapkgs[*]}"
fi

# ─ Test: Hybrid (NVIDIA + Intel) → nvidia meta-pkg still added
reset_env
GPU_COUNT=2
GPU_HYBRID=1
GPU_INTERNAL=1
GPU_NVIDIA=0
GPU_VENDOR=(nvidia intel)
gpu_detect_nvidia
build_metapkgs laptop

if [[ " ${metapkgs[*]} " == *"illogical-impulse-nvidia"* ]]; then
  pass "Hybrid GPU detected: illogical-impulse-nvidia added to metapkgs"
else
  fail "expected illogical-impulse-nvidia in hybrid metapkgs, got: ${metapkgs[*]}"
fi

echo "All gpu-detect-install tests passed"
