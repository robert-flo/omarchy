echo "Install elio from the AUR"

# elio-bin is not in the pacman repos. omarchy-pkg-aur-add no-ops when the
# package is already installed and leaves this migration pending if yay fails,
# so a child machine does not continue without elio.
omarchy-pkg-aur-add elio-bin
