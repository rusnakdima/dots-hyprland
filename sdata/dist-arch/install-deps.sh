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
# NOTE: `implicitize_old_dependencies()` was for the old days when we just switch from dependencies.conf to local PKGBUILDs.
# However, let's just keep it as references for other distros writing their `sdata/dist-<OS_GROUP_ID>/install-deps.sh`, if they need it.
implicitize_old_dependencies(){
# Convert old dependencies to non explicit dependencies so that they can be orphaned if not in meta packages
  remove_bashcomments_emptylines ./sdata/dist-arch/previous_dependencies.conf ./cache/old_deps_stripped.conf
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

showfun remove_deprecated_dependencies
v remove_deprecated_dependencies

# Issue #363
case $SKIP_SYSUPDATE in
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
install-local-pkgbuild() {
  local location=$1
  local installflags=$2

  x pushd $location

  source ./PKGBUILD
  x yay -S $installflags --asdeps "${depends[@]}"
  # Phase 1 — build only (no install), so we can inspect the artifact before committing to install.
  # man makepkg:
  # -A, --ignorearch: Ignore a missing or incomplete arch field in the build script.
  # -s, --syncdeps: Install missing dependencies using pacman. When build-time or run-time dependencies are not found, pacman will try to resolve them.
  # -f, --force: build a package even if it already exists in the PKGDEST
  x makepkg -Afs --noconfirm

  # Phase 2 — locate the built package artifact so we can install it explicitly with overwrite flags.
  local pkgfile
  pkgfile="$(ls -1 ${PKGDEST:-.}/${pkgname}-*.pkg.tar.zst 2>/dev/null | sort -V | tail -n1)"
  if [[ -z "${pkgfile}" ]]; then
    printf "${STY_RED}[$0]: Could not locate built package for ${pkgname}. Run 'makepkg' manually in ${location} for diagnostics.${STY_RST}\n"
    x popd
    return 1
  fi

  # Phase 3 — install with overwrite to survive residual file-ownership conflicts that
  # remove_stale_ii_packages could not reach (e.g. mid-loop Qt ABI mismatch on quickshell-git).
  # Skip entirely if the installed version matches what we just built to avoid pacman returning
  # a spurious non-zero exit due to timestamp/recompression differences.
  local installed_ver
  installed_ver="$(pacman -Q "${pkgname}" 2>/dev/null | awk '{print $2}')"
  if [[ "${installed_ver}" == "${pkgver}-${pkgrel}" ]]; then
    printf "${STY_BLUE}[$0]: ${pkgname} is already installed at the same version (${installed_ver}). Skipping pacman -U.${STY_RST}\n"
  else
    x sudo -n pacman -U --noconfirm --overwrite '*' "${pkgfile}"
  fi
  x popd
}

# Install core dependencies from the meta-packages
metapkgs=(./sdata/dist-arch/illogical-impulse-{audio,backlight,basic,fonts-themes,kde,portal,python,screencapture,toolkit,widgets})
metapkgs+=(./sdata/dist-arch/illogical-impulse-hyprland)
metapkgs+=(./sdata/dist-arch/illogical-impulse-microtex-git)
metapkgs+=(./sdata/dist-arch/illogical-impulse-quickshell-git)
metapkgs+=(./sdata/dist-arch/illogical-impulse-bibata-modern-classic-bin)

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
  find ./sdata/dist-arch -maxdepth 2 -name '*.pkg.tar.zst' -delete 2>/dev/null || true
  return 0
}
remove_stale_ii_packages

for i in "${metapkgs[@]}"; do
  metainstallflags="--needed"
  $ask && showfun install-local-pkgbuild || metainstallflags="$metainstallflags --noconfirm"
  v install-local-pkgbuild "$i" "$metainstallflags"
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
  local aic_dir="${REPO_ROOT}/dots-extra/aic8800-usb-5.0+git20260123.5f7be68d-8"
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
  local rules_src="${REPO_ROOT}/dots-extra/etc/udev/rules.d/90-kbd-backlight.rules"
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
