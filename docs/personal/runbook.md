# Runbook — failures and recovery of the personal fork

For the maintainer/agent. What to do **when something fails** in publishing, cadence or on a machine.
It also defines **preventive operations**.

## How publishing works (in 10 seconds)

- The `release-personal.yml` Action (in `robert-flo/omarchy-pkgs`) collects the `personal: true`
  PKGBUILDs, pins the lockstep pair to the base tag of `personal`, **derives `pkgrel` automatically**
  (same `pkgver` → last +1; new `pkgver` → 99), builds/signs/promotes/prunes and **commits to
  `gh-pages`**.
- Dispatch ALWAYS with `--ref personal`; from any other branch the Action aborts on its own
  (fail-fast guard).
- `dry_run=true` = full rehearsal **without publishing**.
- Concurrency: two dispatches run in a queue (never interleaved).

## Declared rollback strategy (READ BEFORE PANICKING)

**General rule: roll-forward, not rollback.** The published repo is pruned (`clean-repo`) to the
latest version; you **cannot "unpublish"** to an earlier one. If you publish something wrong, you
repair by publishing **another version on top** (same `pkgver` + incremented `pkgrel`, or a new
`pkgver`).

Point incidents (only if a MACHINE is broken and you cannot wait for the next `pkgrel`):

| Situation | Tool | When |
|---|---|---|
| Repair a single machine with a good artifact | `pacman -U` of the `.zst` + `.sig` from the `gh-pages` history | the machine does not converge after an update |
| Go back to an earlier public package | `git log gh-pages` → `git show <sha>:stable/x86_64/<pkg>.pkg.tar.zst` | real emergency |

## Known failure modes

### F1 — Dispatch without `--ref` (or from the wrong branch)
Harmless today: the fail-fast guard aborts if `github.ref != refs/heads/personal`.
- Symptom: the run ends red at the first step with "FORK ABORT".
- Response: re-dispatch with `--ref personal`. Nothing was published.

### F2 — Wrong `pkgrel`
Automatic today (the Action derives it). Manual override `-f pkgrel=<n>` only for emergencies.
- Error symptom: the pair does not "catch" the change on some machine (equal `pkgrel` = no rebuild).
- Response: re-dispatch without `-f pkgrel` (derives +1) and `omarchy update` on the machine.

### F3 — Bad publication (corrupt artifact/db/signature, or push to Pages failed)
- Symptom: the "Validate publication" step fails, or `pacman -Sy` on a machine gives a
  signature/data error.
- Response: 1) diagnose (`git -C <gh-pages clone> log --oneline -3`, `curl -fsSI`); 2) rehearse with
  `dry_run=true`; 3) if the rehearsal passed, re-publish (same `pkgver`, `pkgrel+1`); the section
  alias is regenerated on publish.

### F4 — Cadence lag (upstream publishes and the fork does not)
- Symptom: `sync-check.yml` opens a `[Cadence]` issue; or a machine's pair is the OFFICIAL one
  (→ the personalization disappears).
- Response (roll-forward): cadence ([`cadence.md`](cadence.md)) — rebase + re-publish with the new
  `pkgver`. Meanwhile, per machine: do not run `omarchy update` if you cannot re-publish within the
  day; if it already happened, re-publish and the next update returns to the personal pair (automatic
  §5.3 recovery).

### F5 — Transient network failures (archlinux.org TLS, gh rate limit)
- Response: if it failed during downloads, re-dispatch as-is (idempotent; the pin is already on
  `personal`). If it failed AFTER publishing, see F3.

### F6 — Loss / rotation of the GPG key or the deploy key
Practical summary (full DR in `decisions/ADR-006-keys.md`):
- **Loss of `GPG_PRIVATE_KEY`:** new key; publish the new `.asc` under `keys/`; on EACH machine
  `pacman-key --add` + `--lsign-key` of the new key BEFORE any update.
- **Loss of `SSH_DEPLOY_KEY`:** regenerate in `omarchy-personal-repo` (Settings → Deploy keys) and
  update the secret in `omarchy-pkgs`.
- **Fixed rule:** the private key only lives as a secret; never commit it. Suspected leak = immediate
  rotation.

### F7 — Per-machine rescue (return to personal without waiting for the next update)
1. Download the current pair `.pkg.tar.zst` (+`.sig`) from `<REPO_URL>/`.
2. `sudo pacman -U --noconfirm ./omarchy-<ver>-any.pkg.tar.zst ./omarchy-settings-<ver>-any.pkg.tar.zst`.
3. `sudo omarchy refresh pacman` (or verify section order) and `omarchy update -y`.

### F8 — `sudo -v` quirk on older / non-interactive `omarchy update`
`omarchy update` may ask for `sudo -v` before starting (fails in sessions without a TTY). Response:
run with a TTY, or `sudo -v` first, or a temporary `Defaults:USER !authenticate` drop-in. Not a repo
failure.

## Preventive operations

### Cadence
Rebase + re-dispatch (see `cadence.md`). When in doubt, first `-f dry_run=true`.

### Monitoring (what watches for you)
- `sync-check.yml` (daily cron 06:30 UTC): upstream tag vs. pin; opens/closes a `[Cadence]` issue.
- The Action's "Guard §5.3": aborts if the pair falls behind official stable.
- "Validate publication on GitHub Pages" after each push.

### Single source of state
`docs/personal/README.md` → **State** table. Do not invent versions.

## Links for an incident

| Resource | Use |
|---|---|
| `docs/personal/release-pipeline.md` | mechanics of publication + the `pkgrel` rule |
| `docs/personal/cadence.md` | rebase / re-publication |
| `docs/personal/onboarding.md` | per-machine rescue / onboarding |
| `docs/personal/decisions/` | ADRs (hosting, shading, pkgrel, keys, build) |
| `agents/skills/personal-fork/SKILL.md` | Decision Matrix (where each change goes) |
