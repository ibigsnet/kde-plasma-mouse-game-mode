#!/usr/bin/env bash
#
# This project uses a free and open source license.
# You are encouraged to read, modify, and improve these scripts.
#
# Installer for KDE Plasma Mouse Game Mode
# Run: ./install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${HOME}/.local"

echo "Installing KDE Plasma Mouse Game Mode..."

# Create dirs
mkdir -p "${PREFIX}/bin" "${PREFIX}/lib"
mkdir -p "${HOME}/.config/autostart"

# Install scripts
install -m 755 "${REPO_DIR}/bin/"* "${PREFIX}/bin/" 2>/dev/null || true
install -m 644 "${REPO_DIR}/lib/"*.sh "${PREFIX}/lib/" 2>/dev/null || true

# Configs (don't overwrite existing without backup)
if [[ -f "${HOME}/.config/mouse-focus-games.txt" ]]; then
    echo "mouse-focus-games.txt exists, skipping (merge manually if needed)"
else
    cp "${REPO_DIR}/config/mouse-focus-games.txt" "${HOME}/.config/"
fi

cp -n "${REPO_DIR}/config/autostart/mouse-desktop-mode.desktop" "${HOME}/.config/autostart/" || true

# Make sure focus script is executable
chmod +x "${PREFIX}/bin/mouse-focus-watchdog.sh" 2>/dev/null || true

echo ""
echo "Installation complete."
echo ""
echo "Next steps:"
echo "  1. source or re-login so PATH is fresh"
echo "  2. mouse-game-mode list"
echo "  3. mouse-game-mode desktop   # enable for normal use"
echo "  4. (optional) mouse-game-mode focus   # for auto alt-tab switching"
echo "  5. For Steam games, put e.g.  %command%  wrapper in launch options"
echo ""
echo "See README.md for full details, patterns, and game-specific integration."
