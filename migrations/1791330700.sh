echo "Deploy Cursor CLI configuration and permissions policies to ~/.cursor and ~/.config/cursor"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

if [[ -d "$OMARCHY_PATH/default/cursor" ]]; then
  mkdir -p "$HOME/.cursor" "$HOME/.config/cursor"

  if [[ -f "$OMARCHY_PATH/default/cursor/permissions.json" ]]; then
    cp -f "$OMARCHY_PATH/default/cursor/permissions.json" "$HOME/.cursor/permissions.json"
    cp -f "$OMARCHY_PATH/default/cursor/permissions.json" "$HOME/.config/cursor/permissions.json"
  fi

  tpl="$OMARCHY_PATH/default/cursor/cli-config.json"
  if [[ -f "$tpl" ]]; then
    has_active_session() {
      local file="$1"
      [[ -f "$file" ]] || return 1
      jq -e '
        .authInfo? and (
          if (.authInfo | type) == "object" then
            ([.authInfo[] | strings | select(length > 0)] | length > 0) or
            ([.authInfo[] | numbers | select(. > 0)] | length > 0)
          elif (.authInfo | type) == "string" then
            (.authInfo | length > 0)
          else
            false
          end
        )
      ' "$file" >/dev/null 2>&1
    }

    session_src=""
    if has_active_session "$HOME/.config/cursor/cli-config.json"; then
      session_src="$HOME/.config/cursor/cli-config.json"
    elif has_active_session "$HOME/.cursor/cli-config.json"; then
      session_src="$HOME/.cursor/cli-config.json"
    fi

    if [[ -n "$session_src" ]]; then
      merged=$(mktemp)
      if jq -s '
        .[0] as $tpl | .[1] as $existing |
        ($tpl * $existing) * {
          authInfo: (if ($existing.authInfo // null) != null then $existing.authInfo else $tpl.authInfo end),
          autoReviewAvailabilityCache: (
            if ($existing.autoReviewAvailabilityCache.authCacheKey // "") != ""
            then $existing.autoReviewAvailabilityCache
            else $tpl.autoReviewAvailabilityCache end
          ),
          serverConfigCache: (
            if ($existing.serverConfigCache.authCacheKey // "") != ""
            then $existing.serverConfigCache
            else $tpl.serverConfigCache end
          ),
          privacyCache: (
            if ($existing.privacyCache // null) != null
            then $existing.privacyCache
            else $tpl.privacyCache end
          ),
          permissions: $tpl.permissions
        }
      ' "$tpl" "$session_src" > "$merged" 2>/dev/null; then
        cp -f "$merged" "$HOME/.cursor/cli-config.json"
        cp -f "$merged" "$HOME/.config/cursor/cli-config.json"
      else
        cp -f "$tpl" "$HOME/.cursor/cli-config.json"
        cp -f "$tpl" "$HOME/.config/cursor/cli-config.json"
      fi
      rm -f "$merged"
    else
      cp -f "$tpl" "$HOME/.cursor/cli-config.json"
      cp -f "$tpl" "$HOME/.config/cursor/cli-config.json"
    fi
  fi
fi
