# ble.sh. Default --attach=prompt hands over the line editor at the first prompt,
# after all of .bashrc.
if [[ $- == *i* ]] && [ -e ~/.local/share/blesh/ble.sh ]; then
    source ~/.local/share/blesh/ble.sh
fi
