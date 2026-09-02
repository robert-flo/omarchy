# ADR-006 — GPG keys and deploy key: trust model, rotation and DR

- **Status:** Accepted (rotation/DR formalized in the 2026-09-01 revision)

## Context

The personal repo signs artifacts and the db (dedicated GPG key) and the Action writes to `gh-pages`
with a deploy key SSH. The project is **public**: the private key must NEVER appear in git, and you
must know what to do if it is lost or leaked.

## Decision

- **One dedicated GPG key** (`D5E75EAC51A44715`, no passphrase as it lives only in the CI runner as a
  secret).
  - Private ONLY in the `GPG_PRIVATE_KEY` secret of `omarchy-pkgs`.
  - Public at `keys/omarchy-personal-repo.pub.asc`.
- **Deploy key SSH** write to `omarchy-personal-repo` in the `SSH_DEPLOY_KEY` secret.
- Rotation/DR:
  1. Generate a new pair.
  2. Publish the new public key + update `keys/`.
  3. On ALL machines: `pacman-key --add` + `--lsign-key` of the new key BEFORE any update (what is
     already installed stays OK).
  4. Update the secret in `omarchy-pkgs` (never in git).
  5. Re-publish the pair (same `pkgver`, `pkgrel+1`).
  6. Revoke/void the previous one.
- Leak → immediate rotation (steps 1–6) as a minimum.

## Consequences

- With no dedicated private key in git, the only attack surface is the secret (controlled).
- "No passphrase" is an assumed cost of automated CI; the key only signs personal-repo packages and
  the deploy key only writes to `gh-pages` (minimal scope).
