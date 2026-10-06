echo "Deploy Antigravity tool and sandbox policies"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

if [[ -d "$OMARCHY_PATH/default/gemini" ]]; then
  for app in antigravity antigravity-cli antigravity-ide; do
    src="$OMARCHY_PATH/default/gemini/$app/settings.json"
    if [[ -f "$src" ]]; then
      mkdir -p "$HOME/.gemini/$app"
      cp -f "$src" "$HOME/.gemini/$app/settings.json"
    fi
  done
fi
