if status is-interactive
    # Commands to run in interactive sessions can go here
end

set --local OP_AUTH_SOCK "$HOME/.1password/agent.sock"
if test -S $OP_AUTH_SOCK -a -r $OP_AUTH_SOCK -a -w $OP_AUTH_SOCK
    set --global --export SSH_AUTH_SOCK "$OP_AUTH_SOCK"
end

# https://github.com/catppuccin/fish
fish_config theme choose "Catppuccin Mocha"

starship init fish | source
