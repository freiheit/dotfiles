[![pre-commit checks](https://github.com/freiheit/dotfiles/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/freiheit/dotfiles/actions/workflows/pre-commit.yml)
[![gitleaks secret scan](https://github.com/freiheit/dotfiles/actions/workflows/gitleaks.yml/badge.svg)](https://github.com/freiheit/dotfiles/actions/workflows/gitleaks.yml)
[![trufflehog secrets scan](https://github.com/freiheit/dotfiles/actions/workflows/trufflehog.yml/badge.svg)](https://github.com/freiheit/dotfiles/actions/workflows/trufflehog.yml)

# freiheit dotfiles

This is a [chezmoi](https://www.chezmoi.io/) dotfiles repo of configs I use
on my main personal workstation and on a couple personal servers.

## What's here

- **Shell**: `dot_bashrc` (.bashrc), `dot_bash_profile`, and `dot_bashrc.d/` (ble.sh,
  cdpath, fzf, prompt), plus fish in `dot_config/private_fish/`. 
  - Bash uses liquidprompt; fish uses starship.
- **Tools**: `dot_config/` has gh (github), fragment of 1Password,
  tealdeer, liquidprint, and starship configs.
- **Terminal**: `dot_config/` holds ghostty
- **Git**: `dot_config/git`, `dot_gitconfig` and `dot_gittemplate/`.
- **SSH**: `private_dot_ssh/`.
- **Scripts**: `bin/` deploys to `~/bin`, has a few tools.
- **chezmoi config**: `.chezmoi.toml.tmpl`, `.chezmoiignore`, `.chezmoiremove`, and
  `.chezmoiexternal.toml` (pulls liquidprompt and ble.sh on apply).

Source filenames encode the target path and mode: `dot_bashrc` becomes `~/.bashrc`,
`private_dot_ssh/` becomes `~/.ssh/` at mode 0600, `bin/executable_update-all`
becomes `~/bin/update-all` with the execute bit set.

There is no OS or hostname templating — differences between hosts are handled by
runtime guards inside the shell files themselves.

## Usage

Copy bits you like to your own dotfiles repo, or clone this one.

```bash
chezmoi diff     # preview changes
chezmoi apply    # write them to ~
chezmoi managed  # list every deployed path
```
