# This script is meant to be sourced. Do not execute directly.

# ─── Environment ────────────────────────────────────────────────────────────────

#: LYNE_SYSFS  — sysfs root (default: /sys)
#: LYNE_PCI_IDS — pci.ids path (default: resolved below)
#: REPO_ROOT    — repo root, used to find bundled pci.ids

# Prevent double-sourcing
if [[ -n "${_LYNE_GPUS_SH_SOURCED:-}" ]]; then return; fi
declare -gr _LYNE_GPUS_SH_SOURCED=1

# ─── Defaults ──────────────────────────────────────────────────────────────────

declare -g LYNE_SYSFS="${LYNE_SYSFS:-/sys}"

# Resolve pci.ids path
_pci_ids_resolve() {
  if [[ -n "${LYNE_PCI_IDS:-}" ]] && [[ -f "${LYNE_PCI_IDS}" ]]; then
    echo "$LYNE_PCI_IDS"
    return
  fi
  local repo_root="${REPO_ROOT:-}"
  if [[ -z "$repo_root" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  fi
  if [[ -n "$repo_root" ]] && [[ -f "${repo_root}/src/data/pci.ids" ]]; then
    echo "${repo_root}/src/data/pci.ids"
    return
  fi
  if [[ -f /usr/share/hwdata/pci.ids ]]; then
    echo /usr/share/hwdata/pci.ids
    return
  fi
  if [[ -f /usr/share/pci.ids ]]; then
    echo /usr/share/pci.ids
    return
  fi
  # Not found — caller must handle gracefully
  echo ""
}

declare -g LYNE_PCI_IDS="$(_pci_ids_resolve)"

# ─── GPU Data Arrays ───────────────────────────────────────────────────────────

declare -ga GPU_PCI=()       # PCI address (e.g. 0000:00:02.0)
declare -ga GPU_VENDOR_ID=() # hex vendor ID (e.g. 0x8086)
declare -ga GPU_DEVICE_ID=()  # hex device ID (e.g. 0x9a49)
declare -ga GPU_VENDOR=()     # nvidia|intel|amd|virtual|other
declare -ga GPU_BRAND=()     # brand name from pci.ids (e.g. "NVIDIA Corporation")
declare -ga GPU_NAME=()      # device name from pci.ids (e.g. "UHD Graphics 617")
declare -ga GPU_KIND=()       # integrated|dedicated|virtual
declare -ga GPU_DRIVER=()     # kernel driver name
declare -ga GPU_BOOT_VGA=()  # 1 if boot VGA, 0 otherwise, empty if unavailable
declare -ga GPU_CARD=()      # cardN identifier (e.g. card0)
declare -ga GPU_OUTPUTS=()    # space-separated "name:status" pairs

# Scalars
declare -gi GPU_COUNT=-1     # number of GPUs detected
declare -gi GPU_NVIDIA=-1    # index of first NVIDIA GPU, -1 if none
declare -gi GPU_HYBRID=0     # 1 if both integrated and dedicated present
declare -gi GPU_INTERNAL=-1   # index of GPU with internal panel, -1 if none

# ─── pci.ids Lookup ─────────────────────────────────────────────────────────────

#: _pci_ids_lookup <vendor_id_hex> <device_id_hex>
#: Prints "brand|device_name" or empty if not found.
_pci_ids_lookup() {
  local vendor="$1"; local device="$2"
  [[ -z "$vendor" || -z "$LYNE_PCI_IDS" || ! -f "$LYNE_PCI_IDS" ]] && echo "" && return

  # Normalize to lowercase for lookup, strip 0x prefix
  local vendor_lc="${vendor#0x}"
  vendor_lc="${vendor_lc,,}"
  local device_lc="${device#0x}"
  device_lc="${device_lc,,}"

  local brand
  brand=$(grep -i "^${vendor_lc}  " "$LYNE_PCI_IDS" 2>/dev/null | sed 's/^[0-9a-f]\+  //' | xargs)
  [[ -z "$brand" ]] && echo "|" && return

  local devname
  devname=$(grep -i "^${vendor_lc}  " "$LYNE_PCI_IDS" 2>/dev/null | \
    awk -v dev="$device_lc" 'found && /^  / {gsub(/^  /,""); gsub(/  .*/,""); if ($0 ~ "^" dev "$") {found=0; print; exit}} /^[0-9a-f]+  / {gsub(/^  /,""); gsub(/  .*/,""); if ($0 == dev) {found=1}}' 2>/dev/null)

  if [[ -z "$devname" ]]; then
    # Try alternate device lookup
    devname=$(grep -i "^${vendor_lc}  " "$LYNE_PCI_IDS" 2>/dev/null | \
      awk -v dev="$device_lc" '
        /^[0-9a-f]+  [^ ]/ { vendor_line=$0 }
        /^  [0-9a-f]+  / {
          gsub(/^  /,""); gsub(/  .*/,"")
          if ($0 == dev) {
            gsub(/^  /,""); sub(/  .*/,"")
            print
            exit
          }
        }
      ' 2>/dev/null)
  fi

  echo "${brand}|${devname:-}"
}

# ─── Vendor Classification ─────────────────────────────────────────────────────

_gpu_classify_by_vendor() {
  local vendor="$1"
  case "${vendor,,}" in
    0x10de|10de) echo "nvidia" ;;
    0x8086|8086) echo "intel" ;;
    0x1002|1002) echo "amd" ;;
    0x1234|1234) echo "virtual" ;;
    *) echo "other" ;;
  esac
}

# ─── Driver Classification ──────────────────────────────────────────────────────

_gpu_classify_by_driver() {
  local driver="$1"
  case "$driver" in
    virtio-gpu|vmwgfx) echo "virtual" ;;
    *) echo "other" ;;
  esac
}

# ─── GPU Kind ──────────────────────────────────────────────────────────────────

_gpu_kind() {
  local idx="$1"
  local vendor="${GPU_VENDOR[$idx]:-}"
  local outputs="${GPU_OUTPUTS[$idx]:-}"
  local boot_vga="${GPU_BOOT_VGA[$idx]:-}"

  if [[ "$vendor" == "virtual" ]]; then
    echo "virtual"
    return
  fi

  # Check for internal connectors
  if [[ "$outputs" =~ eDP-1|LVDS-1|DSI-1 ]]; then
    echo "integrated"
    return
  fi

  # If this GPU is the boot VGA and it's intel/amd, it's likely integrated
  if [[ "$boot_vga" == "1" ]] && [[ "$vendor" == @(intel|amd) ]]; then
    echo "integrated"
    return
  fi

  # Otherwise dedicated
  echo "dedicated"
}

# ─── gpu_detect ────────────────────────────────────────────────────────────────

gpu_detect() {
  local sysfs="${LYNE_SYSFS}"/bus/pci/devices

  # Reset all arrays and scalars
  GPU_PCI=(); GPU_VENDOR_ID=(); GPU_DEVICE_ID=()
  GPU_VENDOR=(); GPU_BRAND=(); GPU_NAME=()
  GPU_KIND=(); GPU_DRIVER=(); GPU_BOOT_VGA=()
  GPU_CARD=(); GPU_OUTPUTS=()
  GPU_COUNT=-1; GPU_NVIDIA=-1; GPU_HYBRID=0; GPU_INTERNAL=-1

  # GPU vendor filter
  local -A GPU_VENDOR_IDS=(
    [10de]=1 [8086]=1 [1002]=1 [1234]=1
  )

  local idx=0
  for pci_addr in "$sysfs"/*; do
    [[ -d "$pci_addr" ]] || continue
    [[ -e "$pci_addr/vendor" ]] || continue

    local vendor_id
    vendor_id=$(cat "$pci_addr/vendor" 2>/dev/null | tr -d ' \n')
    # Strip 0x prefix for lookup
    local vendor_key="${vendor_id#0x}"
    vendor_key="${vendor_key,,}"

    # Check if it's a known GPU vendor
    if [[ -z "${GPU_VENDOR_IDS[$vendor_key]:-}" ]]; then
      # Also check by driver for virtio-gpu
      if [[ -L "$pci_addr/driver" ]]; then
        local driver
        driver=$(readlink "$pci_addr/driver" 2>/dev/null | xargs basename)
        if [[ "$driver" == @(virtio-gpu|vmwgfx) ]]; then
          GPU_VENDOR_IDS[$vendor_key]=1
        fi
      fi
      [[ -z "${GPU_VENDOR_IDS[$vendor_key]:-}" ]] && continue
    fi

    local device_id=""
    [[ -f "$pci_addr/device" ]] && device_id=$(cat "$pci_addr/device" 2>/dev/null | tr -d ' \n')

    # Determine driver
    local driver=""
    if [[ -L "$pci_addr/driver" ]]; then
      driver=$(readlink "$pci_addr/driver" 2>/dev/null | xargs basename)
    fi

    # Determine boot_vga
    local boot_vga=""
    if [[ -f "$pci_addr/boot_vga" ]]; then
      boot_vga=$(cat "$pci_addr/boot_vga" 2>/dev/null | tr -d ' \n')
    fi

    # Get DRM cardN
    local card=""
    local drm_dir=""
    if [[ -d "$pci_addr/drm" ]]; then
      for cardlink in "$pci_addr/drm"/card*; do
        [[ -d "$cardlink" ]] || continue
        card=$(basename "$cardlink")
        drm_dir="$cardlink"
        break
      done
    fi

    # Enumerate connectors
    local outputs=""
    if [[ -n "$drm_dir" ]]; then
      for conn_dir in "$drm_dir"/*; do
        [[ -d "$conn_dir" ]] || continue
        local conn_name
        conn_name=$(basename "$conn_dir")
        # Strip cardN- prefix
        conn_name="${conn_name#card[0-9]-}"
        if [[ -f "$conn_dir/status" ]]; then
          local status
          status=$(cat "$conn_dir/status" 2>/dev/null | tr -d ' \n' | tr '[:upper:]' '[:lower:]')
          case "$status" in
            connected) status="connected" ;;
            disconnected) status="disconnected" ;;
            *) status="unknown" ;;
          esac
          outputs="${outputs}${conn_name}:${status} "
        fi
      done
    fi
    outputs="${outputs% }"

    # Classify vendor
    local vendor_class
    vendor_class=$(_gpu_classify_by_vendor "$vendor_id")
    if [[ "$vendor_class" == "other" ]] && [[ -n "$driver" ]]; then
      vendor_class=$(_gpu_classify_by_driver "$driver")
    fi

    # Lookup brand and name
    local brand devname
    local lookup_result
    lookup_result=$(_pci_ids_lookup "$vendor_id" "$device_id")
    brand="${lookup_result%%|*}"
    devname="${lookup_result#*|}"

    # If brand is empty, use vendor classification
    [[ -z "$brand" || "$brand" == "|" ]] && brand="${vendor_class^}"
    [[ "$brand" == "|" ]] && brand=""

    # Store per-GPU data
    GPU_PCI+=("$(basename "$pci_addr")")
    GPU_VENDOR_ID+=("$vendor_id")
    GPU_DEVICE_ID+=("$device_id")
    GPU_VENDOR+=("$vendor_class")
    GPU_BRAND+=("$brand")
    GPU_NAME+=("$devname")
    GPU_DRIVER+=("$driver")
    GPU_BOOT_VGA+=("$boot_vga")
    GPU_CARD+=("$card")
    GPU_OUTPUTS+=("$outputs")

    ((idx++)) || true
  done

  GPU_COUNT=${#GPU_PCI[@]}

  # Populate GPU_NVIDIA
  for i in "${!GPU_VENDOR[@]}"; do
    if [[ "${GPU_VENDOR[$i]}" == "nvidia" ]]; then
      GPU_NVIDIA=$i
      break
    fi
  done

  # Classify kind for each GPU and determine GPU_HYBRID and GPU_INTERNAL
  local has_integrated=0 has_dedicated=0
  for i in "${!GPU_VENDOR[@]}"; do
    local kind
    kind=$(_gpu_kind "$i")
    GPU_KIND+=("$kind")

    if [[ "$kind" == "integrated" ]]; then
      has_integrated=1
      # Check for internal panel
      local outputs="${GPU_OUTPUTS[$i]:-}"
      if [[ "$outputs" =~ eDP-1|LVDS-1|DSI-1 ]]; then
        GPU_INTERNAL=$i
      fi
    elif [[ "$kind" == "dedicated" ]]; then
      has_dedicated=1
    fi
  done

  if [[ "$has_integrated" -eq 1 ]] && [[ "$has_dedicated" -eq 1 ]]; then
    GPU_HYBRID=1
  fi
}

# ─── Human-readable output ──────────────────────────────────────────────────────

gpu_status() {
  for i in "${!GPU_PCI[@]}"; do
    echo "GPU $i: ${GPU_PCI[$i]}"
    echo "  Vendor:   ${GPU_VENDOR_ID[$i]} (${GPU_VENDOR[$i]:-unknown})"
    echo "  Brand:    ${GPU_BRAND[$i]:-Unknown}"
    echo "  Device:   ${GPU_DEVICE_ID[$i]:-Unknown} (${GPU_NAME[$i]:-Unknown})"
    echo "  Driver:   ${GPU_DRIVER[$i]:-unknown}"
    echo "  Kind:     ${GPU_KIND[$i]:-unknown}"
    echo "  Boot VGA: ${GPU_BOOT_VGA[$i]:-(n/a)}"
    echo "  Card:     ${GPU_CARD[$i]:-(n/a)}"
    echo "  Outputs:  ${GPU_OUTPUTS[$i]:-none}"
    echo ""
  done
}

gpu_summary() {
  if [[ "${GPU_COUNT:-0}" -eq 0 ]]; then
    echo "No GPU detected"
    return
  fi

  local parts=()
  for i in "${!GPU_KIND[@]}"; do
    local kind="${GPU_KIND[$i]}"
    local brand="${GPU_BRAND[$i]:-Unknown}"
    local name="${GPU_NAME[$i]:-}"
    local line="${kind^} ${brand}"
    [[ -n "$name" && "$name" != "$brand" ]] && line="$line $name"
    parts+=("$line")
  done

  local result
  printf -v result "%s + %s" "${parts[0]}" "${parts[1]:-}"
  result="${result%+ }"

  if [[ "${GPU_HYBRID:-0}" -eq 1 ]]; then
    echo "${result} (hybrid)"
  else
    echo "${result}"
  fi
}

gpu_json() {
  echo "["
  local first=true
  for i in "${!GPU_PCI[@]}"; do
    $first || echo ","
    first=false
    printf '  {\n'
    printf '    "index": %s,\n' "$i"
    printf '    "pci_addr": "%s",\n' "${GPU_PCI[$i]}"
    printf '    "vendor_id": "%s",\n' "${GPU_VENDOR_ID[$i]}"
    printf '    "device_id": "%s",\n' "${GPU_DEVICE_ID[$i]}"
    printf '    "vendor": "%s",\n' "${GPU_VENDOR[$i]}"
    printf '    "brand": "%s",\n' "${GPU_BRAND[$i]}"
    printf '    "name": "%s",\n' "${GPU_NAME[$i]}"
    printf '    "kind": "%s",\n' "${GPU_KIND[$i]}"
    printf '    "driver": "%s",\n' "${GPU_DRIVER[$i]}"
    printf '    "boot_vga": "%s",\n' "${GPU_BOOT_VGA[$i]}"
    printf '    "card": "%s",\n' "${GPU_CARD[$i]}"
    printf '    "outputs": "%s"\n' "${GPU_OUTPUTS[$i]}"
    printf '  }'
  done
  echo ""
  echo "]"
}
