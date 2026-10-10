# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
XDG_BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

STY_RED='\e[31m'
STY_GREEN='\e[32m'
STY_YELLOW='\e[33m'
STY_BLUE='\e[34m'
STY_PURPLE='\e[35m'
STY_CYAN='\e[36m'

STY_BOLD='\e[1m'
STY_FAINT='\e[2m'
STY_SLANT='\e[3m'
STY_UNDERLINE='\e[4m'
STY_BLINK='\e[5m'
STY_INVERT='\e[7m'
STY_RST='\e[00m'

# Used by register_temp_file()
declare -a TEMP_FILES_TO_CLEANUP=()

# Used by install script
BACKUP_DIR="${BACKUP_DIR:-$HOME/ii-original-dots-backup}"
DOTS_CORE_CONFDIR="${XDG_CONFIG_HOME}/illogical-impulse"
INSTALLED_LISTFILE="${DOTS_CORE_CONFDIR}/installed_listfile"
FIRSTRUN_FILE="${DOTS_CORE_CONFDIR}/installed_true"

# Machine profile: auto (probe hardware), laptop, or desktop
MACHINE_PROFILE="${MACHINE_PROFILE:-auto}"

# Install skip flags (set via --skip-* options in setup install)
SKIP_ALLGREETING="${SKIP_ALLGREETING:-false}"
SKIP_ALLDEPS="${SKIP_ALLDEPS:-false}"
SKIP_ALLSETUPS="${SKIP_ALLSETUPS:-false}"
SKIP_ALLFILES="${SKIP_ALLFILES:-false}"
