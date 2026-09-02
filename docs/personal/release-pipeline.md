# Release pipeline — the `release-personal.yml` Action

How the **GitHub Action** builds and publishes the personal pacman repo on GitHub Pages, replicating
upstream's pipeline end to end. This is the heart of delivery to machines: **the only distribution
trigger is `omarchy update`**, and the Action is what re-publishes the pair on every source change in
the fork.

## The model

- The Action lives in `robert-flo/omarchy-pkgs` (branch `personal`; a record copy on `master`).
- It replicates `bin/repo` from `omarchy-pkgs` (`build → sign → promote → update → clean`) running in CI.
- Only the final delivery layer differs: instead of `sync-repo`/rclone (Pages does not accept it), it
  does a **commit + push to the `gh-pages` branch** of `robert-flo/omarchy-personal-repo`.

## Steps

1. **Checkouts** (`actions/checkout@v4`): `omarchy@personal`→`./source`, `omarchy-pkgs@personal`→
   `./pkgs`, `omarchy-personal-repo@gh-pages`→`./repo` (with `ssh-key: ${{ secrets.SSH_DEPLOY_KEY }}`).
2. **Pin the pair in lockstep** inside `archlinux:base-devel` as **non-root**:
   `./bin/omarchy-pkgs release v<UPSTREAM_TAG> --commit <sha> --no-push --yes` by a `builder` user.
   The engine resets `pkgrel` to 1.
   - **`pkgrel` derived automatically:** the Action reads the previously committed state of the pair's
     PKGBUILD and applies — new `pkgver` → `99`; same `pkgver` → last released `+1`. Only the `pinned`
     subset (the pair); generic packages keep their PKGBUILD's. Override: `-f pkgrel=<n>`.
   - The pin commit and its push are gated by `dry_run`.
3. **Guard §5.3** before building: `vercmp` of the personal pair against the current official stable
   at `pkgs.omarchy.org/stable` (aborts if it falls behind).
4. **Collect the `personal: true` set** and **build** `--mirror stable`:
   - Fork DELTA: `pinned:true` packages do not build natively to `stable` by design; a temporary
     **LOCAL un-pin** (`pinned:false` via jq, not committed) is applied and stable is built directly,
     with deps resolved against `pkgs.omarchy.org/stable` (the fork's Dockerfile keeps that remote
     `[omarchy]` at `MIRROR=stable`).
5. **Sign** (1:1 with upstream).
6. **Promote, db and prune**: `promote`, then `update`, then `clean` (real `bin/repo` subcommands).
7. **Publish to `gh-pages`** (the only operational deviation): resolve db symlinks to real copies
   (`cp -L`), sign them (`*.sig`). **Section aliases:** also publish `omarchy-personal.db`/`.files`
   (+`.sig`) — pacman derives the db name from the section. `git add -A && git commit -m "publish:
   <v>"; git push origin gh-pages` (guard: skip if no changes).
8. **Validate** with `curl` at `<REPO_URL>/…`: walks all `PERSONAL_PKGS` and derives the
   `.pkg.tar.zst` name from the published tree (60×20 s margin).

## Fail-fast guard and concurrency

- **Fail-fast guard:** if `github.ref != refs/heads/personal`, it aborts at the first step (which is
  why the `master` copy is pure record). Dispatch ALWAYS with `--ref personal`.
- **Concurrency:** group `release-personal`; two simultaneous dispatches run in a queue, never
  interleaved.

## Shading on the machine (partial shadow)

- The fork ships `default/pacman/pacman-stable.conf` with `[omarchy-personal]` BEFORE `[omarchy]`.
  `omarchy refresh pacman` propagates it to any machine.
- pacman picks the **highest version**; at equal version, the repo **listed first**.
- The official mirror `pkgs.omarchy.org` keeps providing the rest of the ecosystem.

## The `pkgrel` rule (§5.3) — why the pair carries base 99

- The pair's `pkgver` = the upstream base tag of the `personal` branch (pin engine, lockstep).
- The official stable `pkgrel` is `1`. The personal one starts at `99` and grows `+1` per
  re-publication of the same `pkgver`. Thus `<CURRENT_PAR>` (personal) beats `x.y.z-1` (official) by
  `vercmp`, and each re-publication changes `pkgrel` (triggers "needs build").
- **Automatic recovery (lag):** if a machine ended up on the official pair, re-publishing the personal
  with `pkgver >=` and a growing `pkgrel` brings it back at the next update. The only real loss is the
  window between an official release and the personal re-publication.
- **Operational guard:** the Action aborts if `vercmp` of the personal pair falls behind official
  stable.

## Pair lockstep

`omarchy` depends on `omarchy-settings=${pkgver}` **exactly**. Never publish the pair at different
`pkgver`s. `bin/omarchy-pkgs release` is the pin engine that rewrites them in step (same
`_tag`/`_commit`/`pkgver`/`sha256sums`); in this flow the Action runs it (step 2).

## Keys and signing

- The personal repo uses its own key (`<GPG_KEY_ID>`); every package is signed (`.sig`), the db too.
- Machines: `pacman-key --add` + `--lsign-key` (W8 step 1 / onboarding).
- On `gh-pages`, deliver `*.db.tar.zst` as `*.db` and `*.files` (copies, not symlinks) and their
  signatures.

## Secrets

- Private GPG key ONLY in the `GPG_PRIVATE_KEY` secret; public key at
  `keys/omarchy-personal-repo.pub.asc`.
- Deploy key SSH (write to `omarchy-personal-repo`) in `SSH_DEPLOY_KEY`.
- **Never commit private keys** (the repo is public). Rotation/DR: ADR-006 + `runbook.md`.
