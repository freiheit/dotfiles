if [ -e ~/.local/share/liquidprompt/liquidprompt ]; then

    source ~/.local/share/liquidprompt/liquidprompt

    if [ -e ~/.local/share/liquidprompt-powerline/powerline.theme ]; then
        source ~/.local/share/liquidprompt-powerline/powerline.theme

        lp_theme powerline_full
    fi

elif which starship &>/dev/null; then

    function set_win_title() {
        echo -ne "\033]0; $(basename "$PWD") $USER@$HOSTNAME\007"
    }

    starship_precmd_user_func="set_win_title"

    eval -- "$(starship init bash --print-full-init)"
    eval "$(starship completions bash)"

fi
