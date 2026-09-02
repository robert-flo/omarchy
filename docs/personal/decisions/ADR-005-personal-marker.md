# ADR-005 — The repo publishes ALL PKGBUILDs with `"personal": true`

- **Status:** Accepted
- **Milestone:** generalization (2026-09-01)

## Context

The personal repo started hard-coding the `omarchy`/`omarchy-settings` pair. The owner wants to add
own packages to the same `omarchy update` flow without touching the Action each time.

## Decision

- The Action collects **all** `pkgbuilds/*/` whose `.omarchy/package.json` has `"personal": true` and
  publishes exactly that set.
- The pair (pinned/lockstep) is still handled apart with its §5.3 rule (ADR-004); a generic package
  builds as-is from its PKGBUILD.
- Adding a future package: `pkgbuilds/<pkg>/PKGBUILD` + `.omarchy/package.json`
  (`source: local`, `release_ring: fast`, `"personal": true`), push to `personal`, re-dispatch.

## Consequences

- The `hola-mundo` PoC was the test bench (0.1.0-1 → 0.1.0-2).
- `omarchy update` **updates** packages already installed but does **not** install new ones: a
  personal extra is installed once per machine with `pacman -S <pkg>` (or added to
  `install/omarchy-base.packages` for mass onboarding).
