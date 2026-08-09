# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Repo **is** [chezmoi](https://www.chezmoi.io/) source dir — not app. No build, no tests, no linter. Edit here change nothing until `chezmoi apply` copy to target.

Source filenames encode target paths and attributes: `dot_bashrc` → `~/.bashrc`, `private_dot_ssh/private_config` → `~/.ssh/config` (mode 0600), `bin/executable_update-all` → `~/bin/update-all` (mode +x).

## Commands

```bash
chezmoi diff            # preview what apply would change — run this before apply, always
chezmoi apply           # write source state to ~
chezmoi re-add          # pull edits made directly in ~ back into the source
chezmoi managed         # list every path chezmoi deploys
bin/chezmoi-update      # full fan-out: re-add, update, push, then ssh to every other account
bin/update-all          # OS/package updates (topgrade, distrobox, etckeeper) — unrelated to dotfiles
```

`.chezmoi.toml.tmpl` set `autoCommit` and `autoPush`. chezmoi own operations commit and push themselves; edits you make with normal file tools do not. Check `git status` after any chezmoi command — may already be committed.

## Two traps specific to this layout

**Non-dot files at the source root deploy to `~`.** `renovate.json` managed as `~/renovate.json`. Same for anything else dropped at root without leading dot. `AGENTS.md` in `.chezmoiignore` for this reason. Before adding root-level file, decide dotfile or repo metadata; ignore if metadata.

**Dot-prefixed source entries are invisible to chezmoi.** `.cursor/`, `.github/`, `.claude/`, `.clinerules/`, `.opencode/`, `.windsurf/` are repo metadata, never deploy. Confirm with `chezmoi managed | grep -v '^\.'`.

**Deleting from the source does not delete from targets.** Removing `foo` from source only stops managing `~/foo`. To remove everywhere, add *target* path to `.chezmoiremove` — established pattern here (see Catppuccin theme and neofetch entries).

## Multi-host, without templating

`bin/chezmoi-update` push same tree to five accounts across three machines: this Bazzite desktop (`bazzite-dx-nvidia`, Fedora 44 derivative), local root via `sudo -E chezmoi update`, and root+user on two headless servers (`media1.ogazenh.art`, `freiheit-bots-el10.freiheit.wtf`).

Also used automatically in distrobox containers, currently mix of Ubuntu and Fedora variants.

**No** OS or hostname templating anywhere — `.chezmoi.toml.tmpl` has no template actions, no `.tmpl` file branches on host. Divergence handled entirely by runtime guards inside shell files:

```bash
if which fzf &>/dev/null; then ...
if [ -e ~/.local/share/liquidprompt/liquidprompt ]; then ...
if [[ -S $OP_AUTH_SOCK && -r $OP_AUTH_SOCK ]]; then ...
```

Keep it that way. Config applies to some hosts only → guard at runtime, no templates. Corollary: "tool not installed, delete its config" usually wrong — may be installed on host you cannot see.

## Bash startup chain

`~/.bash_profile` → `~/.bashrc` → loop sourcing `~/.bashrc.d/*` **in glob (alphabetical) order** → then, still inside `.bashrc`: linuxbrew shellenv, `EDITOR`/`VISUAL`, 1Password `SSH_AUTH_SOCK` block → finally `/usr/share/bazzite-cli/bling.sh`.

Two consequences that bite:

- **Filenames in `dot_bashrc.d/` are load order.** `blesh.sh` must sort before `fzf.sh`, because `fzf.sh` branches on `${BLE_VERSION-}` being set.
- **`bling.sh` is a system file that runs *after* the whole `.bashrc.d` loop**, and re-runs `atuin init bash`, `zoxide init bash`, sources `bash-prexec` unconditionally. Anything in `.bashrc.d/` that binds keys can be overridden by it, and you cannot edit it from this repo.

ble.sh sourced from `dot_bashrc.d/blesh.sh` at default `--attach=prompt`, so takes over line editor at first prompt — after everything above, including `bling.sh`, finished.

## Externals

`.chezmoiexternal.toml` pulls three things with automatic refresh: liquidprompt and personal `liquidprompt-powerline` fork (both `git-repo`), and ble.sh (`archive`, upstream prebuilt nightly tarball — git repo ships no built `ble.sh`).

Because externals, they exist on **every** host that applies. Treat "is liquidprompt installed" as always true; fallback branch guarding absence is dead code.

## Bash and fish diverge deliberately

Bash uses liquidprompt + ble.sh + fzf. Fish uses starship + atuin (`dot_config/private_fish/config.fish`). `dot_config/starship.toml` and `bin/executable_tailscale-status.sh` live for fish only — do not delete because bash no longer calls starship.

## How to work in this repo

Run all work through **ponytail** (`/ponytail`). Take the laziest solution that actually works: reuse what is already here, prefer the platform or stdlib over new code, prefer deletion over addition, and do not add abstractions, dependencies, or config that nothing asks for. Never lazy about understanding the problem first, and never simplify away anything that prevents data loss.

Run `/ponytail-review` over the diff before committing anything non-trivial. This repo is configuration, so the usual outcome is that the diff gets shorter — most files here are captured upstream templates whose commented-out default sections carry no information and actively trip the secret scanners.

## Commits

- **Conventional Commits.** `type: subject`, lowercase after the type, imperative mood, no trailing period.
- **Single line.** Add a body only when the change is genuinely incomprehensible without one — not to restate the diff, and not to argue for a decision. Rationale belongs in a code comment if a future reader needs it, and nowhere if they do not.
- **Generate the message with `/caveman-commit`.** It produces the terse single-line form this repo wants.
- **No `Co-Authored-By:` trailers**, on any commit, from any tool.

chezmoi writes its own commit messages when `autoCommit` fires — `Add …`, `Update …`, `Remove …`, `Change attributes of …`. Those are machine-generated and exempt: leave them exactly as chezmoi produced them. The rules above apply only to hand-authored commits.

## Communication style in this repo

`.cursor/rules/caveman.mdc`, `.github/copilot-instructions.md`, and `AGENTS.md` all carry same rule: reply tersely, drop articles/filler/pleasantries/hedging, keep all technical substance and exact technical terms, code blocks unchanged. Drop terseness for security warnings, irreversible-action confirmations, and when user confused; resume after. Persisted prose — PRs, docs, code comments, this file — written normally; commits are the exception and follow the terse rules above.