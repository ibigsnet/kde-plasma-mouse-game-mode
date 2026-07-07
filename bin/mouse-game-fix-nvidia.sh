#!/usr/bin/env bash
# Steam wrapper example: mouse game mode + NVIDIA offload + mangohud
# Usage: mouse-game-fix-nvidia.sh %command%
#
# Customize the env vars for your GPU setup.

set -euo pipefail
source "${HOME}/.local/lib/mouse-game-mode.sh"

MGM_LOGFILE="/tmp/steam-mouse-fix-nvidia.log"
mgm_log "=== START (mouse-game-fix-nvidia) ==="

echo "Mouse fix active + NVIDIA + mangohud"

mgm_run_with_game_mode \
    env \
    __NV_PRIME_RENDER_OFFLOAD=1 \
    __GLX_VENDOR_LIBRARY_NAME=nvidia \
    __VK_LAYER_NV_optimus=NVIDIA_only \
    DXVK_FILTER_DEVICE_NAME="NVIDIA GeForce RTX 5090" \
    VKD3D_FILTER_DEVICE_NAME="NVIDIA GeForce RTX 5090" \
    PROTON_ENABLE_NVAPI=1 \
    WINE_HIDE_NVIDIA_GPU=0 \
    mangohud "$@"

mgm_log "=== FINISHED (mouse-game-fix-nvidia) ==="