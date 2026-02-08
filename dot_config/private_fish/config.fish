if status is-interactive
    # Commands to run in interactive sessions can go here
end

# https://github.com/catppuccin/fish
fish_config theme choose "Catppuccin Mocha"

starship init fish | source
