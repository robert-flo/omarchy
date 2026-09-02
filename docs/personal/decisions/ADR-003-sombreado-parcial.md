# ADR-003 — Sombreado parcial: `[omarchy-personal]` antes de `[omarchy]`

- **Estado:** Aceptada
- **Hito:** Etapa 4 (5ª parte)

## Contexto

Las personalizaciones viajan como paquetes propios. El mirror oficial `pkgs.omarchy.org` sigue siendo
la casa del ecosistema; reconstruir todo ("build all local") no tiene sentido y los `pinned` no
buildean a `stable`. Semántica de pacman: a versión igual, gana el repo listado primero.

## Decisión

- **Sombreado parcial**: en cada máquina, `[omarchy-personal]` listado ANTES de `[omarchy]` en
  `/etc/pacman.conf`.
- Garantizarlo llevándolo DENTRO de la fuente del fork (`default/pacman/pacman-stable.conf`), no por
  edición per-máquina — así `omarchy refresh pacman` lo restaura en cualquier máquina.
- El mirror oficial sigue proveyendo el resto.

## Consecuencias

- El par y los extras personales se resuelven del repo personal cuando tiene versión >= del oficial
  (regla §5.3 / ADR-004).
- Si el par personal queda detrás del oficial, `omarchy update` instala el oficial y la
  personalización se pierde (riesgo cubierto por el guard §5.3 y la vigilancia de cadencia).
- La sección no lleva `SigLevel` propio → hereda `Required DatabaseOptional` → **confiar la clave
  antes** de `omarchy refresh pacman`.
