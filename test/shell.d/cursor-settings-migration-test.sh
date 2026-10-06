#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1791325100.sh"
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

for file in cli-config.json permissions.json; do
  target="$home/.cursor/$file"
  [[ -f $target ]] || fail "migration deploys Cursor $file"
  cmp -s "$target" "$ROOT/default/cursor/$file" ||
    fail "migration deploys matching Cursor $file content"
done
pass "migration deploys Cursor settings to fresh home"

# ------------------------------------------------------------------ overwrite existing
for file in cli-config.json permissions.json; do
  printf '{"old": true}\n' > "$home/.cursor/$file"
done

run_migration

for file in cli-config.json permissions.json; do
  target="$home/.cursor/$file"
  cmp -s "$target" "$ROOT/default/cursor/$file" ||
    fail "migration overwrites existing Cursor $file"
done
pass "migration overwrites existing Cursor settings"

# ------------------------------------------------------------------ idempotent
run_migration
for file in cli-config.json permissions.json; do
  target="$home/.cursor/$file"
  cmp -s "$target" "$ROOT/default/cursor/$file" ||
    fail "migration remains idempotent for Cursor $file"
done
pass "migration is idempotent"

# ------------------------------------------------------------------ missing source
rm -rf "$home"
mkdir -p "$home" "$test_dir/empty-omarchy"
HOME="$home" OMARCHY_PATH="$test_dir/empty-omarchy" bash -euo pipefail "$migration" >/dev/null ||
  fail "migration exits clean when source is missing"
[[ ! -e $home/.cursor ]] || fail "migration does not create .cursor when source is missing"
pass "migration no-ops when source is missing"
