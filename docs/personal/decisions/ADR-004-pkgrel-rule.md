# ADR-004 — §5.3 rule: high base `pkgrel` + increment per release

- **Status:** Accepted (application auto-derived since the 2026-09-01 revision)

## Context

pacman chooses by `vercmp`: higher `pkgver` wins; at equal `pkgver`, higher `pkgrel` wins. The
pipeline decides "needs build" by **version difference**: a change with the SAME `pkgver-pkgrel`
would rebuild nothing. The pair's `pkgver` = the upstream base tag of the `personal` branch (pin
engine, lockstep). The official stable `pkgrel` is `1`.

## Decision

- Personal `pkgrel` = **high base `99`** when the `pkgver` is new, and **+1 per re-publication of the
  same `pkgver`** (99 → 100 → 101…).
- Application (2026-09-01 rev., now automatic): **auto-derived by the Action** — it reads the previously committed state of the
  pair and, after the pin engine (which resets `pkgrel` to 1), applies: new `pkgver` → `99`; same
  `pkgver` → last +1. Manual override `-f pkgrel=<n>` for emergencies.
- Affects only the `pinned` subset (the pair); a generic package uses its PKGBUILD's `pkgrel`.

## Consequences

- At equal `pkgver`, `vercmp` always wins for the personal (`x.y.z-99` > `x.y.z-1`).
- "Needs build" triggers on each re-publication because `pkgrel` changes.
- **Automatic recovery (lag):** if a machine ended up on the official pair, re-publishing the personal
  with `pkgver >=` and a growing `pkgrel` returns it at the next update.
- `pkgrel` used to be passed by hand (could repeat or err); today it is auto-derived.
