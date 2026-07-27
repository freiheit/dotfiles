#!/bin/bash
# Tailscale status glyph for prompt segments.
# Ported from dotfiles-root eric.eisenhart/bin/tailscale-status.sh

command -v tailscale >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

status=$(tailscale status --json 2>/dev/null \
    | jq -r 'if .BackendState == "Running" then if .Self.Online then "Online" else "Offline" end else .BackendState end')

case "$status" in
    Online)   icon="✅" ;;
    Offline)  icon="⛔️" ;;
    Stopped)  icon="🛑" ;;
    Starting) icon="🔄" ;;
    *)        icon="❓" ;;
esac

echo -n "$icon"
