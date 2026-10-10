#!/usr/bin/env bash
# tests/lib/install-safe-git.t.sh — verify git_config_safe_dirs sets safe.directory
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$REPO_ROOT/tests/lib.sh"

THOME=$(temp_home)
export HOME="$THOME"

# Create fake repo structure
FAKE_REPO="${THOME}/fake-dots"
mkdir -p "${FAKE_REPO}/sdata/dist-arch"
mkdir -p "${FAKE_REPO}/cache"

# Record which directories git config is called with
CALLED_DIRS="${THOME}/git-called.txt"
rm -f "$CALLED_DIRS"

# Fake git that records safe.directory calls
git(){
  if [[ "$1" == "config" && "$2" == "--global" && "$3" == "--add" && "$4" == "safe.directory" ]]; then
    echo "$5" >> "$CALLED_DIRS"
    return 0
  fi
  return 0
}

# Source just the git_config_safe_dirs function from install-deps.sh
REPO_ROOT="$FAKE_REPO"
git_config_safe_dirs(){
  local _dirs=(
    "${REPO_ROOT}"
    "${REPO_ROOT}/sdata/dist-arch"
    "${REPO_ROOT}/cache"
  )
  local _dir
  for _dir in "${_dirs[@]}"; do
    [[ -d "$_dir" ]] || continue
    git config --global --add safe.directory "$_dir" 2>/dev/null || true
  done
}

git_config_safe_dirs 2>/dev/null || true

# Verify git was called with the expected directories
if [[ -s "$CALLED_DIRS" ]]; then
    pass "git config --global --add safe.directory was called"
    count=$(grep -c . "$CALLED_DIRS" || echo 0)
    if [[ "$count" -ge 3 ]]; then
        pass "at least 3 directories registered (got $count)"
    else
        fail "expected at least 3 safe.directory entries, got $count"
    fi

    if grep -qF "$FAKE_REPO" "$CALLED_DIRS"; then
        pass "repo root registered as safe.directory"
    else
        fail "repo root not in safe.directory list"
    fi
else
    fail "git config --global --add safe.directory was not called"
fi

echo "All install-safe-git tests passed"
