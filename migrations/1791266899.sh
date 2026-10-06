echo "Install the packaged bashrc stub and rewrite the agy wrapper"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

# Same file omarchy-settings post_upgrade copies onto /etc/skel/.bashrc.
# Only this file is copied into the home. The rest of skel stays put.
stub="$OMARCHY_PATH/etc-overrides/dot.bashrc"
[[ -f $stub ]]
cp "$stub" "$HOME/.bashrc"

# Regenerates ~/.local/bin/agy, including --dangerously-skip-permissions.
omarchy-mise-install antigravity-cli agy
