#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/home"
export CALL_LOG="$test_dir/calls"

cat >"$test_dir/bin/omarchy-pkg-aur-add" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$CALL_LOG"
exit "${AUR_STATUS:-0}"
SH
chmod +x "$test_dir/bin/omarchy-pkg-aur-add"

migration="$ROOT/migrations/1791260741.sh"
[[ -f $migration ]] || fail "elio migration exists"

run() {
  : >"$CALL_LOG"
  env HOME="$test_dir/home" OMARCHY_PATH="$ROOT" PATH="$test_dir/bin:$PATH" "$@" \
    bash -euo pipefail "$migration" >"$test_dir/output" 2>&1
}

run
[[ $(cat "$CALL_LOG") == "elio-bin" ]] || fail "elio migration installs elio-bin from the AUR" "$(cat "$CALL_LOG")"
grep -q "Install elio from the AUR" "$test_dir/output" || fail "elio migration says what it does" "$(cat "$test_dir/output")"
pass "elio migration installs elio-bin from the AUR"

run
[[ $(cat "$CALL_LOG") == "elio-bin" ]] || fail "elio migration can be rerun" "$(cat "$CALL_LOG")"
pass "elio migration can be rerun"

if run AUR_STATUS=1; then
  fail "a failed AUR install must leave the elio migration pending"
fi
pass "a failed AUR install leaves the elio migration pending"
