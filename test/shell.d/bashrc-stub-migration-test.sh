#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1791266899.sh"
[[ -f $migration ]] || fail "bashrc stub migration exists"

grep -q '^stub="/usr/share/omarchy/etc-overrides/dot.bashrc"$' "$migration" ||
  fail "stub is read from the packaged omarchy-settings path"
grep -v '^ *#' "$migration" | grep -q 'OMARCHY_PATH' && fail "stub does not depend on OMARCHY_PATH"

if [[ ! -f /usr/share/omarchy/etc-overrides/dot.bashrc ]]; then
  test_dir=$(mktemp -d)
  trap 'rm -rf "$test_dir"' EXIT
  mkdir -p "$test_dir/home"
  echo "keep me" >"$test_dir/home/.bashrc"
  if HOME="$test_dir/home" OMARCHY_PATH="$ROOT" bash "$migration" >/dev/null 2>"$test_dir/err"; then
    fail "migration exits non-zero when the packaged stub is missing"
  fi
  grep -q "not found" "$test_dir/err" || fail "missing stub prints a clear error"
  [[ $(cat "$test_dir/home/.bashrc") == "keep me" ]] || fail "~/.bashrc untouched when stub is missing"
fi

pass "bashrc stub migration"
