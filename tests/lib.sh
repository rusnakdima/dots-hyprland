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

# --- Shell lifecycle ---
# Global: SHELL_PID (set by start_shell)

start_shell() {
  # Set REPO_ROOT if not already set
  if [[ -z "${REPO_ROOT:-}" ]]; then
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  fi

  local cfg_path="$REPO_ROOT/dots/.config/quickshell/ii"
  local output_file
  output_file=$(mktemp /tmp/qs-startup-XXXXXX.log)

  # Launch shell in background, capturing stdout
  env QT_QPA_PLATFORM=offscreen qs -c "$cfg_path" > "$output_file" 2>&1 &
  SHELL_PID=$!

  # Wait up to 10s for shell to start and emit "Shell ID:"
  local instance_id=""
  local count=0
  while [[ $count -lt 50 ]]; do
    if grep -q "Shell ID:" "$output_file" 2>/dev/null; then
      instance_id=$(grep "Shell ID:" "$output_file" | tail -1 | sed -n 's/.*Shell ID:[ ]*"\([^"]*\)".*/\1/p')
      if [[ -n "$instance_id" ]]; then
        break
      fi
    fi
    # Check if process died
    if ! kill -0 "$SHELL_PID" 2>/dev/null; then
      break
    fi
    sleep 0.2
    count=$((count + 1))
  done

  if [[ -z "$instance_id" ]]; then
    # Shell failed to start or ID not found
    cat "$output_file" >&2
    stop_shell
    rm -f "$output_file"
    return 1
  fi

  echo "$instance_id"
  rm -f "$output_file"
  return 0
}

stop_shell() {
  if [[ -n "${SHELL_PID:-}" ]] && kill -0 "$SHELL_PID" 2>/dev/null; then
    kill "$SHELL_PID" 2>/dev/null
    # Wait up to 5s for it to exit
    local count=0
    while kill -0 "$SHELL_PID" 2>/dev/null && [[ $count -lt 50 ]]; do
      sleep 0.1
      count=$((count + 1))
    done
    # Force kill if still alive
    if kill -0 "$SHELL_PID" 2>/dev/null; then
      kill -9 "$SHELL_PID" 2>/dev/null
    fi
  fi
  SHELL_PID=""
}

# --- IPC primitives ---

# Call an IPC function on a target
# Usage: ipc_call <instance_id> <target> <function>
ipc_call() {
  local instance_id="$1"
  local target="$2"
  local func="$3"
  qs ipc -i "$instance_id" call "$target" "$func" 2>/dev/null
}

# Get an IPC property value
# Usage: ipc_prop_get <instance_id> <target> <property>
# Returns the property value on stdout
ipc_prop_get() {
  local instance_id="$1"
  local target="$2"
  local prop="$3"
  qs ipc -i "$instance_id" prop get "$target" "$prop" 2>/dev/null | sed -n 's/.*=[ ]*\(.*\)/\1/p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Wait for an IPC signal
# Usage: wait_for_signal <instance_id> <target> <signal> <timeout_seconds>
# Returns 0 if signal fired, 1 if timeout
wait_for_signal() {
  local instance_id="$1"
  local target="$2"
  local signal="$3"
  local timeout_sec="$4"

  # Run qs ipc wait in background, kill it after timeout
  qs ipc -i "$instance_id" wait "$target" "$signal" &
  local wait_pid=$!

  # Wait for the process with timeout
  local count=0
  local interval=1
  local max_wait=$((timeout_sec * 10))

  while kill -0 "$wait_pid" 2>/dev/null && [[ $count -lt $max_wait ]]; do
    sleep 0.1
    count=$((count + 1))
  done

  if kill -0 "$wait_pid" 2>/dev/null; then
    kill "$wait_pid" 2>/dev/null
    wait "$wait_pid" 2>/dev/null
    return 1
  fi

  wait "$wait_pid" 2>/dev/null
  return 0
}

# Assert that the shell startup log contains a pattern
# Usage: assert_log_contains <instance_id> <pattern>
# Returns 0 if found, 1 if not
assert_log_contains() {
  local instance_id="$1"
  local pattern="$2"
  local log_output
  log_output=$(qs ipc -i "$instance_id" log 2>/dev/null)
  if echo "$log_output" | grep -q "$pattern"; then
    return 0
  fi
  return 1
}

# Assert no ERROR: lines in startup output
# Usage: assert_no_errors <startup_output>
# Returns 0 if no errors, 1 if errors found
assert_no_errors() {
  local output="$1"
  if echo "$output" | grep -q "ERROR:"; then
    return 1
  fi
  return 0
}
