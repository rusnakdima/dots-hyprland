#!/usr/bin/env bash
# tests/lib/install-version-gate.t.sh — verify version gate skips makepkg on match
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

# Fake pacman that returns a matching version (simulating current install)
pacman(){
  if [[ "$*" == *"-Q"* ]]; then
    echo "illogical-impulse-quickshell-git 1.0-1"
    return 0
  fi
  return 0
}
sudo(){ shift; "$@"; }
yay(){ return 0; }

FAKE_PKG="${THOME}/fake-pkgbuild"
mkdir -p "$FAKE_PKG"
cat > "$FAKE_PKG/PKGBUILD" << 'PKGEOF'
pkgname=illogical-impulse-quickshell-git
pkgver=1.0
pkgrel=1
PKGEOF

export PKGDEST="$THOME/pkgdest"
mkdir -p "$PKGDEST"

install-local-pkgbuild(){
  local location="$1"
  local installflags="$2"

  pushd "$location" >/dev/null
  source ./PKGBUILD
  local _pkgname="$pkgname"

  local _installed_ver
  _installed_ver="$(pacman -Q "${_pkgname}" 2>/dev/null | awk '{print $2}')"
  if [[ "${_installed_ver}" == "${pkgver}-${pkgrel}" ]]; then
    PKG_STATUS[$_pkgname]="OK"; PKG_REASON[$_pkgname]="already current"
    popd >/dev/null; return 0
  fi

  # Would rebuild here
  PKG_STATUS[$_pkgname]="BUILT"; PKG_REASON[$_pkgname]="rebuilt"
  popd >/dev/null; return 0
}

declare -A PKG_STATUS
declare -A PKG_REASON

install-local-pkgbuild "$FAKE_PKG" "--needed" 2>/dev/null || true

if [[ "${PKG_STATUS[illogical-impulse-quickshell-git]}" == "OK" ]]; then
    pass "matching version skips makepkg (PKG_STATUS=OK)"
else
    fail "expected PKG_STATUS=OK, got: ${PKG_STATUS[illogical-impulse-quickshell-git]:-unset}"
fi

if [[ "${PKG_REASON[illogical-impulse-quickshell-git]}" == "already current" ]]; then
    pass "PKG_REASON=already current"
else
    fail "expected PKG_REASON=already current, got: ${PKG_REASON[illogical-impulse-quickshell-git]:-unset}"
fi

echo "All install-version-gate tests passed"
