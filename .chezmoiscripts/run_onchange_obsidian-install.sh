#!/bin/sh
# Fallback installer. Puppet (profile::atomic) installs Obsidian system-wide on
# nodes whose Hiera lists it; this covers a workstation account Puppet has not.
set -eu
flatpak info md.obsidian.Obsidian >/dev/null 2>&1 && exit 0
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive flathub md.obsidian.Obsidian
