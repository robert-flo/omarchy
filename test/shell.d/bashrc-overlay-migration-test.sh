#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1793228944.sh"
[[ -f $migration ]] || fail "bashrc overlay migration exists"

line_env='[[ -r /usr/share/ravn/omarchy/bash/env ]] && source /usr/share/ravn/omarchy/bash/env'
line_rc='[[ -r /usr/share/ravn/omarchy/bash/rc ]] && source /usr/share/ravn/omarchy/bash/rc'
grep -qxF "$line_env" "$ROOT/default/bashrc" || fail "stub has the env extension point"
grep -qxF "$line_rc" "$ROOT/default/bashrc" || fail "stub has the rc extension point"

t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
run() { HOME="$t/home" OMARCHY_PATH="$ROOT" bash -euo pipefail "$migration" >/dev/null 2>"$t/err"; }
reset() { rm -rf "$t/home"; mkdir -p "$t/home"; }

# Missing ~/.bashrc: nothing created.
reset; run || fail "runs without ~/.bashrc"
[[ ! -e $t/home/.bashrc ]] || fail "does not create ~/.bashrc"

# Old stub: lines inserted after their anchors, user content kept, backup in cache.
reset
grep -vxF -e "$line_env" -e "$line_rc" "$ROOT/default/bashrc" >"$t/home/.bashrc"
echo "alias mine=true" >>"$t/home/.bashrc"
run || fail "patches old stub"
cmp -s <(grep -vx 'alias mine=true' "$t/home/.bashrc") "$ROOT/default/bashrc" || fail "result matches stub order"
grep -qx 'alias mine=true' "$t/home/.bashrc" || fail "keeps user content"
ls "$t/home/.cache/ravn-piloto/"bashrc.bak-* >/dev/null 2>&1 || fail "backup in ~/.cache/ravn-piloto"
[[ -z $(find "$t/home" -maxdepth 1 -name '.bashrc.*') ]] || fail "no backups or temp files in \$HOME"

# Idempotent: second run is a byte-for-byte no-op without new backups.
cp "$t/home/.bashrc" "$t/before"
run; cmp -s "$t/before" "$t/home/.bashrc" || fail "idempotent"
[[ $(ls "$t/home/.cache/ravn-piloto" | wc -l) == 1 ]] || fail "no backup when unchanged"

# Already present, CRLF + indentation + no trailing newline: untouched.
reset
printf '  %s\r\n%s' "$line_env" "$line_rc" >"$t/home/.bashrc"
cp "$t/home/.bashrc" "$t/before"
run; cmp -s "$t/before" "$t/home/.bashrc" || fail "no rewrite without trailing newline / with CRLF"
[[ ! -d $t/home/.cache/ravn-piloto ]] || fail "no backup when already present"

# No anchors: env first, rc last.
reset; echo "echo hi" >"$t/home/.bashrc"
run
[[ $(head -1 "$t/home/.bashrc") == "$line_env" && $(tail -1 "$t/home/.bashrc") == "$line_rc" ]] || fail "fallback placement"

# Symlink: warn and leave the target alone.
reset; echo "dotfiles" >"$t/target"; ln -s "$t/target" "$t/home/.bashrc"
run || fail "symlink exits zero"
grep -q symlink "$t/err" || fail "symlink warns"
[[ $(cat "$t/target") == dotfiles && -L $t/home/.bashrc ]] || fail "symlink target untouched"

pass "bashrc overlay migration"
