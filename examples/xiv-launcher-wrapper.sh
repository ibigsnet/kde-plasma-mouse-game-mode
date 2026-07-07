#!/usr/bin/env bash
# Example XIVLauncher wrapper with mouse game mode.
# Customize envs and flatpak command as needed.

set -euo pipefail
source "${HOME}/.local/lib/mouse-game-mode.sh"

MGM_LOGFILE="/tmp/xiv-mouse-fix.log"
mgm_log "=== START (XIVLauncher) ==="

echo "XIVLauncher starting with mouse fix"

mgm_run_with_game_mode \
    flatpak run \
    --env=...your-nvidia-dlss-envs-here... \
    dev.goats.xivlauncher "$@"
