#!/usr/bin/env bash
# Steam wrapper example: mouse game mode + mangohud
# Usage: mouse-game-fix.sh %command%
#
# Put this in your Steam launch options for games:
#   /path/to/mouse-game-fix.sh %command%

set -euo pipefail
source "${HOME}/.local/lib/mouse-game-mode.sh"

MGM_LOGFILE="/tmp/steam-mouse-fix.log"
mgm_log "=== START (mouse-game-fix) ==="

echo "Mouse fix active + mangohud"
mgm_run_with_game_mode mangohud "$@"
mgm_log "=== FINISHED (mouse-game-fix) ==="