# Star Citizen Integration Notes

## Process watcher (tied to launch/close)

Typical in launch scripts:

```bash
source "${HOME}/.local/lib/mouse-game-mode.sh"
mgm_stop_all_watchers
mgm_set_desktop_mode                    # RSI Launcher phase only
mgm_start_game_watcher 'StarCitizen\.exe'  # real game exe
# ... launch the game ...
```

This keeps **game mode** (scrolling disabled) the entire time `StarCitizen.exe` is running — even if you alt-tab out to desktop.

## Focus watcher (recommended for tabbing in/out)

For the common case of alt-tabbing between the game and other apps:

```bash
mouse-game-mode focus
```

- Tab **into** Star Citizen → game mode (L+R and hold-middle scroll disabled).
- Alt-tab **out** to desktop/browser/etc. → desktop mode (scrolling enabled).
- Tab back in → game mode again.

The focus watcher will automatically stop any process watchers that are running.

**HDR/Gamescope tip:** The main visible window is often the Xwayland bridge. The focus script checks both window title *and* the associated process cmdline, so "StarCitizen" in the cmdline usually works. Add "bridge" or "xwayland" to your patterns file if needed.

See the main README for detailed tabbing setup steps, pattern configuration, and logging.
