# Onboarding — install and maintain a new machine

How to put any machine (x86_64, installed with the official stable Omarchy ISO from omarchy.org) onto
your **personal system**. Done once per machine.

## Before you start

You need the personal repository's public key: `keys/omarchy-personal-repo.pub.asc` (the private key
never leaves the project). The current pair version is read from the **State** table in
[`README.md`](README.md) — `<CURRENT_PAR>`.

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

# 5) Reconcile the package list with the personal system's
omarchy reinstall pkgs

# 6) Materialize the personal system's configs onto your user (if a user is already active):
omarchy reinstall-configs
```

> **Removed home-launcher bootstrap (PoC):** the early-stage `omarchy-personal-bootstrap-launchers`
> PoC has been **removed**; its logic is fully absorbed into canonical rows (system packages →
> `omarchy-base.packages`; CLIs → `install/user/mise.sh`; heavy/AUR tools → lazy first-use stubs in
> `install/user/launchers.sh`; openclaw gateway → `omarchy-install-service-openclaw`; Hermes Web shim →
> `omarchy-install-hermes-cli`; `~/src` → `install/user/mise-work.sh`). Everything travels via
> `omarchy update` → `omarchy refresh applications`. There is no need to run any bootstrap script on
> new machines; the launchers install their own tools on first use.

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
  updates what is installed; it does **not** install new packages.
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
