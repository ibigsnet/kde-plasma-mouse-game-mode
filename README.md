# KDE Plasma Mouse Game Mode

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
- Automatic via focus watcher (recommended for alt-tabbing)
- Automatic via process watcher (tied to specific game exe, used in launchers)

## Features

- Works on KDE Plasma Wayland + KWin (qdbus control + kcminputrc persistence).
- Focus watcher: switches based on active window title + process cmdline. Alt-tab out of game → desktop scrolling restored.
- Process watcher: for launchers (e.g. only real `StarCitizen.exe`, not RSI Launcher).
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

To start the focus watcher (for alt-tab behavior):

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
mouse-game-mode focus                # start focus auto-switcher (Ctrl-C to stop)
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

### Focus watcher (best for alt-tab)

`mouse-game-mode focus`

- Detects the focused window using KWin stacking + wmctrl + process cmdline.
- Matches patterns in `~/.config/mouse-focus-games.txt` (case-insensitive regex on title + cmdline).
- Game focused → game mode.
- Alt-tab / switch away → desktop mode.

**Note for complex setups (HDR, gamescope, Wine):** The "visible" window may be a bridge/proxy (e.g. "Xwayland Video Bridge"). The focus script falls back to cmdline checks. You may need to add patterns or improve detection (see `is_game_focused` in the script).

### Process watchers in launchers

Used in custom game launch scripts (see examples). While the matching exe is running → game mode. Good for distinguishing launcher vs actual game.

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
- Focus watcher not detecting your game? Add to patterns or temporarily use `mouse-game-mode game` manually.
- Clicks broken? `mouse-emergency-reset.sh` or `mouse-game-mode desktop`.
- Multiple mice? The scripts target discovered pointer devices (currently Corsair-filtered in discovery; easy to generalize).
- Logs: `/tmp/mouse-game-mode.log`, `/tmp/mouse-focus-watchdog.log`

## Expected Behavior

- Normal desktop/apps: scrolling via L+R and hold-middle works.
- In supported games: no interference.
- Alt-tabbing with focus watcher active: scrolling comes back when you leave the game window.
- Launch via provided wrappers/launchers: correct mode for the phase of the game.

## Contributing / Customization

The core logic lives in `lib/mouse-game-mode.sh`. The discovery function, set routines, and watchers are all there.

Feel free to fork, improve focus detection for more games, add support for non-Corsair mice, etc.

## Credits

Extracted and cleaned from a working personal setup for Star Citizen + FFXIV on Nobara/KDE Plasma (Wayland + HDR + high-end NVIDIA).

## License

MIT
