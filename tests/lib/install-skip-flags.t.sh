#!/usr/bin/env bash
# tests/lib/install-skip-flags.t.sh — verify SKIP_ variables have defaults and don't cause unbound errors
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

# Source environment-variables.sh and verify all SKIP_ vars have defaults
source "$REPO_ROOT/sdata/lib/environment-variables.sh"

# Verify SKIP_ variables are set (not unbound)
for _var in SKIP_ALLGREETING SKIP_ALLDEPS SKIP_ALLSETUPS SKIP_ALLFILES MACHINE_PROFILE; do
  if [[ -z "${!_var}" ]]; then
    fail "$_var is empty after sourcing environment-variables.sh"
  else
    pass "$_var is set: ${!_var}"
  fi
done

# Verify defaults are "false"
for _var in SKIP_ALLGREETING SKIP_ALLDEPS SKIP_ALLSETUPS SKIP_ALLFILES; do
  if [[ "${!_var}" == "false" ]]; then
    pass "$_var defaults to false"
  else
    fail "$_var should default to false, got: ${!_var}"
  fi
done

# Verify SKIP_SYSUPDATE is handled with default in install-deps.sh
# (just verify the pattern is correct, actual test is the install running)
grep -q 'SKIP_SYSUPDATE:-false' "$REPO_ROOT/sdata/dist-arch/install-deps.sh" && pass "SKIP_SYSUPDATE uses \${SKIP_SYSUPDATE:-false} pattern" || fail "SKIP_SYSUPDATE not defaulted in install-deps.sh"

echo "All install-skip-flags tests passed"
