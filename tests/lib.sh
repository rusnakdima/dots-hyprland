# tests/lib.sh — shared test helpers
# This file is meant to be sourced by test scripts.

# Create a temporary home directory for tests that need a clean $HOME
temp_home() {
  mktemp -d "/tmp/dots-test-home-XXXXXX"
}

# Print a pass message
pass() {
  printf "%b\n" "\033[32m✓\033[0m $*"
}

# Print a fail message and exit
fail() {
  printf "%b\n" "\033[31m✗\033[0m $*"
  exit 1
}
