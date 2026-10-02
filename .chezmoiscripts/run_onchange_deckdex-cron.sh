#!/bin/sh
# Weekly ProtonDB-tier sync of Steam collections. Full path because cronie gives
# user crontabs PATH=/usr/bin:/bin. The API key is read from
# ~/.config/deckdex/config.toml, so it stays off the command line.
set -eu
line='@weekly $HOME/.local/bin/deckdex sync --preset per-tier --native --kill-steam --yes'
{ crontab -l 2>/dev/null | grep -v 'deckdex sync' || true; echo "$line"; } | crontab -
