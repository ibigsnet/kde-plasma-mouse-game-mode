#!/usr/bin/env bash
# Strong recovery for stuck middle button emulation state in libinput/KWin
# Run this when normal clicks stop working but L+R scroll still does.

set -euo pipefail

echo "=== Fixing stuck middle button emulation state ==="
echo "This will cycle properties and inject button release events."

# Disable emulation and scroll first to clear the logic
echo "Disabling emulation..."
qdbus org.kde.KWin /org/kde/KWin/InputDevice/event2 org.freedesktop.DBus.Properties.Set org.kde.KWin.InputDevice middleEmulation false 2>/dev/null || true
qdbus org.kde.KWin /org/kde/KWin/InputDevice/event2 org.freedesktop.DBus.Properties.Set org.kde.KWin.InputDevice scrollOnButtonDown false 2>/dev/null || true
qdbus org.kde.KWin /org/kde/KWin/InputDevice/event2 org.freedesktop.DBus.Properties.Set org.kde.KWin.InputDevice enabled false 2>/dev/null || true

sleep 1

# Try to release any stuck buttons using ydotool (if available)
if [ -S /tmp/.ydotool_socket ] && command -v ydotool >/dev/null; then
    echo "Injecting button release events via ydotool..."
    YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool key 272:0 273:0 274:0 2>/dev/null || true  # BTN_LEFT, BTN_RIGHT, BTN_MIDDLE up
    sleep 0.5
else
    echo "ydotool not available or no socket; skipping injected releases."
fi

# Re-enable device
echo "Re-enabling device..."
qdbus org.kde.KWin /org/kde/KWin/InputDevice/event2 org.freedesktop.DBus.Properties.Set org.kde.KWin.InputDevice enabled true 2>/dev/null || true
sleep 0.3

# Restore desktop mode
echo "Restoring desktop mode..."
~/.local/bin/mouse-game-mode desktop 2>/dev/null || true

# Also force via kwriteconfig
kwriteconfig6 --file kcminputrc --group Mouse --key EmulateMiddleButton true 2>/dev/null || true
kwriteconfig6 --file kcminputrc --group Mouse --key MiddleButtonScroll true 2>/dev/null || true

echo "Done."
echo "Test normal left/right clicks now."
echo "If still bad, unplug/replug the mouse USB."
