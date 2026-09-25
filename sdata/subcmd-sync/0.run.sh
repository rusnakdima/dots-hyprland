#!/usr/bin/env bash
# sync subcommand - Sync ii theme to user's Quickshell config
# Usage: ./setup sync [OPTIONS]

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/sdata/lib/environment-variables.sh"
source "${REPO_ROOT}/sdata/lib/functions.sh"

#####################################################################################
printf "${STY_CYAN}[$0]: Sync ii theme to Quickshell config${STY_RST}\n"
printf "${STY_CYAN}Destination: ${SYNC_DEST}${STY_RST}\n"
echo ""

#####################################################################################
# Validate source
SRC="${REPO_ROOT}/dots/.config/quickshell"
if [[ ! -d "$SRC" ]]; then
  printf "${STY_RED}[$0]: Source directory not found: $SRC${STY_RST}\n"
  exit 1
fi

# Validate destination parent
if [[ ! -d "$(dirname "${SYNC_DEST}")" ]]; then
  printf "${STY_RED}[$0]: Parent directory not found: $(dirname "${SYNC_DEST}")${STY_RST}\n"
  exit 1
fi

# Create destination quickshell dir if needed
if [[ ! -d "${SYNC_DEST}" ]]; then
  printf "${STY_YELLOW}[$0]: Creating ${SYNC_DEST}${STY_RST}\n"
  mkdir -p "${SYNC_DEST}"
fi

#####################################################################################
# Build rsync options
RSYNC_OPTS=(-avh --progress)

if [[ "${DRY_RUN}" == "true" ]]; then
  RSYNC_OPTS+=(--dry-run)
  printf "${STY_YELLOW}[$0]: DRY RUN MODE - No changes will be made${STY_RST}\n"
fi

if [[ "${FORCE}" != "true" ]]; then
  RSYNC_OPTS+=(--ignore-existing)
  printf "${STY_YELLOW}[$0]: Using --ignore-existing (existing files will be skipped)${STY_RST}\n"
  printf "${STY_YELLOW}[$0]: Use --force to overwrite existing files${STY_RST}\n"
else
  printf "${STY_YELLOW}[$0]: Using --force (will overwrite existing files)${STY_RST}\n"
fi

echo ""

#####################################################################################
# Show stats
SRC_COUNT=$(find "${SRC}" -type f -name "*.qml" 2>/dev/null | wc -l)
DEST_COUNT=$(find "${SYNC_DEST}" -type f -name "*.qml" 2>/dev/null | wc -l)
printf "${STY_CYAN}Source QML files: ${SRC_COUNT}${STY_RST}\n"
printf "${STY_YELLOW}Dest QML files:   ${DEST_COUNT}${STY_RST}\n"
echo ""

#####################################################################################
# Dry run - show what would be synced
if [[ "${DRY_RUN}" == "true" ]]; then
  echo -e "${STY_CYAN}[$0]: Files that would be synced:${STY_RST}"
  rsync -avh --dry-run --stats "${SRC}/" "${SYNC_DEST}/" 2>/dev/null | tail -10
  echo ""
  printf "${STY_GREEN}[$0]: Dry run complete. Run without --dry-run to sync.${STY_RST}\n"
  exit 0
fi

#####################################################################################
# Confirm
if [[ "${FORCE}" != "true" ]]; then
  printf "${STY_YELLOW}[$0]: This will copy new files but NOT overwrite existing.${STY_RST}\n"
fi
pause

#####################################################################################
# Do sync
printf "${STY_CYAN}[$0]: Syncing...${STY_RST}\n"
rsync "${RSYNC_OPTS[@]}" "${SRC}/" "${SYNC_DEST}/"

#####################################################################################
# Summary
echo ""
printf "${STY_GREEN}[$0]: Sync complete!${STY_RST}\n"

FINAL_COUNT=$(find "${SYNC_DEST}" -type f -name "*.qml" 2>/dev/null | wc -l)
printf "${STY_CYAN}Destination now has: ${FINAL_COUNT} QML files${STY_RST}\n"

# Restart Quickshell hint
echo ""
printf "${STY_CYAN}[$0]: You may need to restart Quickshell for changes to take effect.${STY_RST}\n"
