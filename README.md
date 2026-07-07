# KDE Plasma Mouse Game Mode

**Free & Open Source Software**

This project uses the MIT license. You are encouraged to read the code, modify it for your needs, fork it, and contribute improvements.

Automatically disable middle mouse button emulation and "hold middle to scroll" when playing games on KDE Plasma (Wayland), and re-enable it for normal desktop use.

This prevents games from receiving unwanted middle clicks or scroll events from L+R or middle-hold, while keeping the convenient behavior on the desktop.

## What it does

**Desktop mode (normal use):**
- Left + Right click together emulates middle mouse button (`middleEmulation`).
- Holding the middle mouse button + moving the mouse scrolls (`scrollOnButtonDown`).
- Globals `EmulateMiddleButton=true` and `MiddleButtonScroll=true`.

**Game mode:**
- Both features disabled.
- Games see raw left/right clicks and a normal middle button (no emulation, no scroll-on-hold).

Switching can be:
- Manual via `mouse-game-mode desktop` / `game`
- Automatic via **focus watcher** (recommended for alt-tabbing in/out of games)
- Automatic via **process watcher** (tied to game exe running, best for launch/close)

## Features

- Works on KDE Plasma Wayland + KWin (qdbus control + kcminputrc persistence).
- Focus watcher: switches based on active window title + process cmdline. Ideal for alt-tabbing: leave the game → scrolling restored; tab back in → disabled.
- Process watcher: for launchers (e.g. only real `StarCitizen.exe`, not RSI Launcher). Stays in game mode while exe runs, even if alt-tabbed out.
- Per-device + global settings persisted.
- Easy wrappers for Steam launch options.
- Emergency reset script.
- Supports HDR/gamescope setups (with some caveats on window detection).

## Requirements

- KDE Plasma (KWin, qdbus/qdbus6, kwriteconfig6)
- `wmctrl`, `xprop` (for focus watcher)
- `xdotool` (optional, for some fallbacks)
- `ydotool` + running `ydotoold` (optional, for Wayland input in some gamescope cases)
- Bash

Tested primarily with Corsair mice (M65 series) but the mechanism is general.

## Installation

```bash
git clone https://github.com/YOURNAME/kde-plasma-mouse-game-mode.git
cd kde-plasma-mouse-game-mode
./install.sh
```

The install script copies everything to `~/.local/bin`, `~/.local/lib`, and drops config templates.

Re-login or run `source ~/.bashrc` (or equivalent) if needed. Then:

```bash
mouse-game-mode list
mouse-game-mode desktop
```

To start the focus watcher (recommended for tabbing in/out of games):

```bash
mouse-game-mode focus
```

### Autostart desktop mode

An autostart `.desktop` is provided (runs after delay on login to force safe desktop settings).



## Usage

```bash
mouse-game-mode list                 # current state
mouse-game-mode desktop              # enable scrolling/emulation
mouse-game-mode game                 # disable for gaming
mouse-game-mode focus                # start focus watcher (best for alt-tabbing in/out)
mouse-game-mode stop                 # kill watchers + force desktop
mouse-game-mode watch 'SomeGame.exe' # simple process watcher (advanced)
```

### Steam integration

In game Properties → Launch Options:

```
~/.local/bin/mouse-game-fix.sh %command%
```

Or the NVIDIA/gamescope variants.

The wrapper calls `mgm_run_with_game_mode ...` which sets game mode, runs your command, and restores on exit.

## Automatic switching

### Focus watcher — Recommended for tabbing in and out of games

The focus watcher is designed specifically for the "tabbing in/out" use case (rather than full launch/close).

**Steps to set up tab-in / tab-out behavior:**

1. Make sure the project is installed (`./install.sh`).
2. Edit your game patterns:
   ```bash
   nano ~/.config/mouse-focus-games.txt
   ```
   Add titles/cmdlines for your games (one per line, regex supported):
   ```
   Star Citizen
   StarCitizen
   FINAL FANTASY XIV
   ffxiv_dx11
   ```
3. Start the focus watcher (run this in a terminal or background it):
   ```bash
   mouse-game-mode focus
   ```
   - It stops any conflicting process watchers.
   - On start it checks current focus and sets the correct mode.
   - While running: 
     - Game window focused (or top of stack) → **GAME mode** (L+R and hold-middle scroll **disabled**).
     - Alt-tab / switch to desktop, browser, Discord, etc. → **DESKTOP mode** (scrolling **enabled**).
   - Logs go to `/tmp/mouse-focus-watchdog.log`. Watch them:
     ```bash
     tail -f /tmp/mouse-focus-watchdog.log
     ```
4. Verify while tabbing:
   ```bash
   mouse-game-mode list
   ```
   Tab in/out of the game and watch the output change.

5. To run persistently:
   - Run in a terminal you keep open.
   - Or start from a script and background it: `mouse-game-mode focus & disown`
   - Or create your own autostart `.desktop` that launches it (similar to the provided desktop-mode one).
   - On exit (Ctrl-C or logout) it automatically forces desktop mode.

**How it works internally:**
- Polls KWin's `_NET_CLIENT_LIST_STACKING` + `_NET_ACTIVE_WINDOW`.
- Gets the window's title + process cmdline.
- Matches against your patterns.
- Only changes mode when focus state actually changes (debounced).

**HDR / Gamescope / Wine caveats:**
The "game" window is often a proxy ("Wayland to X Recording bridge", "Xwayland Video Bridge", etc.). The script uses both title *and* cmdline of the reported pid, plus numeric ID matching. If detection is flaky:
- Add bridge-related patterns temporarily.
- Or run `wmctrl -l -p` and `xprop -root _NET_ACTIVE_WINDOW` while in-game to see what titles/pids are reported.
- Improve `is_game_focused()` in `bin/mouse-focus-watchdog.sh` if needed (it already handles some stacking edge cases).

### Process watchers — Better for launch/close

Used when you want mode tied to the game *process* being alive (not just focused).

Example from launch scripts:
```bash
source "${HOME}/.local/lib/mouse-game-mode.sh"
mgm_set_desktop_mode                    # launcher phase
mgm_start_game_watcher 'StarCitizen\.exe'  # actual game
# ... launch command ...
```

- While the matching exe runs → game mode (even if you alt-tab out).
- When exe disappears for a few seconds (debounce) → desktop mode.
- Good for launchers that stay running after the game starts, or when you want strict "game is running" logic.
- Launch via `mouse-game-mode watch 'pattern'` for testing.

**When to choose which?**
- Frequent alt-tabbing (desktop + game): Use **focus watcher**.
- Mostly launch game, play full session, then close: Process watcher or launch wrappers are fine.
- Both: You can start the focus watcher after launching (it will stop process watchers).

The CLI help and examples show both approaches.

## Configuration

Edit `~/.config/mouse-focus-games.txt` (one pattern per line):

```
FINAL FANTASY XIV
ffxiv_dx11
Star Citizen
StarCitizen
MyFavoriteGame
```

The focus watcher and some launchers use this.

## Examples

See the `examples/` directory and the original launch scripts for:

- XIVLauncher wrapper
- Star Citizen launchers with gamescope/HDR + mouse fix
- NVIDIA offload wrappers

### Basic custom launcher snippet

```bash
#!/usr/bin/env bash
source "${HOME}/.local/lib/mouse-game-mode.sh"
mgm_run_with_game_mode your-game-command "$@"
```

Or for launchers that stay running:

```bash
mgm_set_game_mode
your-launcher
# (restore manually or use watcher)
```

## Troubleshooting

- After reboot or manual changes in System Settings, run `mouse-game-mode desktop`.
- `mouse-game-mode list` shows live KWin state vs what kcminputrc has.
- In HDR/gamescope the window titles/pids can be weird (bridge). Use `wmctrl -l`, `xprop`, and logs.
- Focus watcher not detecting your game when tabbing? Add patterns (including bridge names for HDR), check with `wmctrl -l -p` while focused, or look at `/tmp/mouse-focus-watchdog.log`. You can also run `mouse-game-mode game` manually right after tabbing in.
- Clicks broken? `mouse-emergency-reset.sh` or `mouse-game-mode desktop`.
- Multiple mice? The scripts target discovered pointer devices (currently Corsair-filtered in discovery; easy to generalize).
- Logs: `/tmp/mouse-game-mode.log`, `/tmp/mouse-focus-watchdog.log`

## Expected Behavior

- Normal desktop or alt-tabbed out of a game (focus watcher running): L+R middle emulation + hold-middle scroll are **enabled**.
- Game window focused (focus watcher running): both features **disabled** — games get clean input.
- With process watcher / launch wrappers: mode follows the exe lifetime (game mode while running, regardless of focus).
- After reboot or manual System Settings changes: run `mouse-game-mode desktop` to reset.

## Contributing & Modifications

This project is **free and open source**. We actively encourage you to:

- Fork the repository
- Edit, improve, and customize the scripts for your setup
- Add support for new games, mice, or desktop environments
- Fix bugs or improve HDR/gamescope/Wine detection
- Share your changes via pull requests

The core logic lives in `lib/mouse-game-mode.sh`. The discovery function, set routines, watchers, and focus logic are all designed to be easy to understand and modify.

### How to contribute
1. Fork the repo on GitHub.
2. Make your changes (most people start by tweaking patterns or the `is_game_focused` function).
3. Test with `mouse-game-mode list` and the focus watcher.
4. Open a Pull Request.

Even small improvements (better comments, new game patterns, clearer docs) are welcome.

See `CONTRIBUTING.md` for more details.

No contribution is too small — this project exists to help the community avoid middle-mouse annoyances in games.

## Credits

Extracted and cleaned from a working personal setup for Star Citizen + FFXIV on Nobara/KDE Plasma (Wayland + HDR + high-end NVIDIA).

## License

This project is licensed under the **MIT License** (a permissive free and open source license).

You are free to:
- Use the software for any purpose
- Modify the source code
- Distribute copies (modified or not)
- Use it in proprietary projects

See the [LICENSE](LICENSE) file for the full text.

We chose a free and open license specifically so that people can easily edit, adapt, and improve the tools for their own games and setups.

Contributions and modifications are very welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
