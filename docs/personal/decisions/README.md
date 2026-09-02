# docs/personal/decisions — Registro de decisiones (ADRs)

Decisiones de arquitectura/operación del fork, promovidas desde la bitácora pasada del scratchpad.
Formato aligerado: Contexto → Decisión → Consecuencias. Cada ADR tiene estado: **Aceptada**,
**Reemplazada**, **Deprecated**. Para cambiar una vigente, escribir un nuevo ADR que la reemplace
(nunca editar el histórico).

## Índice

| ADR | Estado |
|---|---|
| [ADR-001 — Hosting: GitHub Pages + GitHub Actions como build host](ADR-001-hosting-github-pages.md) | Aceptada |
| [ADR-002 — Solo canal stable](ADR-002-canal-estable-solo.md) | Aceptada |
| [ADR-003 — Sombreado parcial: `[omarchy-personal]` antes de `[omarchy]`](ADR-003-sombreado-parcial.md) | Aceptada |
| [ADR-004 — Regla `pkgrel` base alta + incremento por republicación](ADR-004-regla-pkgrel.md) | Aceptada (autoderivado L8) |
| [ADR-005 — Publicar todos los `personal: true`](ADR-005-marcador-personal.md) | Aceptada |
| [ADR-006 — Claves GPG y deploy key: confianza, rotación y DR](ADR-006-claves-gpg.md) | Aceptada |
| [ADR-007 — Entorno de build rolling vs pin a digest](ADR-007-entorno-build.md) | Aceptada (riesgo declarado) |
| [ADR-008 — Todo viaja vía `omarchy update` (arquitectura 13ª parte)](ADR-008-arquitectura.md) | Aceptada |
