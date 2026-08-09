if which fzf &> /dev/null; then
  # Under ble.sh, fzf's own readline bindings don't apply -- load fzf through
  # ble.sh's integration modules instead. -d defers them until after attach.
  if [[ ${BLE_VERSION-} ]]; then
    ble-import -d integration/fzf-completion
    ble-import -d integration/fzf-key-bindings
  else
    eval "$(fzf --bash)"
  fi
  export FZF_DEFAULT_OPTS=$'--color=fg:#ebdbb2,bg:#282828,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836
    --color=hl+:#fabd2f,info:#83a598,prompt:#fe8019,pointer:#fb4934
    --color=marker:#b8bb26,spinner:#fb4934,header:#928374,border:#665c54
    --color=gutter:#282828'
fi
