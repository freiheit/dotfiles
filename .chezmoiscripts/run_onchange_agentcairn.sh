#!/bin/sh
# agentcairn: Claude Code memory as Markdown notes in the Obsidian vault. The
# Claude Code plugin comes from settings.json enabledPlugins; this adds the CLI,
# the sweep cron (cairn owns its crontab line, marker "# agentcairn-sweep") and
# the Claude Desktop MCP entry. Vault path mirrors ~/.agentcairn/config.toml.
set -eu
vault="$HOME/Documents/freibrain"
uv tool list 2>/dev/null | grep -q '^agentcairn ' || uv tool install agentcairn
[ -d "$vault" ] || cairn init "$vault"
cairn schedule install --interval 2h --vault "$vault"
[ -d "$HOME/.config/Claude" ] && cairn install claude-desktop --vault "$vault"
exit 0
