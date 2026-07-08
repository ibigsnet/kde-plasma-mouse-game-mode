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

echo "Cycling properties to clear libinput middle button state desync..."

for dev in $(mgm_discover_corsair_mice); do
    echo "Resetting $dev ..."
    mgm_device_set "$dev" middleEmulation false
    mgm_device_set "$dev" scrollOnButtonDown false
    mgm_device_set "$dev" enabled false
    sleep 0.5
    mgm_device_set "$dev" enabled true
    sleep 0.2
    mgm_device_set "$dev" middleEmulation true
    mgm_device_set "$dev" scrollOnButtonDown true
done

# Safe KDE settings
mgm_reset_safe

# Ensure enabled
for dev in $(mgm_discover_corsair_mice); do
    mgm_device_set "$dev" enabled true
done

echo "Current Corsair mice:"
mgm_describe_devices
echo "Done. If still broken: unplug/replug the mouse USB while in desktop mode."
echo "Then run: mouse-game-mode desktop"