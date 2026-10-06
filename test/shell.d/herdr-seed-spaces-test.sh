#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/home/Work/tries/pj-omarchy" "$test_dir/omarchy/default/herdr"
export CALL_LOG="$test_dir/calls"
printf '%s\n' pj-omarchy fo-quickshell >"$test_dir/omarchy/default/herdr/spaces"

cat >"$test_dir/bin/agy" <<'SH'
#!/bin/bash
exit 0
SH
cp "$test_dir/bin/agy" "$test_dir/bin/elio"
cp "$test_dir/bin/agy" "$test_dir/bin/nvim"
cat >"$test_dir/bin/herdr" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$CALL_LOG"
if [[ $1 == status && $2 == server ]]; then
  printf '%s\n' "$HERDR_STATUS"
  exit 0
fi
if [[ $1 == api && $2 == snapshot ]]; then
  printf '%s\n' "$(<"$HERDR_SNAPSHOT")"
  exit 0
fi
if [[ $1 == workspace && $2 == create ]]; then
  printf '%s\n' '{"result":{"workspace":{"workspace_id":"w9"},"tab":{"tab_id":"w9:t1"},"root_pane":{"pane_id":"w9:p1"}}}'
  exit 0
fi
if [[ $1 == tab && $2 == create ]]; then
  printf '%s\n' '{"result":{"tab":{"tab_id":"w9:t2"},"root_pane":{"pane_id":"w9:p2"}}}'
  exit 0
fi
exit 0
SH
ln -s "$(command -v jq)" "$test_dir/bin/jq"
ln -s "$(command -v realpath)" "$test_dir/bin/realpath"
chmod +x "$test_dir/bin/agy" "$test_dir/bin/elio" "$test_dir/bin/nvim" "$test_dir/bin/herdr"

seed="$ROOT/bin/omarchy-herdr-seed-spaces"
[[ -x $seed || -f $seed ]] || fail "herdr seed command exists"

run() {
  : >"$CALL_LOG"
  env HOME="$test_dir/home" OMARCHY_PATH="$test_dir/omarchy" PATH="$test_dir/bin" "$@" \
    /usr/bin/bash "$seed" >"$test_dir/output" 2>"$test_dir/err"
}

export HERDR_STATUS='{"running":true}'
project="$test_dir/home/Work/tries/pj-omarchy"
cat >"$test_dir/snapshot-existing.json" <<EOF
{"result":{"snapshot":{"workspaces":[{"workspace_id":"w1","label":"try: pj-omarchy"}],"panes":[{"workspace_id":"w1","cwd":"$project","foreground_cwd":"$project"}],"tabs":[{"workspace_id":"w1","tab_id":"w1:t1","label":"1"}]}}}
EOF
cat >"$test_dir/snapshot-empty.json" <<'EOF'
{"result":{"snapshot":{"workspaces":[],"panes":[],"tabs":[]}}}
EOF
cat >"$test_dir/snapshot-done.json" <<EOF
{"result":{"snapshot":{"workspaces":[{"workspace_id":"w1","label":"pj-omarchy"}],"panes":[{"workspace_id":"w1","cwd":"$project","foreground_cwd":"$project"}],"tabs":[{"workspace_id":"w1","label":"agy"},{"workspace_id":"w1","label":"elio"},{"workspace_id":"w1","label":"nvim"}]}}}
EOF

printf '%s\n' pj-omarchy >"$test_dir/omarchy/default/herdr/spaces"
export HERDR_SNAPSHOT="$test_dir/snapshot-existing.json"
run
grep -qx 'workspace rename w1 pj-omarchy' "$CALL_LOG" || fail "an existing space is renamed to the directory" "$(cat "$CALL_LOG")"
grep -q 'workspace create' "$CALL_LOG" && fail "an existing cwd is not created again" "$(cat "$CALL_LOG")"
grep -qx 'tab create --workspace w1 --cwd '"$project"' --label agy --no-focus' "$CALL_LOG" ||
  fail "a missing agy tab is created" "$(cat "$CALL_LOG")"
grep -qx 'tab create --workspace w1 --cwd '"$project"' --label elio --no-focus' "$CALL_LOG" ||
  fail "a missing elio tab is created" "$(cat "$CALL_LOG")"
grep -qx 'tab create --workspace w1 --cwd '"$project"' --label nvim --no-focus' "$CALL_LOG" ||
  fail "a missing nvim tab is created" "$(cat "$CALL_LOG")"
grep -q 'pane run .* nvim \.' "$CALL_LOG" || fail "nvim starts in the project" "$(cat "$CALL_LOG")"
! grep -qx 'tab close*' "$CALL_LOG" || fail "extra tabs stay open"
pass "an existing space gains the three tabs and keeps its other tabs"

export HERDR_SNAPSHOT="$test_dir/snapshot-done.json"
run
[[ $(grep -c snapshot "$CALL_LOG") -eq 1 ]] || fail "a finished space is only inspected" "$(cat "$CALL_LOG")"
! grep -q 'tab create\|pane run\|workspace create\|workspace rename' "$CALL_LOG" ||
  fail "a second run does not duplicate tabs" "$(cat "$CALL_LOG")"
pass "a second run does not duplicate tabs"

printf '%s\n' fo-quickshell >"$test_dir/omarchy/default/herdr/spaces"
export HERDR_SNAPSHOT="$test_dir/snapshot-empty.json"
quick="$test_dir/home/Work/tries/fo-quickshell"
run
grep -qx "workspace create --cwd $quick --label fo-quickshell --no-focus" "$CALL_LOG" ||
  fail "a missing directory still becomes a space" "$(cat "$CALL_LOG")"
grep -qx 'tab rename w9:t1 agy' "$CALL_LOG" || fail "the first tab is renamed to agy" "$(cat "$CALL_LOG")"
grep -qx 'pane run w9:p1 agy' "$CALL_LOG" || fail "agy starts in the first pane" "$(cat "$CALL_LOG")"
grep -c 'tab create' "$CALL_LOG" | grep -qx 2 || fail "elio and nvim are the only extra tabs" "$(cat "$CALL_LOG")"
pass "a new space is created even when the directory is missing"

export HERDR_STATUS='{"running":false}'
export HERDR_SNAPSHOT="$test_dir/snapshot-empty.json"
if run; then
  fail "a stopped Herdr must leave the seed unapplied"
fi
grep -q 'Herdr is not running' "$test_dir/err" || fail "a stopped Herdr is reported" "$(cat "$test_dir/err")"
! grep -q 'workspace create' "$CALL_LOG" || fail "a stopped Herdr creates nothing" "$(cat "$CALL_LOG")"
pass "a stopped Herdr creates nothing"
unset HERDR_STATUS

rm "$test_dir/bin/elio"
if run; then
  fail "a missing elio must fail the seed"
fi
grep -q 'Missing command: elio' "$test_dir/err" || fail "a missing elio is named" "$(cat "$test_dir/err")"
pass "a missing elio fails the seed"
