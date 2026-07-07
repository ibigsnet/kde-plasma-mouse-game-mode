# Contributing to KDE Plasma Mouse Game Mode

Thank you for your interest! This project is intentionally released under a **free and open source license** (MIT) so that anyone can study, modify, improve, and share the code.

We strongly encourage edits, forks, and customizations.

## Ways You Can Help

- **Improve game detection** — especially for HDR, gamescope, Wine, or other setups where window titles are weird (e.g. "Xwayland Video Bridge").
- **Add support for new mice** — the current code focuses on Corsair devices but can be generalized.
- **Better patterns** — contribute good regexes for popular games.
- **Documentation** — improve the README, add more examples, or write guides for specific games.
- **Bug fixes** — report or fix issues with focus detection, persistence, or launch wrappers.
- **New features** — e.g. better logging, GUI config tool, more robust Wayland support.

Even tiny changes are appreciated.

## Getting Started

1. Fork the repository.
2. Clone your fork:
   ```bash
   git clone https://github.com/YOURNAME/kde-plasma-mouse-game-mode.git
   cd kde-plasma-mouse-game-mode
   ```
3. Make your changes.
4. Test them:
   ```bash
   ./install.sh   # or just copy files manually
   mouse-game-mode list
   mouse-game-mode focus
   ```
5. Commit and push, then open a Pull Request.

## Code Style & Tips

- Keep things simple and well-commented. Many users will be editing these scripts.
- The main logic is in `lib/mouse-game-mode.sh`.
- The focus watcher (`bin/mouse-focus-watchdog.sh`) is where most tabbing-related improvements happen.
- Use `mouse-game-mode list` and the log files (`/tmp/mouse-*.log`) heavily when testing.
- For HDR/gamescope users, pay attention to what `wmctrl -l -p` and `xprop` actually report.

## Pull Requests

- Describe what problem your change solves (especially for tabbing or specific games).
- Include before/after behavior if possible.
- It's okay if your first PR is small!

## Questions?

Open an issue on GitHub. We're happy to discuss ideas for modifications.

This project exists because one person was annoyed by middle-mouse behavior in games. The best way to keep it useful is for many people to adapt it to their own needs.

Happy hacking!