#!/usr/bin/env bash
# Emergency desktop mouse recovery.
set -euo pipefail
# shellcheck source=/dev/null
source "${HOME}/.local/lib/mouse-game-mode.sh"

echo "=== Mouse emergency reset ==="

# Stop gamescope cursor grabs (common cause of dead desktop clicks).
if command -v pkill >/dev/null 2>&1; then
    pkill -x gamescope 2>/dev/null || true
    pkill -x gamescopereaper 2>/dev/null || true
fi

# Safe KDE settings: never re-enable middle-click emulation.
mgm_reset_safe

# Re-enable all Corsair pointer devices in case one was disabled.
for dev in $(mgm_discover_corsair_mice); do
    mgm_device_set "$dev" enabled true
done

echo "Current Corsair mice:"
mgm_describe_devices
echo "Done. If clicks still fail: Alt+Tab out of fullscreen games, then unplug/replug the mouse USB."