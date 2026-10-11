# This script is meant to be sourced.
# It's not for directly running.

install-yay(){
  x sudo -n pacman -S --needed --noconfirm base-devel
  x git clone https://aur.archlinux.org/yay-bin.git /tmp/buildyay
  x cd /tmp/buildyay
  x makepkg -o
  x makepkg -se
  x makepkg -i --noconfirm
  x cd ${REPO_ROOT}
  rm -rf /tmp/buildyay
}

remove_deprecated_dependencies(){
  printf "${STY_CYAN}[$0]: Removing deprecated dependencies:${STY_RST}\n"
  local list=()
  list+=(illogical-impulse-{microtex,pymyc-aur,oneui4-icons-git})
  list+=(hyprland-qtutils)
  list+=({quickshell,hyprutils,hyprpicker,hyprlang,hypridle,hyprland-qt-support,hyprland-qtutils,hyprlock,xdg-desktop-portal-hyprland,hyprcursor,hyprwayland-scanner,hyprland}-git)
  list+=(matugen-bin)
  for i in ${list[@]};do try sudo -n pacman --noconfirm -Rdd $i;done
}

# Register all git repos (including nested) under src/dist-arch as safe.
# This prevents "dubious ownership" errors when makepkg clones git repos as root.
git_config_safe_dirs(){
  local _dir
  while IFS= read -r _dir; do
    [[ -d "$_dir" ]] || continue
    git config --global --add safe.directory "$_dir" 2>/dev/null || true
  done < <(find "${REPO_ROOT}/src/dist-arch" -name ".git" -type d 2>/dev/null | while IFS= read -r _gd; do dirname "$_gd"; done)
  # Also register the repo root itself.
  git config --global --add safe.directory "${REPO_ROOT}" 2>/dev/null || true
}

# NOTE: `implicitize_old_dependencies()` was for the old days when we just switch from dependencies.conf to local PKGBUILDs.
# However, let's just keep it as references for other distros writing their `src/dist-<OS_GROUP_ID>/install-deps.sh`, if they need it.
implicitize_old_dependencies(){
# Convert old dependencies to non explicit dependencies so that they can be orphaned if not in meta packages
  remove_bashcomments_emptylines ./src/dist/arch/previous_dependencies.conf ./cache/old_deps_stripped.conf
  readarray -t old_deps_list < ./cache/old_deps_stripped.conf
  pacman -Qeq > ./cache/pacman_explicit_packages
  readarray -t explicitly_installed < ./cache/pacman_explicit_packages

  echo "Attempting to set previously explicitly installed deps as implicit..."
  for i in "${explicitly_installed[@]}"; do for j in "${old_deps_list[@]}"; do
    [ "$i" = "$j" ] && yay -D --asdeps "$i"
  done; done

  return 0
}

#####################################################################################
if ! command -v pacman >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...${STY_RST}\n"
  exit 1
fi

# If running as root, no sudo needed — call pacman directly
if [[ $(whoami) == "root" ]]; then
  pacman() { command pacman "$@"; }
fi

# Keep makepkg from resetting sudo credentials
if [[ -z "${PACMAN_AUTH:-}" ]]; then
  export PACMAN_AUTH="sudo"
fi

# Per-package status tracking for install summary
declare -A PKG_STATUS
declare -A PKG_REASON

# When true, skip packages that fail instead of aborting the whole install
SKIP_BROKEN="${SKIP_BROKEN:-false}"

# Print install summary on exit — always runs via trap, even on Ctrl+C / error
print_summary(){
  local _failed=0
  printf "\n[$0]: Install summary:\n"
  printf "  %-50s %-20s %s\n" "PACKAGE" "STATUS" "REASON"
  printf "  %-50s %-20s %s\n" "-------" "------" "------"
  local _pkg
  for _pkg in "${!PKG_STATUS[@]}"; do
    local _status="${PKG_STATUS[$_pkg]}"
    local _reason="${PKG_REASON[$_pkg]:-}"
    if [[ "$_status" == "FAILED" ]]; then
      _failed=1
    fi
    printf "  %-50s %-20s %s\n" "$_pkg" "$_status" "$_reason"
  done
  return $_failed
}
trap 'print_summary' EXIT

showfun remove_deprecated_dependencies
v remove_deprecated_dependencies

# Safe directory pre-flight — before any makepkg/git operations
git_config_safe_dirs

# GPU detection — runs before metapkg selection so GPU_NVIDIA etc. are populated.
source "${REPO_ROOT}/src/lib/gpus.sh"
gpu_detect
printf "${STY_CYAN}[$0]: GPU: ${GPU_COUNT} found, NVIDIA=${GPU_NVIDIA}${STY_RST}\n"

# Issue #363
case "${SKIP_SYSUPDATE:-false}" in
  true) true;;
  *) v sudo -n pacman -Syu --noconfirm;;
esac

# Use yay. Because paru does not support cleanbuild.
# Also see https://wiki.hyprland.org/FAQ/#how-do-i-update
if ! command -v yay >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"yay\" not found.${STY_RST}"
  showfun install-yay
  v install-yay
fi

showfun implicitize_old_dependencies
v implicitize_old_dependencies

# https://github.com/end-4/dots-hyprland/issues/581
# yay -Bi is kinda hit or miss, instead cd into the relevant directory and manually source and install deps
aur_fallback(){
  # Fall back to AUR package if PKGBUILD install fails
  local _location=$1
  local _pkgname
  _pkgname=$(cd "$_location" && . ./PKGBUILD && echo "$pkgname")
  printf "${STY_YELLOW}[$0]: AUR fallback for ${_pkgname}...${STY_RST}\n"
  if yay -S --noconfirm --needed --asdeps "$_pkgname" 2>/dev/null; then
    PKG_STATUS[$_pkgname]="OK (AUR fallback)"
    PKG_REASON[$_pkgname]="AUR fallback succeeded"
    return 0
  else
    PKG_STATUS[$_pkgname]="FAILED"
    PKG_REASON[$_pkgname]="makepkg failed, AUR fallback also failed"
    return 1
  fi
}

# Wrapper: try PKGBUILD first, fall back to AUR on failure.
try_install_package(){
  local _location=$1
  local _installflags=$2
  local _pkgname
  _pkgname=$(cd "$_location" && . ./PKGBUILD && echo "$pkgname")

  # Run makepkg in subshell so failure doesn't propagate to the outer loop.
  local _rc=0
  (
    set +e
    install-local-pkgbuild "$_location" "$_installflags"
  )
  _rc=$?

  if [[ $_rc -ne 0 ]]; then
    if [[ "$SKIP_BROKEN" == "true" ]]; then
      PKG_STATUS[$_pkgname]="FAILED (skipped)"
      PKG_REASON[$_pkgname]="SKIP_BROKEN=true, skipped after failure"
      printf "${STY_YELLOW}[$0]: ${_pkgname} failed but SKIP_BROKEN=true — skipping.${STY_RST}\n"
      return 0
    fi
    printf "${STY_YELLOW}[$0]: ${_pkgname} makepkg failed (rc=$_rc), trying AUR fallback...${STY_RST}\n"
    aur_fallback "$_location"
    return $?
  fi
  PKG_STATUS[$_pkgname]="OK"
  PKG_REASON[$_pkgname]="already current"
  return 0
}

install-local-pkgbuild() {
  local location=$1
  local installflags=$2
  local pkgname installed_ver pkgfile

  pushd "$location" >/dev/null || return 1

  source ./PKGBUILD
  pkgname=$pkgname  # capture from sourced PKGBUILD
  x yay -S $installflags --asdeps "${depends[@]}"

  # Phase 1 — build only (no install), so we can inspect the artifact before committing to install.
  # Wrapped in subshell with set +e so makepkg failure exits the subshell but not the parent function.
  local _makepkg_rc=0
  (
    set +e
    # --noconfirm: skip confirmation prompts
    # -A: ignore arch field
    # -s: syncdeps
    # -f: force rebuild
    makepkg -Afs --noconfirm
  )
  _makepkg_rc=$?

  if [[ $_makepkg_rc -ne 0 ]]; then
    printf "${STY_RED}[$0]: makepkg failed for ${pkgname} (rc=$_makepkg_rc)${STY_RST}\n"
    popd >/dev/null
    return 1
  fi

  # Phase 2 — locate the built package artifact so we can install it explicitly with overwrite flags.
  pkgfile="$(ls -1 ${PKGDEST:-.}/${pkgname}-*.pkg.tar.zst 2>/dev/null | sort -V | tail -n1)"
  if [[ -z "${pkgfile}" ]]; then
    printf "${STY_RED}[$0]: Could not locate built package for ${pkgname}. Run 'makepkg' manually in ${location} for diagnostics.${STY_RST}\n"
    popd >/dev/null
    return 1
  fi

  # Phase 3 — install with overwrite to survive residual file-ownership conflicts that
  # remove_stale_ii_packages could not reach (e.g. mid-loop Qt ABI mismatch on quickshell-git).
  # Skip entirely if the installed version matches what we just built to avoid pacman returning
  # a spurious non-zero exit due to timestamp/recompression differences.
  installed_ver="$(pacman -Q "${pkgname}" 2>/dev/null | awk '{print $2}')"
  if [[ "${installed_ver}" == "${pkgver}-${pkgrel}" ]]; then
    printf "${STY_BLUE}[$0]: ${pkgname} is already installed at the same version (${installed_ver}). Skipping pacman -U.${STY_RST}\n"
  else
    x sudo -n pacman -U --noconfirm --overwrite '*' "${pkgfile}"
  fi
  popd >/dev/null
  return 0
}

# Resolve machine profile: auto probes battery to decide laptop/desktop,
# laptop/desktop are forced. Result written to ~/.config/dots-hyprland/MACHINE.
resolve_profile(){
  if [[ "$MACHINE_PROFILE" == "auto" ]]; then
    if [[ -f "${HOME}/.config/dots-hyprland/MACHINE" ]]; then
      MACHINE_PROFILE="$(cat "${HOME}/.config/dots-hyprland/MACHINE")"
      printf "${STY_CYAN}[$0]: Machine profile from cached file: ${MACHINE_PROFILE}${STY_RST}\n"
    else
      # Probe: battery presence = laptop, else desktop
      if [[ -n "$(ls /sys/class/power_supply/BAT* 2>/dev/null)" ]]; then
        MACHINE_PROFILE="laptop"
      else
        MACHINE_PROFILE="desktop"
      fi
      printf "${STY_CYAN}[$0]: Machine profile auto-detected: ${MACHINE_PROFILE}${STY_RST}\n"
    fi
  fi
  mkdir -p "${HOME}/.config/dots-hyprland"
  printf '%s\n' "$MACHINE_PROFILE" > "${HOME}/.config/dots-hyprland/MACHINE"
  printf "${STY_CYAN}[$0]: Machine profile: ${MACHINE_PROFILE}${STY_RST}\n"
}
resolve_profile

# Base packages — always installed
metapkgs_base=(
  ./src/dist/arch/illogical-impulse-{audio,basic,fonts-themes,portal,python,screencapture,toolkit,widgets}
  ./src/dist/arch/illogical-impulse-hyprland
  ./src/dist/arch/illogical-impulse-microtex-git
  ./src/dist/arch/illogical-impulse-quickshell-git
  ./src/dist/arch/illogical-impulse-bibata-modern-classic-bin
)

# Laptop-only packages (backlight and kde/powerdevil for battery management)
metapkgs_laptop=(
  ./src/dist/arch/illogical-impulse-backlight
  ./src/dist/arch/illogical-impulse-kde
)

# NVIDIA packages — added when GPU_NVIDIA >= 0
metapkgs_nvidia=(
  ./src/dist/arch/illogical-impulse-nvidia
)

# Build final metapkgs array based on resolved profile
metapkgs=("${metapkgs_base[@]}")
if [[ "$MACHINE_PROFILE" == "laptop" ]]; then
  metapkgs+=("${metapkgs_laptop[@]}")
fi
if [[ "$GPU_NVIDIA" -ge 0 ]] && [[ "${SKIP_NVIDIA_PKG:-false}" != "true" ]]; then
  # Detect existing NVIDIA driver to avoid package conflicts
  local _nvidia_pkg=""
  if pacman -Q nvidia-open-dkms &>/dev/null; then
    _nvidia_pkg="nvidia-open-dkms"
    printf "${STY_CYAN}[$0]: Detected existing NVIDIA open driver — will match existing driver.${STY_RST}\n"
  elif pacman -Q nvidia-580xx-dkms &>/dev/null; then
    _nvidia_pkg="nvidia-580xx-dkms"
    printf "${STY_CYAN}[$0]: Detected existing NVIDIA 580xx driver — will match existing driver.${STY_RST}\n"
  elif pacman -Q nvidia-dkms &>/dev/null; then
    _nvidia_pkg="nvidia-dkms"
    printf "${STY_CYAN}[$0]: Detected existing NVIDIA driver — will match existing driver.${STY_RST}\n"
  fi
  if [[ -n "$_nvidia_pkg" ]]; then
    # Update nvidia meta-pkg to use detected driver
    printf "${STY_CYAN}[$0]: Using existing NVIDIA driver packages instead of meta-package.${STY_RST}\n"
  else
    metapkgs+=("${metapkgs_nvidia[@]}")
  fi
fi

# ─── Hardware probe: AIC8800 USB WiFi adapter ─────────────────────────────────
if lsusb 2>/dev/null | grep -q "0b05:5721"; then
  printf "${STY_CYAN}[$0]: AIC8800 USB WiFi adapter detected — running install_aic8800...${STY_RST}\n"
  install_aic8800
fi

# ─── Hardware probe: Tuxedo / QC71 keyboard ────────────────────────────────
_tuxedo_detected=false
for _hwmon in /sys/class/hwmon/hwmon*/name; do
  if grep -qiE "tuxedo_keyboard|qc71_laptop|tuxedo" "$_hwmon" 2>/dev/null; then
    _tuxedo_detected=true
    break
  fi
done
if [[ "$_tuxedo_detected" == "true" ]]; then
  printf "${STY_CYAN}[$0]: Tuxedo/QC71 keyboard detected${STY_RST}\n"
  if [[ "$MACHINE_PROFILE" == "laptop" ]]; then
    metapkgs_tuxedo=(./src/dist/arch/illogical-impulse-tuxedo)
    metapkgs+=("${metapkgs_tuxedo[@]}")
  fi
fi

printf "${STY_CYAN}[$0]: Removing previously installed illogical-impulse-* packages (if any) before rebuild to avoid pacman transaction errors.${STY_RST}\n"

remove_stale_ii_packages(){
  local stale_pkgs
  stale_pkgs="$(pacman -Qq illogical-impulse- 2>/dev/null)" || stale_pkgs=""
  if [[ -z "${stale_pkgs}" ]]; then
    return 0
  fi
  printf "${STY_YELLOW}[$0]: Found stale illogical-impulse-* packages installed: ${stale_pkgs}${STY_RST}\n"
  printf "${STY_YELLOW}[$0]: Force-removing them with pacman -Rdd to allow clean rebuild...${STY_RST}\n"
  # Use || true so a failure here does not abort the whole install — per-metapkg install will surface any remaining issue.
  sudo -n pacman -Rdd --noconfirm ${stale_pkgs} 2>/dev/null || true
  # Also clear stale built package files left over from previous partial installs to avoid makepkg confusion.
  find ./src/dist-arch -maxdepth 2 -name '*.pkg.tar.zst' -delete 2>/dev/null || true
  return 0
}
remove_stale_ii_packages

for i in "${metapkgs[@]}"; do
  metainstallflags="--needed"
  $ask && showfun try_install_package || metainstallflags="$metainstallflags --noconfirm"
  v try_install_package "$i" "$metainstallflags"
done

install-dinit-service-packages(){
  local -a pkgs=()
  local pkg

  if ! command -v dinitctl >/dev/null 2>&1; then
    return 0
  fi

  for pkg in userspawn-dinit bluez-dinit networkmanager-dinit pipewire-dinit pipewire-pulse-dinit wireplumber-dinit power-profiles-daemon-dinit; do
    if pacman -Si "$pkg" >/dev/null 2>&1; then
      pkgs+=("$pkg")
    fi
  done

  if (( ${#pkgs[@]} > 0 )); then
    printf "${STY_YELLOW}[$0]: Detected dinit init system, installing service packages: ${pkgs[*]}${STY_RST}\n"
    x sudo -n pacman -S --needed --noconfirm "${pkgs[@]}"
  fi
}
showfun install-dinit-service-packages
v install-dinit-service-packages

# Additional runtime dependencies not in meta-packages
printf "${STY_CYAN}[$0]: Installing additional dependencies...${STY_RST}\n"
for pkg in hostapd; do
  if ! pacman -Q "$pkg" &>/dev/null; then
    x sudo -n pacman -S --needed --noconfirm "$pkg"
  fi
done

## AIC8800D80 USB WiFi+BT adapter
# Installs mode-switch rule, udev hook, DKMS modules, and firmware
# Idempotent: safe for machines without the hardware (steps gracefully skip)
install_aic8800(){
  case "${SKIP_AIC8800:-false}" in
    true) printf "${STY_YELLOW}[$0]: SKIP_AIC8800=true — skipping AIC8800 setup.${STY_RST}\n"; return 0 ;;
  esac
  local aic_dir="${REPO_ROOT}/sys/aic8800-usb-5.0+git20260123.5f7be68d-8"
  local fw_dir="/lib/firmware/aic8800D80"
  local files_dir="${aic_dir}/files"

  # usb_modeswitch package
  if ! pacman -Q usb_modeswitch &>/dev/null; then
    printf "${STY_CYAN}[$0]: Installing usb_modeswitch...${STY_RST}\n"
    x sudo -n pacman -S --needed --noconfirm usb_modeswitch
  fi

  # Mode-switch config
  if [[ -d "${files_dir}/etc/usb_modeswitch.d" ]]; then
    printf "${STY_CYAN}[$0]: Installing AIC8800 mode-switch config...${STY_RST}\n"
    x sudo install -Dm644 "${files_dir}/etc/usb_modeswitch.d/a69c:5721" /etc/usb_modeswitch.d/a69c:5721
  fi

  # udev rule
  if [[ -d "${files_dir}/etc/udev/rules.d" ]]; then
    printf "${STY_CYAN}[$0]: Installing AIC8800 udev rules...${STY_RST}\n"
    x sudo install -Dm644 "${files_dir}/etc/udev/rules.d/99-aic8800-modeswitch.rules" /etc/udev/rules.d/99-aic8800-modeswitch.rules
    x sudo udevadm control --reload-rules
    x sudo udevadm trigger
  fi

  # modules-load.d
  if [[ -f "${files_dir}/etc/modules-load.d/aic8800.conf" ]]; then
    printf "${STY_CYAN}[$0]: Installing AIC8800 module autoload...${STY_RST}\n"
    x sudo install -Dm644 "${files_dir}/etc/modules-load.d/aic8800.conf" /etc/modules-load.d/aic8800.conf
  fi

  # Firmware
  if [[ -d "${aic_dir}/fw/aic8800D80" ]]; then
    if [[ ! -d "${fw_dir}" ]] || [[ $(ls -1 "${fw_dir}" | wc -l) -lt 5 ]]; then
      printf "${STY_CYAN}[$0]: Installing AIC8800D80 firmware...${STY_RST}\n"
      x sudo mkdir -p "${fw_dir}"
      x sudo cp -r "${aic_dir}/fw/aic8800D80/"* "${fw_dir}/" 2>/dev/null || true
      x sudo cp -r "${aic_dir}/fw/aic8800/"* "${fw_dir}/" 2>/dev/null || true
    fi
  fi

  # DKMS build
  if [[ -d "${aic_dir}/drivers" ]] && [[ -f "${aic_dir}/dkms.conf" ]]; then
    local dkms_name="aic8800d80"
    local dkms_ver="1.0.0"
    if ! dkms status 2>/dev/null | grep -q "${dkms_name}/${dkms_ver}"; then
      printf "${STY_CYAN}[$0]: Building AIC8800 DKMS modules...${STY_RST}\n"
      x sudo mkdir -p "/usr/src/${dkms_name}-${dkms_ver}"
      x sudo cp -r "${aic_dir}/drivers" "/usr/src/${dkms_name}-${dkms_ver}/"
      x sudo cp "${aic_dir}/dkms.conf" "/usr/src/${dkms_name}-${dkms_ver}/"
      x sudo dkms add "${dkms_name}/${dkms_ver}" 2>/dev/null || true
      x sudo dkms build "${dkms_name}/${dkms_ver}" 2>&1 | tail -3
      x sudo dkms install "${dkms_name}/${dkms_ver}" 2>&1 | tail -3
    fi
  fi

  printf "${STY_GREEN}[$0]: AIC8800 setup complete. Replug the adapter if already attached.${STY_RST}\n"
}
v install_aic8800

## Keyboard RGB backlight udev rule (rgb:kbd_backlight sysfs, no sudo needed)
install_kbd_backlight_udev(){
  case "${SKIP_KBD_BACKLIGHT:-false}" in
    true) printf "${STY_YELLOW}[$0]: SKIP_KBD_BACKLIGHT=true — skipping kbd-backlight setup.${STY_RST}\n"; return 0 ;;
  esac
  local rules_src="${REPO_ROOT}/sys/etc/udev/rules.d/90-kbd-backlight.rules"
  local rules_dst="/etc/udev/rules.d/90-kbd-backlight.rules"
  if [[ ! -f "${rules_src}" ]]; then
    printf "${STY_YELLOW}[$0]: kbd-backlight udev rule not found at ${rules_src}, skipping.${STY_RST}\n"
    return 0
  fi
  if [[ -f "${rules_dst}" ]]; then
    printf "${STY_GREEN}[$0]: kbd-backlight udev rule already installed.${STY_RST}\n"
  else
    printf "${STY_CYAN}[$0]: Installing kbd-backlight udev rule...${STY_RST}\n"
    x sudo install -Dm644 "${rules_src}" "${rules_dst}"
    x sudo udevadm control --reload-rules
    x sudo udevadm trigger
    printf "${STY_GREEN}[$0]: kbd-backlight udev rule installed.${STY_RST}\n"
  fi
}
v install_kbd_backlight_udev

## Optional dependencies
if pacman -Qs ^plasma-browser-integration$ ;then SKIP_PLASMAINTG=true;fi
case $SKIP_PLASMAINTG in
  true) true;;
  *)
    if $ask;then
      echo -e "${STY_YELLOW}[$0]: NOTE: The size of \"plasma-browser-integration\" is ~600 KiB, but if you don't yet have KDE on your system it'll pull an extra ~600MiB of packages.${STY_RST}"
      echo -e "${STY_YELLOW}It is needed if you want playtime of media in Firefox to be shown on the music controls widget.${STY_RST}"
      echo -e "${STY_YELLOW}Install it? [y/N]${STY_RST}"
      read -p "====> " p
    else
      p=y
    fi
    case $p in
      y) x sudo -n pacman -S --needed --noconfirm plasma-browser-integration ;;
      *) echo "Ok, won't install"
    esac
    ;;
esac
