#!/bin/sh
# agentcairn: Claude Code memory as Markdown notes in the Obsidian vault. The
# Claude Code plugin comes from settings.json enabledPlugins; this adds the CLI,
# and the Claude Desktop MCP entry. The sweep runs from cairn-sweep.timer
# (systemd user, memory-capped), not cairn's own cron line, which is removed. Vault path mirrors ~/.agentcairn/config.toml.
set -eu
vault="$HOME/Documents/freibrain"
uv tool list 2>/dev/null | grep -q '^agentcairn ' || uv tool install agentcairn
uv tool upgrade agentcairn || true
[ -d "$vault" ] || cairn init "$vault"
cairn schedule uninstall || true
[ -d "$HOME/.config/Claude" ] && cairn install claude-desktop --vault "$vault"
exit 0
