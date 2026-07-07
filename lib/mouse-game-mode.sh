#!/usr/bin/env bash
#
# KDE Plasma Mouse Game Mode - Core Library
#
# This is free and open source software.
# Feel free to read, edit, improve, fork, and redistribute these scripts.
# Contributions and modifications are encouraged!
#
# Shared KDE Plasma mouse game-mode helpers.
# Toggles scrollOnButtonDown (hold middle button scrolls) and middleEmulation (L+R emulates middle click).
# Desktop mode: both enabled for normal scrolling (L+R and hold-middle).
# Game mode: both disabled (prevents unwanted scroll/middle emulation in games).
#
# Supports two watcher styles:
#   - Focus-based (mouse-focus-watchdog): switches on window focus. Perfect for alt-tabbing in/out.
#   - Process-based (mgm_start_game_watcher): tied to exe lifetime. Good for launch/close.
# Works on Wayland with KWin. Tested primarily with Corsair mice but extensible.
# Ideal for games like Star Citizen, FFXIV, etc. — disable emulation/scroll while in game.

MGM_QDBUS="${MGM_QDBUS:-$(command -v qdbus6 2>/dev/null || command -v qdbus)}"
MGM_LOGFILE="${MGM_LOGFILE:-/tmp/mouse-game-mode.log}"
MGM_WATCHER_PID=""

mgm_log() {
    echo "[$(date '+%H:%M:%S')] $*" >> "$MGM_LOGFILE"
}

mgm_list_kwin_devices() {
    "$MGM_QDBUS" org.kde.KWin 2>/dev/null | grep '^/org/kde/KWin/InputDevice/event' || true
}

mgm_device_prop() {
    local dev="$1" prop="$2"
    "$MGM_QDBUS" org.kde.KWin "$dev" org.freedesktop.DBus.Properties.Get \
        org.kde.KWin.InputDevice "$prop" 2>/dev/null
}

mgm_device_set() {
    local dev="$1" prop="$2" value="$3"
    local attempt actual

    for attempt in 1 2 3; do
        "$MGM_QDBUS" org.kde.KWin "$dev" org.freedesktop.DBus.Properties.Set \
            org.kde.KWin.InputDevice "$prop" "$value" 2>/dev/null || true
        actual=$(mgm_device_prop "$dev" "$prop")
        if [ "$actual" = "$value" ]; then
            return 0
        fi
        sleep 0.1
    done

    mgm_log "WARN: $dev $prop wanted=$value got=$actual"
    return 1
}

# True when this KWin node looks like a primary gaming mouse (tuned for Corsair).
# Edit this function or mgm_discover_corsair_mice to support other mice/vendors.
mgm_is_corsair_mouse_name() {
    local name="$1"
    echo "$name" | grep -qi 'corsair' || return 1
    echo "$name" | grep -qiE 'keyboard|consumer control|system control' && return 1
    echo "$name" | grep -qi 'mouse'
}

mgm_discover_corsair_mice() {
    local dev name pointer
    for dev in $(mgm_list_kwin_devices); do
        name=$(mgm_device_prop "$dev" name)
        pointer=$(mgm_device_prop "$dev" pointer)
        if [ "$pointer" = "true" ] && mgm_is_corsair_mouse_name "$name"; then
            echo "$dev"
        fi
    done
}

mgm_describe_devices() {
    local dev name middle scroll
    for dev in $(mgm_discover_corsair_mice); do
        name=$(mgm_device_prop "$dev" name)
        middle=$(mgm_device_prop "$dev" middleEmulation)
        scroll=$(mgm_device_prop "$dev" scrollOnButtonDown)
        echo "$dev | $name | middleEmulation=$middle | scrollOnButtonDown=$scroll"
    done
}

mgm_set_middle_emulation() {
    local enabled="$1"
    local label=$([ "$enabled" = true ] && echo "MIDDLE EMU ON" || echo "MIDDLE EMU OFF")
    local dev name count=0

    for dev in $(mgm_discover_corsair_mice); do
        name=$(mgm_device_prop "$dev" name)
        mgm_device_set "$dev" middleEmulation "$enabled"
        mgm_log "$label: $dev ($name)"
        count=$((count + 1))
    done

    [ "$count" -gt 0 ]
}

mgm_apply_scroll_mode() {
    local scroll="$1" label="$2"
    local dev name count=0

    for dev in $(mgm_discover_corsair_mice); do
        name=$(mgm_device_prop "$dev" name)
        mgm_device_set "$dev" scrollOnButtonDown "$scroll"
        mgm_log "$label: $dev ($name) → scrollOnButtonDown=$scroll"
        count=$((count + 1))
    done

    if [ "$count" -eq 0 ]; then
        mgm_log "$label: WARNING — no Corsair mice found"
        return 1
    fi
    return 0
}

mgm_set_desktop_mode() {
    mgm_set_global_middle_button_scroll true
    mgm_set_global_emulate_middle_button true
    mgm_persist_libinput_middle_emulation true
    mgm_set_middle_emulation true
    mgm_apply_scroll_mode true "DESKTOP"
}

mgm_set_game_mode() {
    mgm_set_global_middle_button_scroll false
    mgm_set_global_emulate_middle_button false
    mgm_persist_libinput_middle_emulation false
    mgm_set_middle_emulation false
    mgm_apply_scroll_mode false "GAME"
}

mgm_set_global_middle_button_scroll() {
    local enabled="$1"
    kwriteconfig6 --file kcminputrc --group Mouse --key MiddleButtonScroll "$enabled" 2>/dev/null || true
    mgm_log "GLOBAL: MiddleButtonScroll=$enabled"
}

mgm_set_global_emulate_middle_button() {
    local enabled="$1"
    kwriteconfig6 --file kcminputrc --group Mouse --key EmulateMiddleButton "$enabled" 2>/dev/null || true
    mgm_log "GLOBAL: EmulateMiddleButton=$enabled"
}

# Persist MiddleButtonEmulation in libinput sections for Corsair devices (for login persistence)
mgm_persist_libinput_middle_emulation() {
    local enabled="$1"
    local val=$([ "$enabled" = true ] && echo true || echo false)
    # Update all Corsair Mouse sections (case insensitive-ish for name)
    sed -i '/\[Libinput\]\[[0-9]*\]\[[0-9]*\]\[.*[Cc]orsair.*[Mm]ouse\]/,/^\[/ s/MiddleButtonEmulation=[^ ]*/MiddleButtonEmulation='"$val"'/' ~/.config/kcminputrc 2>/dev/null || true
}

# Emergency: safe click state for desktop use right now.
mgm_reset_safe() {
    mgm_log "RESET SAFE"
    mgm_set_global_middle_button_scroll true
    mgm_set_global_emulate_middle_button true
    mgm_persist_libinput_middle_emulation true
    mgm_set_middle_emulation true
    for dev in $(mgm_discover_corsair_mice); do
        name=$(mgm_device_prop "$dev" name)
        mgm_device_set "$dev" scrollOnButtonDown true
        mgm_log "SAFE: $dev ($name) → scrollOnButtonDown=true"
    done
}

# If nothing matching $1 is running, force desktop-safe settings first.
mgm_ensure_desktop_if_idle() {
    local pattern="$1"
    if ! pgrep -f -i "$pattern" >/dev/null 2>&1; then
        mgm_set_desktop_mode
    fi
}

mgm_install_restore_trap() {
    trap 'mgm_stop_watcher; if ! pgrep -f -i "StarCitizen\.exe" >/dev/null 2>&1; then mgm_set_desktop_mode; fi; mgm_log "RESTORE trap fired"' EXIT INT TERM
}

mgm_stop_watcher() {
    if [ -n "$MGM_WATCHER_PID" ]; then
        kill "$MGM_WATCHER_PID" 2>/dev/null || true
        wait "$MGM_WATCHER_PID" 2>/dev/null || true
        MGM_WATCHER_PID=""
    fi
}

mgm_stop_all_watchers() {
    # Kill any background watcher loops (they are subshells doing while+pgrep+sleep)
    pkill -f 'while true; do.*pgrep -f -i' 2>/dev/null || true
    # Kill watchers only; be specific so we do not accidentally kill the actual StarCitizen.exe
    # or the anti-AFK service/inhibitor. Match watcher code patterns.
    pkill -f 'mgm_start_game_watcher|start_game_watcher' 2>/dev/null || true
    pkill -f 'mouse-focus-watchdog' 2>/dev/null || true
    mgm_stop_watcher
    # Clean any pid files if we add them later
    rm -f /tmp/mgm-*-watcher.pid 2>/dev/null || true
    mgm_log "All watchers stopped"
}

# Background watcher: game mode only while $1 process pattern is active.
# Waits a few seconds after the process vanishes before restoring desktop settings,
# so brief Wine/launcher respawns do not flip middle-click emulation mid-session.
mgm_start_game_watcher() {
    local pattern="$1"
    local off_debounce="${MGM_OFF_DEBOUNCE:-3}"

    mgm_stop_all_watchers  # prevent multiple conflicting watchers (e.g. from previous SC launch)

    (
        local fix_active=false
        local absent_seconds=0
        while true; do
            # Stricter match: confirm the actual exe appears in cmdline (reduces false positives from paths/wine helpers)
            # For SC, also ensure it's not the launcher process
            if pgrep -f -i "$pattern" >/dev/null 2>&1 && \
               pgrep -f -i "$pattern" | head -1 | xargs -r -I{} sh -c '
                 cmd=$(tr "\0" " " < /proc/{}/cmdline 2>/dev/null);
                 echo "$cmd" | grep -qi "'"$pattern"'" && ! echo "$cmd" | grep -qi "RSI Launcher"
               '; then
                absent_seconds=0
                if [ "$fix_active" = false ]; then
                    mgm_set_game_mode
                    fix_active=true
                    mgm_log "WATCHER: $pattern detected — game mode ON"
                fi
            elif [ "$fix_active" = true ]; then
                absent_seconds=$((absent_seconds + 1))
                if [ "$absent_seconds" -ge "$off_debounce" ]; then
                    mgm_set_desktop_mode
                    fix_active=false
                    absent_seconds=0
                    mgm_log "WATCHER: $pattern gone (${off_debounce}s) — desktop mode ON"
                fi
            fi
            sleep 1
        done
    ) &

    MGM_WATCHER_PID=$!
    mgm_log "WATCHER started (pid=$MGM_WATCHER_PID, pattern=$pattern, off_debounce=${off_debounce}s)"
}

# Disable game-breaking mouse features, run command, restore on exit.
mgm_run_with_game_mode() {
    mgm_stop_all_watchers  # launching a wrapped game (e.g. FFXIV) takes precedence; stop any SC watcher
    mgm_ensure_desktop_if_idle '(StarCitizen|game|proton|wine)'
    mgm_install_restore_trap
    mgm_set_game_mode
    mgm_log "RUN WITH GAME MODE: $*"
    "$@"
    local exit_code=$?
    # Explicit restore after the game command returns (normal close path).
    # This ensures undo happens reliably even if EXIT trap is affected by Steam's
    # launch/reaper wrappers. Trap remains as fallback for signals/abnormal exit.
    if ! pgrep -f -i "StarCitizen\.exe" >/dev/null 2>&1; then
        mgm_set_desktop_mode
        mgm_log "RESTORE after run (desktop mode)"
    else
        mgm_log "Not restoring desktop (StarCitizen still detected)"
    fi
    mgm_stop_watcher || true
    return $exit_code
}