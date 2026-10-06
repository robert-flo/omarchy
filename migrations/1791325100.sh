echo "Deploy Cursor CLI configuration and permissions policies"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

if [[ -d "$OMARCHY_PATH/default/cursor" ]]; then
  mkdir -p "$HOME/.cursor"
  for file in cli-config.json permissions.json; do
    src="$OMARCHY_PATH/default/cursor/$file"
    if [[ -f "$src" ]]; then
      cp -f "$src" "$HOME/.cursor/$file"
    fi
  done
fi
