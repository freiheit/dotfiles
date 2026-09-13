# 1Password agent wins when present. Re-assert after /etc/profile.d/keychain.sh
# (Fedora keychain RPM) stomps SSH_AUTH_SOCK in non-login shells via /etc/bashrc.
OP_AUTH_SOCK=$HOME/.1password/agent.sock
if [[ -S $OP_AUTH_SOCK && -r $OP_AUTH_SOCK && -w $OP_AUTH_SOCK ]]; then
   export SSH_AUTH_SOCK=$OP_AUTH_SOCK
fi
