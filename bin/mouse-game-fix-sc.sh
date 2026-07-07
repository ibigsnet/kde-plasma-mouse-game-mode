#!/usr/bin/env bash
# Steam wrapper example for games with gamescope: mouse game mode + gamemoderun + mangohud
# Usage: mouse-game-fix-sc.sh %command%

set -euo pipefail
source "${HOME}/.local/lib/mouse-game-mode.sh"

MGM_LOGFILE="/tmp/steam-mouse-fix.log"
mgm_log "=== START (mouse-game-fix-sc) ==="

echo "Mouse fix active + gamescope"

mgm_run_with_game_mode \
    gamemoderun \
    gamescope -f --force-grab-cursor -- \
    mangohud "$@"

mgm_log "=== FINISHED (mouse-game-fix-sc) ==="