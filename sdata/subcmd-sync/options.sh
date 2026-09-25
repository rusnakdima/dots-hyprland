# Handle args for subcmd: sync
# shellcheck shell=bash
showhelp(){
printf "Syntax: $0 sync [OPTIONS]...

Sync ii theme files from dots-hyprland to user's Quickshell config.

Options:
  -h, --help                Print this help message and exit
  -d, --dry-run             Show what would be synced without copying
  -f, --force              Overwrite existing files (default: skip)
  -t, --target <path>      Target directory (default: /home/dmitriy/.config/quickshell)
      --to-dmitriy          Sync to dmitriy's Quickshell config (default)
      --to-local            Sync to local ~/.config/quickshell

${STY_CYAN}
This copies ii theme files to the user's Quickshell config directory,
while preserving existing user files.
${STY_RST}
"
}

# `man getopt` to see more
para=$(getopt \
  -o hdft \
  -l help,dry-run,force,target:,to-dmitriy,to-local \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1

#####################################################################################
## getopt Phase 1
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help)
      showhelp
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -t|--target)
      SYNC_TARGET="$2"
      shift 2
      ;;
    --to-dmitriy)
      SYNC_MODE="dmitriy"
      shift
      ;;
    --to-local)
      SYNC_MODE="local"
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
done

#####################################################################################
# Default values
DRY_RUN="${DRY_RUN:-false}"
FORCE="${FORCE:-false}"
SYNC_MODE="${SYNC_MODE:-dmitriy}"

# Set target based on mode
case "$SYNC_MODE" in
  dmitriy)
    SYNC_DEST="/home/dmitriy/.config/quickshell"
    ;;
  local)
    SYNC_DEST="$HOME/.config/quickshell"
    ;;
  *)
    SYNC_DEST="${SYNC_TARGET:-/home/dmitriy/.config/quickshell}"
    ;;
esac
