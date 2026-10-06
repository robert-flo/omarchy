#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/install" "$test_dir/default/omarchy/sudo-no-update"
export CALL_LOG="$test_dir/calls"

cat >"$test_dir/bin/omarchy-pkg-add" <<'SH'
#!/bin/bash
printf 'repos %s\n' "$*" >>"$CALL_LOG"
exit "${REPOS_STATUS:-0}"
SH
cat >"$test_dir/bin/omarchy-pkg-aur-add" <<'SH'
#!/bin/bash
printf 'aur %s\n' "$*" >>"$CALL_LOG"
exit "${AUR_STATUS:-0}"
SH
cat >"$test_dir/bin/omarchy-pkg-missing" <<'SH'
#!/bin/bash
for pkg in "$@"; do
  [[ " ${PRESENT_PACKAGES:-} " == *" $pkg "* ]] || exit 0
done
exit 1
SH
chmod +x "$test_dir/bin/omarchy-pkg-add" "$test_dir/bin/omarchy-pkg-aur-add" "$test_dir/bin/omarchy-pkg-missing"

cat >"$test_dir/install/omarchy-base.packages" <<'EOF'
# comment and a blank line stay out of the transaction

meld
  extra-repo
EOF
cat >"$test_dir/install/omarchy-aur.packages" <<'EOF'
# elio is AUR-only

elio-bin
EOF

sync="$ROOT/bin/omarchy-pkg-sync"

run_sync() {
  : >"$CALL_LOG"
  env OMARCHY_PATH="$test_dir" PATH="$test_dir/bin:$PATH" \
    "$sync" "$@" >"$test_dir/output" 2>"$test_dir/error"
}

run_sync --repos
[[ $(cat "$CALL_LOG") == "repos meld extra-repo" ]] ||
  fail "pkg-sync --repos installs the Arch list and skips comments" "$(cat "$CALL_LOG")"
[[ ! -s $test_dir/error ]] || fail "pkg-sync --repos stays quiet on success" "$(cat "$test_dir/error")"
pass "pkg-sync --repos installs the Arch list and skips comments"

run_sync --aur
[[ $(cat "$CALL_LOG") == "aur elio-bin" ]] ||
  fail "pkg-sync --aur installs the AUR list" "$(cat "$CALL_LOG")"
pass "pkg-sync --aur installs the AUR list"

PRESENT_PACKAGES="meld" run_sync --repos
[[ $(cat "$CALL_LOG") == "repos extra-repo" ]] ||
  fail "pkg-sync --repos installs only the Arch packages that are missing" "$(cat "$CALL_LOG")"
pass "pkg-sync --repos installs only the Arch packages that are missing"

PRESENT_PACKAGES="meld extra-repo" run_sync --repos
[[ ! -s $CALL_LOG ]] ||
  fail "pkg-sync --repos leaves installed Arch packages alone" "$(cat "$CALL_LOG")"
pass "pkg-sync --repos exits 0 when every Arch package is already installed"

PRESENT_PACKAGES="elio-bin" run_sync --aur
[[ ! -s $CALL_LOG ]] ||
  fail "pkg-sync --aur leaves an installed AUR package alone" "$(cat "$CALL_LOG")"
pass "pkg-sync --aur exits 0 when the AUR package is already installed"

run_sync
[[ $(cat "$CALL_LOG") == $'repos meld extra-repo\naur elio-bin' ]] ||
  fail "pkg-sync without flags installs Arch and then AUR" "$(cat "$CALL_LOG")"
pass "pkg-sync without flags installs Arch and then AUR"

if REPOS_STATUS=1 run_sync --repos; then
  fail "a failed Arch install must fail pkg-sync --repos"
fi
unset REPOS_STATUS
pass "a failed Arch install fails pkg-sync --repos"

if AUR_STATUS=1 run_sync --aur; then
  fail "a failed AUR install must fail pkg-sync --aur"
fi
unset AUR_STATUS
pass "a failed AUR install fails pkg-sync --aur"

if run_sync --nope; then
  fail "pkg-sync accepts an unknown flag"
fi
[[ ! -s $CALL_LOG ]] || fail "an unknown flag still installs packages" "$(cat "$CALL_LOG")"
pass "pkg-sync rejects an unknown flag"

rm "$test_dir/install/omarchy-base.packages"
if run_sync --repos; then
  fail "pkg-sync --repos ignores a missing Arch list"
fi
pass "pkg-sync --repos fails when the Arch list is missing"

# The cold update phase sets this so yay cannot refresh a sudo timestamp.
cat >"$test_dir/bin/yay" <<'SH'
#!/bin/bash
printf 'yay %s\n' "$*" >>"$CALL_LOG"
exit 0
SH
cat >"$test_dir/bin/omarchy-pkg-missing" <<'SH'
#!/bin/bash
exit 0
SH
cat >"$test_dir/bin/pacman" <<'SH'
#!/bin/bash
exit 0
SH
cat >"$test_dir/default/omarchy/sudo-no-update/sudo" <<'SH'
#!/bin/bash
exit 0
SH
chmod +x "$test_dir/bin/yay" "$test_dir/bin/omarchy-pkg-missing" "$test_dir/bin/pacman" \
  "$test_dir/default/omarchy/sudo-no-update/sudo"

: >"$CALL_LOG"
env OMARCHY_PATH="$test_dir" OMARCHY_SUDO_NO_UPDATE=1 PATH="$test_dir/bin:$PATH" \
  "$ROOT/bin/omarchy-pkg-aur-add" elio-bin >"$test_dir/output" 2>"$test_dir/error"
grep -Fx "yay --sudo $test_dir/default/omarchy/sudo-no-update/sudo --sudoloop=false -S --noconfirm --needed -- elio-bin" "$CALL_LOG" >/dev/null ||
  fail "pkg-aur-add refuses to cache sudo while the update is cold" "$(cat "$CALL_LOG")"
pass "pkg-aur-add refuses to cache sudo while the update is cold"
