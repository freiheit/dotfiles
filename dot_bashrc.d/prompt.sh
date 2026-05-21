function set_win_title() {
    echo -ne "\033]0; $(basename "$PWD") $USER@$HOSTNAME\007"
}

starship_precmd_user_func="set_win_title"

if which starship &>/dev/null; then
    eval -- "$(starship init bash --print-full-init)"
    eval "$(starship completions bash)"
fi
