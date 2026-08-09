# ble.sh (Bash Line Editor). Sourced with the default --attach=prompt, so ble.sh
# only takes over the line editor at the first prompt -- after the rest of
# .bashrc (linuxbrew, bling.sh, atuin, zoxide) has finished setting up.
if [[ $- == *i* ]] && [ -e ~/.local/share/blesh/ble.sh ]; then
    source ~/.local/share/blesh/ble.sh
fi
