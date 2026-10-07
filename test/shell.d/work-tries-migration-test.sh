#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1791328979.sh"
[[ -f $migration ]] || fail "Work/tries migration exists"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
home="$test_dir/home"
mkdir -p "$home"

run_migration() {
  HOME="$home" bash -euo pipefail "$migration" >/dev/null ||
    fail "migration exits clean"
}

run_migration
[[ -d $home/Work/tries ]] || fail "migration creates ~/Work/tries"
pass "migration creates ~/Work/tries"

touch "$home/Work/tries/keep"
run_migration
[[ -f $home/Work/tries/keep ]] || fail "rerun keeps existing ~/Work/tries content"
pass "migration can be rerun without touching existing content"
