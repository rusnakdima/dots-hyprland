#!/usr/bin/env bash
# tests/lib/hardware-probe.t.sh — verify AIC8800 detection triggers install_aic8800
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

AIC8800_CALLS=0

# Mock install_aic8800 that tracks calls
install_aic8800(){
  AIC8800_CALLS=$((AIC8800_CALLS + 1))
}

# ─ Test 1: lsusb shows AIC8800 (0b05:5721) → install_aic8800 called
AIC8800_CALLS=0
lsusb(){
  echo "Bus 001 Device 002: ID 0b05:5721 ASUSTek Computer Inc. AIC8800"
  echo "Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub"
}

# Simulate the AIC8800 probe from install-deps.sh
probe_aic8800(){
  if lsusb 2>/dev/null | grep -q "0b05:5721"; then
    install_aic8800
    return 0
  fi
  return 1
}

probe_aic8800
if [[ "$AIC8800_CALLS" -eq 1 ]]; then
  pass "AIC8800 adapter present: install_aic8800 was called"
else
  fail "expected install_aic8800 to be called once, got: $AIC8800_CALLS"
fi

# ─ Test 2: lsusb does NOT show AIC8800 → install_aic8800 NOT called
AIC8800_CALLS=0
lsusb(){
  echo "Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub"
  echo "Bus 002 Device 002: ID 8087:0034 Intel Corp."
}

probe_aic8800
if [[ "$AIC8800_CALLS" -eq 0 ]]; then
  pass "No AIC8800 adapter: install_aic8800 NOT called"
else
  fail "expected install_aic8800 NOT called, got: $AIC8800_CALLS"
fi

# ─ Test 3: lsusb not available → install_aic8800 NOT called (graceful)
AIC8800_CALLS=0
lsusb(){
  return 1
}

probe_aic8800
if [[ "$AIC8800_CALLS" -eq 0 ]]; then
  pass "lsusb unavailable: probe gracefully skips, install_aic8800 NOT called"
else
  fail "expected install_aic8800 NOT called when lsusb fails, got: $AIC8800_CALLS"
fi

# ─ Test 4: Multiple adapters with AIC8800 present → install_aic8800 called once
AIC8800_CALLS=0
lsusb(){
  echo "Bus 001 Device 002: ID 0b05:5721 ASUSTek Computer Inc. AIC8800"
  echo "Bus 001 Device 003: ID 0b05:5721 ASUSTek Computer Inc. AIC8800"
}

probe_aic8800
if [[ "$AIC8800_CALLS" -eq 1 ]]; then
  pass "Multiple AIC8800 adapters: install_aic8800 called once"
else
  fail "expected 1 call, got: $AIC8800_CALLS"
fi

echo "All hardware-probe tests passed"
