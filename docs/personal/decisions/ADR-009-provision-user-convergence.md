# ADR-009 — `omarchy update` does not re-provision user state; `omarchy provision user --force` is the convergence step

- **Status:** Accepted (2026-09-02)

## Context

ADR-008 says everything travels via `omarchy update`. That is true for *files the pair ships*, but
validating the first real update on the dev machine (2026-09-02) surfaced a gap: after `omarchy update`
installed pair `4.0.2-104` and all four new `omarchy install …` resolvers registered, the **lazy
first-use stubs in `~/.local/bin` had not materialized**. The new launchers existed in the package but
were not reaching the user.

The cause is that the per-user finalization — which runs `install/user/all.sh` and through it
`install/user/launchers.sh` + `mise.sh` — is gated by the `finalize-user` marker and runs **once**. A
plain `omarchy update` does not clear it, so on an already-finalized user it does nothing to `$HOME`.

## Decision

- **`omarchy update` is and remains the only distribution trigger** (ADR-008) for *installing the
  pair and its files*.
- **Converging an existing user's `$HOME` after an update is a distinct, explicit step:**
  `omarchy provision user --force`. It re-runs the whole per-user finalization idempotently, so it
  materializes configs, launchers and any new lazy first-use stubs.
- It is safe and cheap to run unconditionally after an update, so both the `--child` machine bootstrap
  and the onboarding steps run it every time rather than trying to detect whether anything changed.
- The two scenarios remain exactly two (dev / child), and both bootstrap paths record this step so an
  agent/human reading them cannot miss it.

## Consequences

- The mental model is refined: **update installs files; provision materializes the user.** Both are
  needed to "land" a change that ships launchers/stubs.
- A new launcher still needs `omarchy refresh applications`-style user materialization; on an
  all-at-once update this is covered by `omarchy provision user --force` (which also refreshes
  applications).
- The `finalize-user` marker is not bypassed globally (good: normal updates stay fast); `--force` is
  the deliberate escape hatch.

## Sources

- Validation on the dev machine, 2026-09-02 (first real `omarchy update` + the missing stubs).
- `bin/omarchy-provision-user`, the `finalize-user` idempotency marker.
