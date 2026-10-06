#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1791324000.sh"
[[ -f $migration ]] || fail "Antigravity settings migration exists"

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

for app in antigravity antigravity-cli antigravity-ide; do
  file="$home/.gemini/$app/settings.json"
  [[ -f $file ]] || fail "migration deploys $app settings.json"
  cmp -s "$file" "$ROOT/default/gemini/$app/settings.json" ||
    fail "migration deploys matching $app settings.json content"
done
pass "migration deploys Antigravity settings to fresh home"

# ------------------------------------------------------------------ overwrite existing
for app in antigravity antigravity-cli antigravity-ide; do
  printf '{"old": true}\n' > "$home/.gemini/$app/settings.json"
done

run_migration

for app in antigravity antigravity-cli antigravity-ide; do
  file="$home/.gemini/$app/settings.json"
  cmp -s "$file" "$ROOT/default/gemini/$app/settings.json" ||
    fail "migration overwrites existing $app settings.json"
done
pass "migration overwrites existing Antigravity settings"

# ------------------------------------------------------------------ idempotent
run_migration
for app in antigravity antigravity-cli antigravity-ide; do
  file="$home/.gemini/$app/settings.json"
  cmp -s "$file" "$ROOT/default/gemini/$app/settings.json" ||
    fail "migration remains idempotent for $app"
done
pass "migration is idempotent"

# ------------------------------------------------------------------ missing source
rm -rf "$home"
mkdir -p "$home" "$test_dir/empty-omarchy"
HOME="$home" OMARCHY_PATH="$test_dir/empty-omarchy" bash -euo pipefail "$migration" >/dev/null ||
  fail "migration exits clean when source is missing"
[[ ! -e $home/.gemini ]] || fail "migration does not create .gemini when source is missing"
pass "migration no-ops when source is missing"
