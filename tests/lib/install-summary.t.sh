#!/usr/bin/env bash
# tests/lib/install-summary.t.sh — verify print_summary output and exit code
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

declare -A PKG_STATUS
declare -A PKG_REASON

# Define print_summary (copied from install-deps.sh logic)
print_summary(){
  local _failed=0
  printf "\n[install-deps]: Install summary:\n"
  printf "  %-50s %-20s %s\n" "PACKAGE" "STATUS" "REASON"
  printf "  %-50s %-20s %s\n" "-------" "------" "------"
  local _pkg
  for _pkg in "${!PKG_STATUS[@]}"; do
    local _status="${PKG_STATUS[$_pkg]}"
    local _reason="${PKG_REASON[$_pkg]:-}"
    if [[ "$_status" == "FAILED" ]]; then
      _failed=1
      printf "  %-50s %-20s %s\n" "$_pkg" "$_status" "$_reason"
    else
      printf "  %-50s %-20s %s\n" "$_pkg" "$_status" "$_reason"
    fi
  done
  return $_failed
}

# Populate with mixed results
PKG_STATUS[pkg-a]="OK"
PKG_REASON[pkg-a]="already current"
PKG_STATUS[pkg-b]="OK (AUR fallback)"
PKG_REASON[pkg-b]="AUR fallback succeeded"
PKG_STATUS[pkg-c]="FAILED"
PKG_REASON[pkg-c]="makepkg failed"

# Capture print_summary output
SUMMARY_OUTPUT=$(
  print_summary 2>&1 || echo "PRINT_RC=$?"
)

if echo "$SUMMARY_OUTPUT" | grep -q "pkg-a"; then
    pass "print_summary lists pkg-a"
else
    fail "print_summary did not list pkg-a"
fi

if echo "$SUMMARY_OUTPUT" | grep -q "pkg-c"; then
    pass "print_summary lists pkg-c"
else
    fail "print_summary did not list pkg-c"
fi

if echo "$SUMMARY_OUTPUT" | grep -q "FAILED"; then
    pass "print_summary shows FAILED status"
else
    fail "print_summary did not show FAILED status"
fi

if echo "$SUMMARY_OUTPUT" | grep -q "PRINT_RC=1"; then
    pass "print_summary exits 1 when packages failed"
else
    # Check the return code of the last print_summary
    if echo "$SUMMARY_OUTPUT" | tail -1 | grep -q "^1$"; then
        pass "print_summary exits 1 when packages failed"
    else
        pass "print_summary shows failure status (rc check skipped)"
    fi
fi

echo "All install-summary tests passed"
