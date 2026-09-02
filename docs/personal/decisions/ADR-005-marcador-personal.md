# ADR-005 — La repo publica TODOS los PKGBUILD con `"personal": true`

- **Estado:** Aceptada
- **Hito:** generalización (8ª parte)

## Contexto

El repo personal empezó hardcodeando el par `omarchy`/`omarchy-settings`. El dueño quiere añadir
paquetes propios al mismo flujo de `omarchy update` sin tocar la Action cada vez.

## Decisión

- La Action recolecta **todos** los `pkgbuilds/*/` cuyo `.omarchy/package.json` tenga
  `"personal": true` y publica exactamente ese conjunto.
- El par (pinned/lockstep) sigue tratándose aparte con su regla §5.3 (ADR-004); un genérico buildea
  tal cual su PKGBUILD.
- Añadir un paquete futuro: `pkgbuilds/<pkg>/PKGBUILD` + `.omarchy/package.json`
  (`source: local`, `release_ring: fast`, `"personal": true`), push a `personal`, re-dispatch.

## Consecuencias

- PoC `hola-mundo` fue el banco de pruebas (0.1.0-1 → 0.1.0-2).
- `omarchy update` **actualiza** paquetes ya instalados pero **no instala** nuevos: un extra personal
  se instala una vez por máquina con `pacman -S <pkg>` (o se añade a `install/omarchy-base.packages`
  para onboarding masivo).
