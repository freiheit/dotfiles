if [ -e ~/.local/share/liquidprompt/liquidprompt ]; then

    source ~/.local/share/liquidprompt/liquidprompt

    if [ -e ~/.local/share/liquidprompt-powerline/powerline.theme ]; then
        source ~/.local/share/liquidprompt-powerline/powerline.theme

        lp_theme powerline_full
    fi

fi
