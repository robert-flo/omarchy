#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1791330700.sh"
[[ -f $migration ]] || fail "Cursor settings migration exists"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
home="$test_dir/home"

run_migration() {
  HOME="$home" OMARCHY_PATH="$ROOT" bash -euo pipefail "$migration" >/dev/null ||
    fail "migration exits clean"
}

# ------------------------------------------------------------------ fresh home
rm -rf "$home"
mkdir -p "$home"
run_migration

for dir in .cursor .config/cursor; do
  for file in cli-config.json permissions.json; do
    target="$home/$dir/$file"
    [[ -f $target ]] || fail "migration deploys Cursor $dir/$file"
    cmp -s "$target" "$ROOT/default/cursor/$file" ||
      fail "migration deploys matching Cursor $dir/$file content"
  done
done
pass "migration deploys Cursor settings to fresh home across dual directories"

# ------------------------------------------------------------------ overwrite existing without session
for dir in .cursor .config/cursor; do
  for file in cli-config.json permissions.json; do
    printf '{"old": true}\n' > "$home/$dir/$file"
  done
done

run_migration

for dir in .cursor .config/cursor; do
  for file in cli-config.json permissions.json; do
    target="$home/$dir/$file"
    cmp -s "$target" "$ROOT/default/cursor/$file" ||
      fail "migration overwrites existing unauthenticated Cursor $dir/$file"
  done
done
pass "migration overwrites existing unauthenticated Cursor settings"

# ------------------------------------------------------------------ preserve active session
rm -rf "$home"
mkdir -p "$home/.cursor"
cat << 'EOF' > "$home/.cursor/cli-config.json"
{
  "authInfo": {
    "email": "user@example.com",
    "displayName": "Test User",
    "userId": 12345,
    "authId": "auth0|testuser"
  },
  "autoReviewAvailabilityCache": {
    "backendUrl": "https://api2.cursor.sh",
    "authCacheKey": "auth:auth0|testuser",
    "available": true,
    "updatedAt": 1791082804728
  },
  "customPref": "preserved"
}
EOF

run_migration

for dir in .cursor .config/cursor; do
  target="$home/$dir/cli-config.json"
  [[ -f $target ]] || fail "cli-config exists in $dir"
  
  jq -e '
    .authInfo.email == "user@example.com" and
    .authInfo.userId == 12345 and
    .authInfo.authId == "auth0|testuser" and
    .autoReviewAvailabilityCache.authCacheKey == "auth:auth0|testuser" and
    .customPref == "preserved" and
    .display.mode == "zen" and
    .sandbox.mode == "disabled" and
    .permissions.deny == []
  ' "$target" >/dev/null || fail "migration preserves active session and merges template in $dir"

  perm_target="$home/$dir/permissions.json"
  [[ -f $perm_target ]] || fail "permissions.json exists in $dir"
  cmp -s "$perm_target" "$ROOT/default/cursor/permissions.json" ||
    fail "permissions.json matches template in $dir"
done
pass "migration preserves active session across dual directories"

# ------------------------------------------------------------------ idempotent
cli_cursor_before=$(mktemp)
cli_config_before=$(mktemp)
cp "$home/.cursor/cli-config.json" "$cli_cursor_before"
cp "$home/.config/cursor/cli-config.json" "$cli_config_before"

run_migration

cmp -s "$home/.cursor/cli-config.json" "$cli_cursor_before" ||
  fail "migration is idempotent for .cursor/cli-config.json"
cmp -s "$home/.config/cursor/cli-config.json" "$cli_config_before" ||
  fail "migration is idempotent for .config/cursor/cli-config.json"
rm -f "$cli_cursor_before" "$cli_config_before"

pass "migration is idempotent"

# ------------------------------------------------------------------ missing source
rm -rf "$home"
mkdir -p "$home" "$test_dir/empty-omarchy"
HOME="$home" OMARCHY_PATH="$test_dir/empty-omarchy" bash -euo pipefail "$migration" >/dev/null ||
  fail "migration exits clean when source is missing"
[[ ! -e $home/.cursor ]] || fail "migration does not create .cursor when source is missing"
[[ ! -e $home/.config/cursor ]] || fail "migration does not create .config/cursor when source is missing"
pass "migration no-ops when source is missing"
