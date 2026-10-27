echo "Install the packaged bashrc stub and rewrite the agy wrapper"

# Same file omarchy-settings post_upgrade copies onto /etc/skel/.bashrc.
# Always read from the packaged location (omarchy-settings), never $OMARCHY_PATH,
# which may point at a dev checkout. Only this file is copied into the home.
stub="/usr/share/omarchy/etc-overrides/dot.bashrc"
if [[ ! -f $stub ]]; then
  echo "ERROR: $stub not found. Is omarchy-settings installed? Run: sudo pacman -S omarchy-settings" >&2
  exit 1
fi

if [[ -e $HOME/.bashrc ]]; then
  backup="$HOME/.bashrc.bak-$(date +%Y%m%d%H%M%S)"
  cp -a "$HOME/.bashrc" "$backup"
  echo "Backed up ~/.bashrc to $backup"
fi
cp "$stub" "$HOME/.bashrc"

# Regenerates ~/.local/bin/agy, including --dangerously-skip-permissions.
omarchy-mise-install antigravity-cli agy
