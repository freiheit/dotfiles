#!/bin/sh
# LifeOS is the harness ~/.claude/settings.json and CLAUDE.md assume (hooks,
# skills, agents, LIFEOS/ runtime). It ships as a skill payload: this drops it
# under ~/.claude/skills/LifeOS; `/LifeOS setup` inside claude does the rest,
# interactively. Plugins need no step here: Claude Code installs everything in
# settings.json enabledPlugins/extraKnownMarketplaces at startup.
set -eu
[ -e "$HOME/.claude/LIFEOS/VERSION" ] && exit 0
command -v bun >/dev/null 2>&1 || { echo "lifeos-bootstrap: bun missing; brew install oven-sh/bun/bun, then chezmoi apply" >&2; exit 0; }
curl -fsSL https://ourlifeos.ai/install.sh | bash
echo "lifeos-bootstrap: LifeOS skill dropped; run /LifeOS setup inside claude" >&2
