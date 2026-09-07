# fzf owns history search. atuin is the fallback for when fzf isn't installed.
# if interactive...
if [ "${-#*i}" == "$-" ]; then
   if ! which fzf &>/dev/null && which atuin &>/dev/null; then
      eval "$(atuin init bash)"
   fi
fi
