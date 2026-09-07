# tool for suggesting fixes to typos
if [ "${-#*i}" == "$-" ] && which thefuck &> /dev/null; then
  eval "$(thefuck --alias)"
fi