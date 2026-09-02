# ADR-001 — Hosting the personal pacman repo: GitHub Pages + GitHub Actions

- **Status:** Accepted
- **Milestone:** Stage 3

## Context

The personal system needs its own pacman repo that machines consume through the normal
`omarchy update` flow. We want CI as the build host (not the laptop) and static HTTPS delivery, with
no self-hosted infrastructure (no VPS, no rclone/S3, no own file server).

## Decision

- Publishing repo: `robert-flo/omarchy-personal-repo`, branch `gh-pages` (`stable` only).
- Build host: GitHub Actions in `robert-flo/omarchy-pkgs` replicating the `omarchy-pkgs` pipeline
  (`build → sign → promote → update → clean`).
- **Only operational deviation** vs upstream: the final deliverable is a commit+push to `gh-pages`
  instead of `sync-repo`/rclone (Pages accepts no SSH/rclone push).
- The runner needs write access to `omarchy-personal-repo` → deploy key SSH (`SSH_DEPLOY_KEY`, write)
  instead of the host's `GITHUB_TOKEN` (which cannot write to another repo).

## Consequences

- Builds depend on GitHub runners; without a runner there is no release.
- Publishing = turning the workflow; there is a `dry_run=true` to rehearse without publishing.
- Pages serves the `.pkg.tar.zst` as a flat static file; there are no symlinks (the `omarchy.db`/
  `.files` resolve to real copies), and db + artifacts are signed.
- Canonical URL: `https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/…`.

## Alternatives rejected

- Hosting on the dev machine / home NAS: no guaranteed availability.
- OCI (GHCR) as a pacman repo: not upstream's mechanism.
