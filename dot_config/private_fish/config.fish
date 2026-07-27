set --local OP_AUTH_SOCK "$HOME/.1password/agent.sock"
if test -S $OP_AUTH_SOCK -a -r $OP_AUTH_SOCK -a -w $OP_AUTH_SOCK
    set --global --export SSH_AUTH_SOCK "$OP_AUTH_SOCK"
end

if status is-interactive
    # INTERACTIVE

    # If no SSH-AGENT, try keychain and then ssh-agent
    if test -z "$SSH_AUTH_SOCK" # no SSH-AGENT
        if type --query keychain
            keychain --eval --ignore-missing --quiet --quick --ssh-allow-forwarded id_ecdsa id_rsa id_ed25519 | source
        else
            ssh-agent | source
        end
    end

    
   command -q atuin && atuin init fish | source

else
    # NON-INTERACTIVE
    # If no SSH-AGENT, try keychain and then ssh-agent
    if test -z "$SSH_AUTH_SOCK" # no SSH-AGENT
        if type --query keychain
            keychain --eval --no-ask --ignore-missing --quiet --quick --ssh-allow-forwarded id_ecdsa id_rsa id_ed25519 | source
        else
            ssh-agent | source
        end
    end
    # Commands to run in interactive sessions can go here
end


# ~/.config/fish/themes/Gruvbox Dark.theme (chezmoi-managed)
fish_config theme choose "Gruvbox Dark"

starship init fish | source
