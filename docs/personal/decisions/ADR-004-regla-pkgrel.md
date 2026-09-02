# ADR-004 — Regla §5.3: `pkgrel` base alta + incremento por republicación

- **Estado:** Aceptada (mecánica de aplicación autoderivada por la revisión L8, 2026-09-01)

## Contexto

pacman elige por `vercmp`: gana el `pkgver` más alto; a `pkgver` igual, el `pkgrel` más alto. El
pipeline decide "needs build" por **diferencia de versión**: un cambio con el MISMO `pkgver-pkgrel` no
reconstruiría nada. El `pkgver` del par personal = el tag upstream base de la rama `personal` (pin
engine, lockstep). El `pkgrel` oficial de stable es `1`.

## Decisión

- `pkgrel` personal = **base alta `99`** cuando el `pkgver` es nuevo, e **incremento +1 por cada
  republicación del mismo `pkgver`** (99 → 100 → 101…).
- Aplicación (L8): **autoderivada por la Action** — lee el estado previo commitado del par y, tras el
  pin engine (que resetea `pkgrel` a 1), aplica `pkgver` nuevo → `99`; mismo `pkgver` → última +1.
  Override manual `-f pkgrel=<n>` para emergencias.
- Solo afecta al subconjunto `pinned` (el par); un genérico usa el `pkgrel` de su PKGBUILD.

## Consecuencias

- A `pkgver` igual, `vercmp` gana siempre el personal (`4.0.2-99` > `4.0.2-1`).
- "Needs build" se dispara en cada republicación porque cambia `pkgrel`.
- **Recuperación automática (lag):** si una máquina quedó en el par oficial, republicar el personal
  con `pkgver >=` y `pkgrel` creciente la devuelve en el próximo update.
- Antes el `pkgrel` se pasaba a mano (podía repetirse o errar); hoy es autoderivado.
