# docs/personal/decisions — Architecture decision records (ADRs)

Architecture/operations decisions for the fork, promoted from the previous notes log. Lightweight
format: Context → Decision → Consequences. Each ADR has a status: **Accepted**, **Superseded**,
**Deprecated**. To change an accepted one, write a new ADR that supersedes it (never edit history).

## Index

| ADR | Status |
|---|---|
| [ADR-001 — Hosting: GitHub Pages + GitHub Actions as build host](ADR-001-hosting-github-pages.md) | Accepted |
| [ADR-002 — Stable channel only](ADR-002-stable-channel.md) | Accepted |
| [ADR-003 — Partial shadow: `[omarchy-personal]` before `[omarchy]`](ADR-003-partial-shadow.md) | Accepted |
| [ADR-004 — `pkgrel`: high base + increment per release](ADR-004-pkgrel-rule.md) | Accepted (auto-derived) |
| [ADR-005 — Publish every `personal: true`](ADR-005-personal-marker.md) | Accepted |
| [ADR-006 — GPG keys and deploy key: trust, rotation, DR](ADR-006-keys.md) | Accepted |
| [ADR-007 — Rolling build environment, not a digest pin](ADR-007-build-environment.md) | Accepted (declared risk) |
| [ADR-008 — Everything travels via `omarchy update`](ADR-008-architecture.md) | Accepted |

## Known limitations and non-goals (read this first)

This is an active proof of concept (pre-1.0) maintained by a single person. The borders of what is
solved are stated explicitly rather than hidden:

- **Build reproducibility is best-effort, not strict.** The Action builds inside `archlinux:base-devel`
  (rolling). See ADR-007 for the accepted trade-off and the trigger to revisit.
- **Single maintainer + single signing key.** Recovery depends on the maintainer; the key exists
  only as a CI secret. See ADR-006 and `../runbook.md` (F6).
- **Sync/merge CI is human-triggered** for publication; only the cadence watcher (`sync-check.yml`)
  is automated. See `../cadence.md`.
- **Only the stable channel is published** (no edge/rc personal). See ADR-002.
- These are decisions, not gaps: each has a record above. Any change to them is a new ADR.
