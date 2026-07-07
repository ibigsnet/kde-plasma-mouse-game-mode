#!/usr/bin/env bash
# mouse-focus-watchdog.sh
# Focus-based mouse mode switcher for KDE Plasma.
# Only "game mode" (scroll disabled) when a game window is focused.
# Desktop mode otherwise (scrolling/L+R emulation restored).
#
# Run via: mouse-game-mode focus
# Matches window title + cmdline against ~/.config/mouse-focus-games.txt
# Works with alt-tabbing. See README.

set -euo pipefail

LIB="${HOME}/.local/lib/mouse-game-mode.sh"
if [[ -f "$LIB" ]]; then
    source "$LIB"
else
    echo "ERROR: $LIB not found" >&2
    exit 1
fi

LOGFILE="${MGM_LOGFILE:-/tmp/mouse-focus-watchdog.log}"
MGM_LOGFILE="$LOGFILE"

log() {
    echo "[$(date '+%H:%M:%S')] $*" >> "$LOGFILE"
}

declare -a GAME_PATTERNS=()

load_patterns() {
    if [[ $# -gt 0 ]]; then
        GAME_PATTERNS=("$@")
        return
    fi

    local cfg="${HOME}/.config/mouse-focus-games.txt"
    if [[ -f "$cfg" ]]; then
        mapfile -t GAME_PATTERNS < <(grep -v '^\s*#' "$cfg" | grep -v '^\s*$' || true)
        if [[ ${#GAME_PATTERNS[@]} -gt 0 ]]; then
            return
        fi
    fi

    GAME_PATTERNS=(
        "FINAL FANTASY XIV"
        "ffxiv_dx11"
        "Star Citizen"
        "StarCitizen"
    )
}

is_game_focused() {
    local stacking
    stacking=$(xprop -root _NET_CLIENT_LIST_STACKING 2>/dev/null | awk -F'#' '{print $2}' | tr -d ' ')
    if [[ -z "$stacking" ]]; then
        return 1
    fi
    local top_id
    top_id=$(echo "$stacking" | tr ',' ' ' | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')

    local active_hex
    active_hex=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')

    local check_ids="$top_id $active_hex"

    for check_id in $check_ids; do
        [[ -z "$check_id" || "$check_id" == "0x0" ]] && continue

        local line=""
        while read -r w_id desk pid host title_rest; do
            if [[ "$(printf '%d' "$w_id" 2>/dev/null || echo 0)" == "$(printf '%d' "$check_id" 2>/dev/null || echo 1)" ]]; then
                line="$w_id $desk $pid $host $title_rest"
                break
            fi
        done < <(wmctrl -l -p 2>/dev/null)

        if [[ -z "$line" ]]; then
            continue
        fi

        local w_id desk pid host title
        read -r w_id desk pid host title <<< "$line"

        if [[ -z "$pid" || "$pid" == "0" ]]; then
            continue
        fi

        local cmdline=""
        if [[ -r "/proc/$pid/cmdline" ]]; then
            cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
        fi

        local full="$title $cmdline"

        for pat in "${GAME_PATTERNS[@]}"; do
            if echo "$full" | grep -qiE "$pat"; then
                return 0
            fi
        done
    done

    return 1
}

load_patterns "$@"

if [[ ${#GAME_PATTERNS[@]} -eq 0 ]]; then
    echo "No game patterns defined!" >&2
    exit 1
fi

log "=== Focus watchdog starting ==="
log "Patterns: ${GAME_PATTERNS[*]}"

if declare -f mgm_stop_all_watchers >/dev/null 2>&1; then
    mgm_stop_all_watchers || true
fi

last_mode=""

cleanup() {
    log "Exiting, forcing desktop mode..."
    mgm_set_desktop_mode || true
    exit 0
}
trap cleanup INT TERM EXIT

# Initial decision - function now defined above
if is_game_focused; then
    mgm_set_game_mode
    last_mode="game"
    log "Initial: game focused → GAME MODE"
else
    mgm_set_desktop_mode
    last_mode="desktop"
    log "Initial: not game focused → DESKTOP MODE"
fi

while true; do
    if is_game_focused; then
        if [[ "$last_mode" != "game" ]]; then
            mgm_set_game_mode
            log "Game window focused → GAME MODE (scrolls disabled)"
            last_mode="game"
        fi
    else
        if [[ "$last_mode" != "desktop" ]]; then
            mgm_set_desktop_mode
            log "No game focused (alt-tab / launcher / desktop) → DESKTOP MODE (scrolls enabled)"
            last_mode="desktop"
        fi
    fi
    sleep 0.7
done
