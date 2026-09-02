# ADR-002 — The personal repo publishes ONLY the stable channel

- **Status:** Accepted
- **Milestone:** Stage 3

## Context

Upstream publishes three channels (`edge`, `rc`, `stable`) and a promotion walk between them. The
personal repo only needs to serve machines running the stable channel.

## Decision

- Publish only `stable` in `robert-flo/omarchy-personal-repo`; do not replicate `edge`/`rc` or the
  promotion walk.
- Machines need nothing more: their `[omarchy-personal]` is listed BEFORE `[omarchy]` (ADR-003).

## Consequences

- The §5.3 guard compares against `pkgs.omarchy.org/stable`.
- Any future edge/rc personal need is a new ADR.
