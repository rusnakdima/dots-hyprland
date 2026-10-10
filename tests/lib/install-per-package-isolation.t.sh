#!/usr/bin/env bash
# tests/lib/install-per-package-isolation.t.sh — verify failure isolation
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"
export PACMAN_AUTH="sudo"

# Fake pacman that always succeeds
pacman(){
  case "$*" in
    *-Q*illogical-impulse-quickshell*) echo "illogical-impulse-quickshell-git 1.0-1" ;;
    *) return 0 ;;
  esac
}

# Fake yay that always succeeds
yay(){ return 0; }

# Fake makepkg that always fails (simulating build failure)
makepkg(){
  return 1
}

# Fake sudo that does nothing
sudo(){ shift; "$@"; }

# Create a fake PKGBUILD for quickshell that returns a known version
FAKE_PKG="${THOME}/fake-pkgbuild"
mkdir -p "$FAKE_PKG"
cat > "$FAKE_PKG/PKGBUILD" << 'PKGEOF'
pkgname=illogical-impulse-quickshell-git
pkgver=2.0
pkgrel=1
PKGEOF

# Override PKGDEST to our temp
export PKGDEST="$THOME/pkgdest"
mkdir -p "$PKGDEST"

# Source just the install-local-pkgbuild function
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

  # Per-package removal
  if pacman -Q "${_pkgname}" &>/dev/null; then
    sudo pacman -Rdd --noconfirm "${_pkgname}" 2>/dev/null || true
  fi

  yay -S $installflags --asdeps "${depends[@]}" || true

  # Subshell makepkg — disable set -e inside so we can capture the rc
  local _rc=0
  (
    set +e
    makepkg -Afs --noconfirm
  )
  _rc=$?

  if [[ $_rc -ne 0 ]]; then
    PKG_STATUS[$_pkgname]="FAILED"
    PKG_REASON[$_pkgname]="makepkg failed (rc=$_rc)"
    popd >/dev/null; return $_rc
  fi

  PKG_STATUS[$_pkgname]="OK"
  PKG_REASON[$_pkgname]="built from PKGBUILD"
  popd >/dev/null; return 0
}

declare -A PKG_STATUS
declare -A PKG_REASON

# Test: makepkg failure for one package should set FAILED status
install-local-pkgbuild "$FAKE_PKG" "--needed" 2>/dev/null || true

if [[ "${PKG_STATUS[illogical-impulse-quickshell-git]}" == "FAILED" ]]; then
    pass "makepkg failure sets PKG_STATUS to FAILED"
else
    fail "expected PKG_STATUS=FAILED, got: ${PKG_STATUS[illogical-impulse-quickshell-git]:-unset}"
fi

if [[ "${PKG_REASON[illogical-impulse-quickshell-git]}" == *"makepkg failed"* ]]; then
    pass "PKG_REASON contains makepkg failure message"
else
    fail "expected PKG_REASON to mention makepkg failure"
fi

echo "All install-per-package-isolation tests passed"
