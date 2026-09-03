# Provision the lazy first-use stubs for the heavy and AUR-backed launchers.
# Nothing heavy is downloaded here: every line merely writes a ~/.local/bin
# wrapper that installs its tool on first use (the same lazy philosophy as the
# mise-backed CLIs in mise.sh). Kept out of mise.sh because these are not mise
# tools -- two are official binaries/AppImages, three are AUR system packages
# whose real binary lives in /usr/bin and shadows the wrapper once installed.
set -euo pipefail

# Large official GUI tools: stubbed now, installed on first launch.
omarchy-install-mimo --stub
omarchy-install-opencode-desktop --stub

# AUR system packages: wrapper wins only while the package is absent, then the
# /usr/bin binary takes over. Installed on first use, not in provisioning.
omarchy-install-aur microsoft-edge-stable-bin microsoft-edge-stable
omarchy-install-aur lyricify lyricify
omarchy-install-aur spicetify-cli spicetify
