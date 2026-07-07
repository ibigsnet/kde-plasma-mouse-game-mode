#!/usr/bin/env bash
# Example Steam launch option wrapper for mouse game mode.
# Usage in Steam: /path/to/this-script.sh %command%

set -euo pipefail
source "${HOME}/.local/lib/mouse-game-mode.sh"

MGM_LOGFILE="/tmp/steam-mouse-fix.log"
mgm_log "=== START (steam wrapper) ==="

echo "Mouse game mode active for this game session"

mgm_run_with_game_mode "$@"

mgm_log "=== FINISHED ==="
