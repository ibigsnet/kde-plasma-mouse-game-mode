# Star Citizen Integration Notes

The mouse fix is integrated in launch scripts like this:

```bash
source "${HOME}/.local/lib/mouse-game-mode.sh"
mgm_stop_all_watchers
mgm_set_desktop_mode          # for RSI Launcher
mgm_start_game_watcher 'StarCitizen\.exe'   # only real game gets game mode
# ... launch ...
```

- Process watcher keeps game mode while `StarCitizen.exe` is alive (even if alt-tabbed).
- For pure alt-tab behavior (scrolling returns when you tab out), prefer `mouse-game-mode focus` instead of (or in addition to) the process watcher.

See the focus watcher for window title + cmdline matching. In HDR/gamescope the visible window is often a bridge — the cmdline check on the window pid + patterns helps.
