# Onboarding — install and maintain a new machine

How to put any machine (x86_64, installed with the official stable Omarchy ISO from omarchy.org) onto
your **personal system**. Done once per machine.

## Before you start

You need the personal repository's public key: `keys/omarchy-personal-repo.pub.asc` (the private key
never leaves the project). The current pair version is read from the **State** table in
[`README.md`](README.md) — `<CURRENT_PAR>`.

## Choose your path: `child` or `dev`

There are **exactly two** kinds of machine (see the two-scenario model in
[`SKILL.md`](../../agents/skills/personal-fork/SKILL.md)); decide which this one is before doing
anything:

| Kind | You run | Delivered by | Maintains itself with |
|---|---|---|---|
| **child** | `omarchy update` once, after the ISO | the **published package** (no local source) | `omarchy update` |
| **dev** | builds from the **local checkout** | the **local** `-dev` pair | refresh commands (**not** `omarchy update`) |

- **child** — every machine except the ones you build on. It only *receives*. This is the default and
  the reliable one.
- **dev** — the machine(s) where you edit the fork. It deliberately runs ahead of the published pair.

> **Which route do you want?** [Automatic with the script](#automatic-with-the-script) (one command,
> recommended) or the [manual steps](#the-steps) (same flow, by hand, for a child).

---

## Automatic with the script

The canonical way is one script, [`bootstrap-omarchy-machine.sh`](machine-bootstrap/bootstrap-omarchy-machine.sh),
which you fetch from the fork's raw source and run in the mode that matches the machine (`--child` is
the default; `--dev` builds the local pair). Details, flags and troubleshooting are in
[`machine-bootstrap/README.md`](machine-bootstrap/README.md).

```bash
# fetch the script (public key is fetched from the fork automatically)
curl -fsSL -o bootstrap-omarchy-machine.sh \
  https://raw.githubusercontent.com/robert-flo/omarchy/personal/docs/personal/machine-bootstrap/bootstrap-omarchy-machine.sh
chmod +x bootstrap-omarchy-machine.sh

./bootstrap-omarchy-machine.sh --child          # a machine that only receives (default mode)
./bootstrap-omarchy-machine.sh --dev            # the build machine: clone layout + install -dev pair
./bootstrap-omarchy-machine.sh --dev --no-install   # dev: clone/layout only, don't build
```

> **dev machines must NOT run `omarchy update`.** The official repo also publishes a `-dev` pair
> versioned with git-describe of quattro, and that version beats our local `dev.<sha>` by `vercmp` — so
> `omarchy update` would "upgrade" to the official dev pair and drop all local work. If that happens,
> re-run `--dev` (the script detects the mismatch and says so).

If you prefer to understand what the script does instead of trusting it blind, read the manual steps
below — they are the exact `--child` flow.

---

## The steps

```bash
# 1) Trust the personal repo key on this machine (once, as root)
sudo pacman-key --add /path/to/omarchy-personal-repo.pub.asc
sudo pacman-key --lsign-key <GPG_KEY_ID>

# 2) Install the personal pair the first time (no repo configured yet)
#    Download from the browser (or curl):
#    <REPO_URL>/omarchy-<CURRENT_PAR>-any.pkg.tar.zst
#    …and its .sig (same name + .sig), then install BOTH at once (same version, mandatory):
sudo pacman -U omarchy-<CURRENT_PAR>-any.pkg.tar.zst omarchy-settings-<CURRENT_PAR>-any.pkg.tar.zst
#    The .sig next to the .pkg.tar.zst is verified automatically by pacman (Good signature from
#    <GPG_KEY_ID>); it does not need to be passed as an argument.

# 3) Write the personal system's pacman.conf (already has the personal repo BEFORE the official one)
omarchy refresh pacman

# 4) Full update: convergence of packages, migrations and hooks
omarchy update

# 5) Materialize configs, launchers and lazy first-use stubs into THIS user.
#    `omarchy update` installs the pair but does NOT re-provision an existing user's $HOME
#    (gated by the finalize-user marker). Run this explicitly: it is what writes the
#    ~/.local/bin/* stubs and refreshes the launcher menu. Idempotent.
omarchy provision user --force

# 6) Reconcile the package list with the personal system's
omarchy reinstall pkgs

# 7) Materialize the personal system's configs onto your user (if a user is already active):
omarchy reinstall-configs
```

> Steps 1–6 are exactly what `bootstrap-omarchy-machine.sh --child` automates (see
> [Automatic with the script](#automatic-with-the-script)); the steps below document the same flow by
> hand for reference.

> **Removed home-launcher bootstrap (PoC) + lazy on-first-use:** the early-stage
> `omarchy-personal-bootstrap-launchers` PoC has been **removed**; its logic is fully absorbed into
> canonical rows (system packages → `omarchy-base.packages`; CLIs → `install/user/mise.sh`; heavy/AUR
> tools → lazy first-use stubs in `install/user/launchers.sh`; openclaw gateway →
> `omarchy-install-service-openclaw`; Hermes Web shim → `omarchy-install-hermes-cli`; `~/src` →
> `install/user/mise-work.sh`). Everything travels via `omarchy update` → `omarchy refresh
> applications`. There is no need to run any bootstrap script on new machines; the launchers install
> their own tools on first use.

**Lazy on-first-use (the owner's chosen model, like `~/.local/bin/ori`):** tools are never fetched at
provision time. The pair only writes idle launchers (`~/.local/bin/<cmd>` stubs); the first time you
actually launch a launcher, its stub installs the tool then runs it. Covers all first-use classes:

- **mise-backed CLIs** (`qwen`, `openclaude`, `zero`, `cmd`, `openclaw`, …) → `omarchy-mise-install`
  stub in `install/user/mise.sh`.
- **Heavy official GUI tools** (`mimo`, `opencode-desktop`) → self-contained stubs
  (`bin/omarchy-install-mimo` / `omarchy-install-opencode-desktop`) that download on first use.
- **AUR packages** (`microsoft-edge-stable-bin`, `lyricify`, `spicetify-cli`) →
  `bin/omarchy-install-aur` stub: on first use it runs `omarchy-pkg-aur-add <pkg>` (the canonical AUR
  wrapper), then `exec /usr/bin/<bin>` by absolute path.
- **Systemd user services** (`openclaw-gateway`) are the deliberate exception: they are installed with
  `omarchy install service openclaw`, never from a first-use stub (a daemon should not spring to life
  from a launcher). Its `ExecStart` is generated per-machine by `openclaw gateway install` because it
  must point at that machine's mise node runtime path.

> **Validation note (non-destructive dry-run, 2026-09-02):** the onboarding contract was vetted with a
> non-destructive dry-run on the dev machine (no VM, no reformat). It exercised: command registration
> (all four `omarchy install …` resolvers), stub writing into a throwaway `$HOME`, a simulated
> first-use of an AUR stub (it invoked the canonical AUR installer on demand) and the fast-path (no
> re-download when the tool is already present), and confirmed every `.desktop` `Exec=` binary
> resolves either via a stub (`mimo`, `opencode-desktop`, `microsoft-edge-stable`, `lyricify`,
> `spicetify`) or via the mise lazy flow (`openclaw`, `openclaude`, `cmd`, `zero`, `qwen`). To validate
> the full end-to-end with the published pair, use a VM on the official stable ISO — see
> [`cadence.md`](cadence.md) / [`recipes.md`](recipes.md) for the publish steps.

## Verify it worked

```bash
pacman -Q omarchy omarchy-settings      # → omarchy <CURRENT_PAR> (same version for both)
omarchy-debug --no-sudo --print         # no errors
```

Also, in `/etc/pacman.conf` you must see the `[omarchy-personal]` section **before** `[omarchy]`.

## If step 4 shows "Something went wrong"

This is a known quirk of the non-interactive update (see the next section). In a normal terminal it
will simply ask for your password and continue. Nothing is broken on the system.

## Day-to-day use

- **Maintain:** `omarchy update` (updates packages + AUR + mise; runs migrations and hooks). It
  updates what is installed; it does **not** install new packages. If an update ships **new launchers
  or first-use stubs**, follow it with `omarchy provision user --force` to materialize them into the
  current user (update alone does not).
- **Install a new personal package:** `sudo pacman -S <pkg>` (once; then it maintains itself).
- **Reconcile the set:** `omarchy reinstall pkgs`.
- **Re-seed configs (nuclear):** `omarchy reinstall-configs`; finer: `omarchy refresh shell`,
  `omarchy refresh config <relpath>`.
- **Verify:** `pacman -Q omarchy omarchy-settings`, `omarchy version`, `pacman -Qn`.

## Common problems

- **"I lost my personalization after `omarchy update`."** Symptom: the pair is no longer the personal
  version. On normal machines this should not happen (version/position priority + guard §5.3). If it
  happens on a dev machine with the local `-dev` pair, it is a separate case.
- **`omarchy update -y` aborts with "Something went wrong"** (session without a terminal). A `sudo`
  quirk (`sudo -v` under a pty asks for a password and expires after ~5 min). In a normal terminal it
  is fine. If fully unattended is needed, a temporary `Defaults:USER !authenticate` drop-in in sudoers
  works.
- **A new web app does not appear in the launcher.** Rebuilding the package does NOT touch the current
  user; refresh: `omarchy refresh applications`.
