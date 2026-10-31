#!/bin/sh
# deckdex moved from a weekly cron line to deckdex-sync.timer (systemd user, so
# it can relaunch Steam in the graphical session). Drop the old line, load the timer.
set -eu
crontab -l 2>/dev/null | grep -v 'deckdex sync' | crontab - || true
systemctl --user daemon-reload
systemctl --user start deckdex-sync.timer || true
