echo "Install Command Code (cmd) via mise wrapper"

if omarchy-cmd-missing cmd && [[ ! -f $HOME/.local/state/omarchy/preinstalls-removed ]]; then
  omarchy-mise-install npm:command-code cmd
fi
