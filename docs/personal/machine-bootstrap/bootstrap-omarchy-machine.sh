#!/usr/bin/env bash
# bootstrap-omarchy-machine.sh — put any machine onto the personal Omarchy system.
#
# There are exactly TWO scenarios (see AGENTS.personal.md / the personal-fork skill):
#
#   --child  A "client" machine that only RECEIVES personalizations. You run this once
#            after the official ISO. Everything it installs is delivered by the package:
#            trust the repo key -> install the published pair -> refresh pacman ->
#            `omarchy update` -> `omarchy provision user --force` -> verify.
#            After this, the machine maintains itself with `omarchy update`.
#
#   --dev    A machine you BUILD ON. It clones the fork layout under ~/Work/omarchy and
#            installs the LOCAL `omarchy-dev` + `omarchy-settings-dev` pair built from the
#            working tree. Leaves the machine on the `-dev` channel — run `omarchy update`
#            there is a mistake that wipes the local work (see LESSON LEARNED below).
#
# Default mode is --child. The script is idempotent in both modes.
#
# -------------------------------------------------------------------------------------
# DESIGN NOTES — why it is written this way (so a future agent/human trusts the shape)
# -------------------------------------------------------------------------------------
#
# 1. THE ONLY DISTRIBUTION TRIGGER IS `omarchy update`.
#    Nothing on a child machine is installed by a loose per-machine helper. This script is
#    only a convenience for the first boot: after it finishes, the pair itself is what keeps
#    the machine current. That is why almost every step below calls an existing `omarchy …`
#    command instead of re-implementing logic.
#
# 2. THE PAIR VERSION IS NEVER HARD-CODED.
#    The fork's docs forbid writing a literal version outside the State table
#    (docs/personal/README.md). Here the version is DERIVED from the personal repo's own
#    pacman database (the true single source of truth on the wire): we read the newest
#    `omarchy-<version>` directory and install `omarchy-<version>` + `omarchy-settings-<version>`
#    together (lockstep — same version, always, or the exact-version dependency breaks).
#
# 3. `omarchy update` DOES NOT RE-PROVISION USER STATE. (Lesson learned, 2026-09-02.)
#    Updating the pair installs files but does NOT rewrite an existing user's $HOME: the
#    per-user finalization is gated by the `finalize-user` marker and is skipped once done.
#    So a child machine that already exists must be told to re-run it explicitly:
#        omarchy provision user --force
#    This is what materializes configs, launchers and the lazy first-use stubs
#    (install/user/all.sh -> install/user/launchers.sh). On the FIRST boot this also happens
#    as part of finalization, so running it here is cheap and always correct.
#
# 4. DEV MODE REPLICATES `omarchy dev pkg-test` WITH `pkexec` INSTEAD OF `sudo`.
#    The official `omarchy dev pkg-test` ends in `sudo pacman -U`, which cannot prompt for a
#    password without a TTY (an agent run). Omarchy's rule: with a terminal use sudo, without
#    one use pkexec. The dev loop below reproduces the tool's steps 1:1 but installs the pair
#    with `pkexec`.
#
# 5. THE DEV PAIR MUST BE INSTALLED TOGETHER. (Trap verified 2026-08-30 / 2026-09-01.)
#    On a machine with the STOCK pair, `omarchy-settings-dev` and `omarchy-settings` CONFLICT,
#    and stock `omarchy` depends on `omarchy-settings=<pkgver>` EXACTLY. Installing one dev
#    package on its own breaks that dependency. Solution: install BOTH in a single
#    `pacman -U --ask 4 --overwrite='*'` (the same trick upstream's build wrapper uses).
#
# -------------------------------------------------------------------------------------
# LESSON LEARNED (2026-09-01): `omarchy update` on a DEV machine wipes the local pair.
#
#   Symptom: we installed the dev pair dev.0e6c11d5 (with a new web app) and minutes later
#   the app vanished from the launcher. pacman's log showed `omarchy update` had "upgraded"
#   the pair to 4.0.0.r1832.g23dab9e-1.
#
#   Root cause: the OFFICIAL repo also publishes `omarchy-dev`/`omarchy-settings-dev`,
#   versioned with git describe of quattro (4.0.0.rNNN.g<sha>), and that version BEATS our
#   `dev.<sha>` by vercmp. So to pacman the official dev pair is an "upgrade" of ours, and any
#   `omarchy update` installs it — dropping the local customizations. It is the partial-shading
#   rule (keep the personal ahead in version) manifesting INSIDE the dev loop: we lose by
#   version, not by name.
#
#   Operating rule derived:
#     - On a machine on the dev line NEVER run `omarchy update`. The normal update is for
#       stock/production (child) machines.
#     - If it ran by accident and customizations "disappear": run `--dev` again; the build
#       phase reinstalls the local pair. The script detects a mismatch and says so.
# -------------------------------------------------------------------------------------
#
# Exit code 0 on success, 1 on failure (with a recovery hint).

set -euo pipefail

# -------------------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------------------
GH="https://github.com"
RAW="https://raw.githubusercontent.com"
FORK_OWNER="robert-flo"
SRC_REPO="robert-flo/omarchy"
SRC_BRANCH="personal"
DEFAULT_UPSTREAM="${GH}/${SRC_REPO}.git"
REPO_URL="https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64"
# Public key id of the personal pacman repo (see docs/personal/README.md placeholder
# <GPG_KEY_ID>). The public key is versioned in the fork at keys/omarchy-personal-repo.pub.asc.
GPG_KEY_ID="D5E75EAC51A44715"

WORK="$HOME/Work/omarchy"
GH_SSH="git@github.com:"

MODE=""            # child (default) | dev
NO_INSTALL=false    # --dev --no-install : clone only, do not build/install the dev pair
PUB_KEY_PATH=""     # optional local path to the pub key; else fetched from the fork raw

usage() {
  cat <<'USAGE'
Usage: bootstrap-omarchy-machine.sh [--child | --dev] [options]

Put this machine onto the personal Omarchy system.

Modes:
  --child           Client machine (default): receive personalizations via omarchy update.
                    Trusts the key, installs the published pair once, refreshes pacman,
                    runs `omarchy update` + `omarchy provision user --force`, reinstalls the
                    package set, and verifies. Safe to re-run; idempotent.
  --dev             Development machine: clone the fork layout (~/Work/omarchy) and install
                    the LOCAL omarchy-dev + omarchy-settings-dev pair built from the working
                    tree. Leaves the machine on the -dev channel (do NOT run omarchy update).

Options:
  --key <path>      Path to the personal repo public key (default: fetch from the fork raw).
  --no-install      (dev) Clone/layout only; do not build or install the dev pair.
  -h, --help        Show this help.
USAGE
}

while (($#)); do
  case "$1" in
    --child) MODE="child" ;;
    --dev) MODE="dev" ;;
    --key) PUB_KEY_PATH="$2"; shift ;;
    --no-install) NO_INSTALL=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

[[ -z "$MODE" ]] && MODE="child"
echo "== Mode: $MODE"

require_tool() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1" >&2; exit 1; }; }
require_tool curl
require_tool bsdtar
require_tool pacman

# -------------------------------------------------------------------------------------
# CHILD MODE
# -------------------------------------------------------------------------------------
child_main() {
  local pub_key="$PUB_KEY_PATH" dir zst sig
  local tmp par pkgs_dir

  echo ""
  echo "== [child] Trusting the personal repo key"
  if [[ -z "$pub_key" ]]; then
    pub_key=$(mktemp -t omarchy-key.XXXXXX)
    curl -fsSL -o "$pub_key" "$RAW/$SRC_REPO/$SRC_BRANCH/keys/omarchy-personal-repo.pub.asc"
  fi
  sudo pacman-key --add "$pub_key"
  sudo pacman-key --lsign-key "$GPG_KEY_ID"

  # Derive the pair version from the personal repo's own database (never hard-coded).
  echo ""
  echo "== [child] Reading the latest pair version from the personal repo"
  tmp=$(mktemp -d -t omarchy-child.XXXXXX)
  curl -fsSL -o "$tmp/omarchy.db.tar.zst" "$REPO_URL/omarchy.db.tar.zst"
  par=$(bsdtar -tf "$tmp/omarchy.db.tar.zst" | grep -oE '^omarchy-[0-9][^/]*/' | sort -V | tail -1 \
        | sed -E 's#^omarchy-([^/]*)/#\1#')
  [[ -n "$par" ]] || { echo "Could not derive the pair version from the personal repo." >&2; exit 1; }
  echo "   latest pair version: $par"

  # Download both halves + signatures and install them TOGETHER (lockstep).
  echo ""
  echo "== [child] Installing the published pair $par (first boot)"
  pkgs_dir="$tmp/pkgs"
  mkdir -p "$pkgs_dir"
  for P in "omarchy-$par" "omarchy-settings-$par"; do
    base="$P-any"
    curl -fsSL -o "$pkgs_dir/$base.pkg.tar.zst" "$REPO_URL/$base.pkg.tar.zst"
    curl -fsSL -o "$pkgs_dir/$base.pkg.tar.zst.sig" "$REPO_URL/$base.pkg.tar.zst.sig"
  done
  # The .sig files sit next to the .pkg.tar.zst; pacman verifies them automatically.
  sudo pacman -U --noconfirm "$pkgs_dir"/*.pkg.tar.zst

  # Now that omarchy is installed, use the real commands for the rest.
  echo ""
  echo "== [child] Configuring pacman (personal repo first) + full update"
  omarchy refresh pacman
  omarchy update

  # update does NOT rewrite an existing user's $HOME; force the user finalization so configs,
  # launchers and lazy first-use stubs (install/user/all.sh) are materialized for this user.
  echo ""
  echo "== [child] Materializing user configs, launchers and first-use stubs"
  omarchy provision user --force

  echo ""
  echo "== [child] Reconciling the package set"
  omarchy reinstall pkgs

  rm -rf "$tmp"

  echo ""
  echo "== [child] Verifying"
  pacman -Q omarchy omarchy-settings
  echo ""
  echo "== [child] Done. This machine now maintains itself with: omarchy update"
  echo "   (new launchers/stubs introduced by a future par are materialized with:"
  echo "    omarchy provision user --force)"
}

# -------------------------------------------------------------------------------------
# DEV MODE
# -------------------------------------------------------------------------------------
clone_or_skip() {
  local dir="$1" url="$2"
  if [[ -d "$dir/.git" ]]; then
    echo "   $dir already exists, skipping clone"
  else
    git clone "$url" "$dir"
  fi
}

remove_pkgver_function() {
  # Replica of remove_pkgver_function() in bin/omarchy-dev-pkg-test: removes the whole
  # pkgver() function by counting braces (the PKGBUILD uses a dynamic upstream-based
  # pkgver(); for a local OMARCHY_SRC build it would clobber our dev pkgver).
  local pkgbuild="$1"
  local tmp="$pkgbuild.tmp"
  awk '
    /^pkgver\(\)[[:space:]]*\{/ { in_pkgver = 1; depth = 0 }
    in_pkgver {
      line = $0; opens = gsub(/\{/, "{", line)
      line = $0; closes = gsub(/\}/, "}", line)
      depth += opens - closes
      if (depth <= 0) { in_pkgver = 0 }
      next
    }
    { print }
  ' "$pkgbuild" >"$tmp" && mv "$tmp" "$pkgbuild"
}

dev_main() {
  require_tool git
  require_tool makepkg
  require_tool pkexec

  echo ""
  echo "== [dev] Fase 1 — clones under $WORK"
  mkdir -p "$WORK"

  # fork|work-branch|upstream-repo|upstream-branch (for the W9 rebase cadence)
  declare -A REPOS=(
    ["$WORK/omarchy-installer"]="${FORK_OWNER}/omarchy|personal|omacom/omarchy|quattro"
    ["$WORK/omarchy-pkgs"]="${FORK_OWNER}/omarchy-pkgs|master|omacom/omarchy-pkgs|master"
    ["$WORK/scratchpad"]="${FORK_OWNER}/scratchpad|master|-|-"
  )

  local dir fork branch upstream_repo upstream_branch
  for dir in "${!REPOS[@]}"; do
    IFS='|' read -r fork branch upstream_repo upstream_branch <<<"${REPOS[$dir]}"
    clone_or_skip "$dir" "${GH_SSH}${fork}.git"
    git -C "$dir" checkout "$branch" 2>/dev/null || true
    if [[ "$upstream_repo" != "-" ]] && ! git -C "$dir" remote get-url upstream &>/dev/null; then
      git -C "$dir" remote add upstream "${GH_SSH}${upstream_repo}.git"
      echo "   $dir: added upstream remote ($upstream_repo)"
    fi
    git -C "$dir" fetch upstream 2>/dev/null || true
  done

  # Condición del paso §0.2.2: el dev loop apunta al fork (no al default basecamp).
  export OMARCHY_UPSTREAM_URL="${OMARCHY_UPSTREAM_URL:-$DEFAULT_UPSTREAM}"

  if $NO_INSTALL; then
    echo "== [dev] --no-install: layout done, skipping the dev pair build/install."
  else
    dev_build_install
  fi

  echo ""
  echo "== [dev] Verifying the dev loop points at the fork"
  local pkgs_origin
  pkgs_origin=$(git -C "$WORK/omarchy-pkgs" remote get-url origin)
  if [[ "$pkgs_origin" == *"${FORK_OWNER}/omarchy-pkgs"* ]]; then
    echo "   OK: PKGBUILDs come from the fork (origin $pkgs_origin)"
  else
    echo "   ! origin of omarchy-pkgs is NOT the fork: $pkgs_origin" >&2
    exit 1
  fi
  if [[ "$OMARCHY_UPSTREAM_URL" =~ ${FORK_OWNER}/omarchy(\.git)?$ ]]; then
    echo "   OK: OMARCHY_UPSTREAM_URL=$OMARCHY_UPSTREAM_URL"
  else
    echo "   ! OMARCHY_UPSTREAM_URL does not point at the fork: $OMARCHY_UPSTREAM_URL" >&2
    exit 1
  fi

  echo ""
  echo "== [dev] Done. Machine on the -dev line."
  echo "   Do NOT run 'omarchy update' here (it would install the official dev pair and"
  echo "   drop your local work). Consume/refresh with: omarchy refresh <component>."
}

dev_build_install() {
  local checkout="$WORK/omarchy-installer"
  local pkgbuilds_root="$WORK/omarchy-pkgs/pkgbuilds"
  local short_sha dirty new_pkgver build_dir pkg pkg_dir extra_args
  local q_output

  short_sha=$(git -C "$checkout" rev-parse --short HEAD)
  dirty=""
  [[ -n "$(git -C "$checkout" status --porcelain)" ]] && dirty=".dirty"
  new_pkgver="dev.${short_sha}${dirty}"

  build_dir=$(mktemp -d -t omarchy-dev-pkgtest.XXXXXX)
  echo "== [dev] Building dev pair ${new_pkgver} (build dir: $build_dir)"

  for pkg in omarchy-settings-dev omarchy-dev; do
    pkg_dir="$build_dir/$pkg"
    mkdir -p "$pkg_dir"
    cp -a "$pkgbuilds_root/$pkg/." "$pkg_dir/"
    remove_pkgver_function "$pkg_dir/PKGBUILD"
    sed -i "s/^pkgver=.*/pkgver=${new_pkgver}/" "$pkg_dir/PKGBUILD"
    extra_args=()
    [[ "$pkg" == "omarchy-dev" ]] && extra_args=(--nodeps)  # settings-dev not resolvable yet
    (
      cd "$pkg_dir"
      # OMARCHY_SRC set => source() is emptied and the local checkout is copied whole,
      # so the package is built from the working tree, not a throwaway pinned clone.
      OMARCHY_SRC="$checkout" makepkg -s --skipchecksums --noconfirm "${extra_args[@]}"
    )
  done

  local settings_zst engine_zst
  settings_zst=$(ls "$build_dir"/omarchy-settings-dev/*.pkg.tar.zst | head -1)
  engine_zst=$(ls "$build_dir"/omarchy-dev/*.pkg.tar.zst | head -1)

  echo "== [dev] Installing the pair TOGETHER (pkexec, --ask 4)"
  pkexec pacman -U --ask 4 --noconfirm --overwrite='*' "$settings_zst" "$engine_zst"
  rm -rf "$build_dir"

  echo ""
  echo "== [dev] Verifying the acceptance criterion (pacman -Q reports $new_pkgver)"
  q_output=$(pacman -Q omarchy-dev omarchy-settings-dev || true)
  echo "$q_output"
  if [[ $(grep -c "$new_pkgver" <<<"$q_output") -eq 2 ]]; then
    echo "   OK: installed pair matches the working-tree commit."
  else
    echo "   ! Installed version is NOT ${new_pkgver}." >&2
    echo "   Likely an 'omarchy update' ran and pacman 'upgraded' to the official dev pair" >&2
    echo "   (without your localizations). Recovery: re-run with --dev, and do NOT run" >&2
    echo "   'omarchy update' on the dev machine." >&2
    exit 1
  fi
}

# -------------------------------------------------------------------------------------
# Entry point
# -------------------------------------------------------------------------------------
if [[ "$MODE" == "child" ]]; then
  child_main
elif [[ "$MODE" == "dev" ]]; then
  dev_main
else
  echo "Unknown mode: $MODE" >&2
  exit 1
fi
