# ADR-003 — Partial shadow: `[omarchy-personal]` before `[omarchy]`

- **Status:** Accepted
- **Milestone:** Stage 4

## Context

Personalizations travel as our own packages. The official mirror `pkgs.omarchy.org` remains the home
of the ecosystem; rebuilding everything ("build all local") makes no sense, and `pinned` packages do
not build to `stable`. Pacman semantics: at equal version, the repo listed first wins.

## Decision

- **Partial shadow**: on each machine, `[omarchy-personal]` is listed BEFORE `[omarchy]` in
  `/etc/pacman.conf`.
- Guaranteed by carrying it INSIDE the fork source (`default/pacman/pacman-stable.conf`), not by
  per-machine edits — so `omarchy refresh pacman` restores it on any machine.
- The official mirror keeps providing the rest.

## Consequences

- The pair and personal extras resolve from the personal repo when it has version >= the official one
  (§5.3 rule / ADR-004).
- If the personal pair falls behind official, `omarchy update` installs the official one and the
  personalization is lost (risk covered by the §5.3 guard and cadence monitoring).
- The section carries no own `SigLevel` → inherits `Required DatabaseOptional` → **trust the key
  first** before `omarchy refresh pacman`.
