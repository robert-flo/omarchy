# ADR-007 — Build environment: `archlinux:base-devel` rolling

- **Status:** Accepted with a declared risk (2026-09-01 revision)

## Context

The Action builds inside `docker run archlinux:base-devel` (a **rolling** image: the mutable tag tracks
the latest Arch). A fully reproducible build would require a digest pin
(`archlinux:base-devel@sha256:…`). Upstream builds the same way (rolling), and the personal repo only
serves `stable` with a very low rebuild cadence.

## Decision

- **Keep `archlinux:base-devel` rolling**, consciously and documented:
  - Each release rebuilds the whole published set; a digest pin would only give byte-for-byte
    determinism between two runs of the SAME commit, which is not a real case here (each
    re-publication changes `pkgrel` → already a different build).
  - Accepted risk: a base-devel update could change deps/behavior between two re-publications of the
    same `pkgver`. Real impact is low (one or two machines, same user).
- **Follow-up (non-blocking):** if installed for third parties or strict reproducibility is demanded,
  move to a documented digest pin in the workflow.

## Consequences

- Simplicity at the cost of no strict determinism (declared, not hidden).
- The §5.3 guard and post-publication validation cover functional safety.
