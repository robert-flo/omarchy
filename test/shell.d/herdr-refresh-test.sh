#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin"
export CALL_LOG="$test_dir/calls"

cat >"$test_dir/bin/omarchy-refresh-config" <<'SH'
#!/bin/bash
printf 'refresh %s\n' "$*" >>"$CALL_LOG"
SH
cat >"$test_dir/bin/omarchy-restart-herdr" <<'SH'
#!/bin/bash
printf 'restart\n' >>"$CALL_LOG"
SH
cat >"$test_dir/bin/omarchy-herdr-seed-spaces" <<'SH'
#!/bin/bash
printf 'seed\n' >>"$CALL_LOG"
exit "${SEED_STATUS:-0}"
SH
cat >"$test_dir/bin/herdr" <<'SH'
#!/bin/bash
printf '%s\n' "$HERDR_STATUS"
SH
cat >"$test_dir/bin/jq" <<'SH'
#!/bin/bash
if [[ ${HERDR_STATUS:-} == *'"running":true'* ]]; then
  printf 'true\n'
else
  printf 'false\n'
fi
SH
chmod +x "$test_dir/bin/"*

refresh="$ROOT/bin/omarchy-refresh-herdr"

run() {
  : >"$CALL_LOG"
  env PATH="$test_dir/bin" "$@" /usr/bin/bash "$refresh" >"$test_dir/output" 2>"$test_dir/err"
}

export HERDR_STATUS='{"running":true}'
run
[[ $(cat "$CALL_LOG") == $'refresh herdr/config.toml\nrestart\nseed' ]] ||
  fail "an open Herdr is refreshed and then seeded" "$(cat "$CALL_LOG")"
pass "an open Herdr is refreshed and then seeded"

export HERDR_STATUS='{"running":false}'
run
[[ $(cat "$CALL_LOG") == $'refresh herdr/config.toml\nrestart' ]] ||
  fail "a closed Herdr still refreshes its config" "$(cat "$CALL_LOG")"
pass "a closed Herdr still refreshes its config"

export HERDR_STATUS='{"running":true}'
if run SEED_STATUS=1; then
  fail "a failed seed must fail the Herdr refresh"
fi
pass "a failed seed fails the Herdr refresh"
