#!/bin/sh
# The agentcairn plugin's SessionEnd/PreCompact hook starts an uncapped
# `cairn sweep` straight from the session (21G on monolith, 2026-10-06) and has
# no off switch. Point every copy at the memory-capped cairn-sweep.service
# instead. Runs on every apply because plugin updates and Claude Desktop's
# plugin sync rewrite the script; already-patched copies are skipped.
set -eu
find "$HOME/.claude/plugins" -path '*agentcairn*' -name session-end.sh \
    -exec grep -l 'nohup \$CAIRN sweep' {} + 2>/dev/null |
while IFS= read -r f; do
    sed -i 's|^nohup \$CAIRN sweep .*|systemctl --user start --no-block cairn-sweep.service >/dev/null 2>\&1 \|\| true  # dotfiles: capped sweep|' "$f"
done
systemctl --user daemon-reload 2>/dev/null || true
exit 0
