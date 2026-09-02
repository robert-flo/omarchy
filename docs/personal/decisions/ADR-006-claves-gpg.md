# ADR-006 — Claves GPG y deploy key: modelo de confianza, rotación y DR

- **Estado:** Aceptada (rotación/DR formalizados en la revisión L8)

## Contexto

El repo personal firma artefactos y db (clave GPG dedicada) y la Action escribe en `gh-pages` con una
deploy key SSH. El proyecto es **público**: la clave privada NO debe aparecer jamás en git, y hay que
saber qué hacer si se pierde o se filtra.

## Decisión

- **Una clave GPG dedicada** (`D5E75EAC51A44715`, sin passphrase por estar solo en el CI runner como
  secret).
  - Privada SOLO en el secret `GPG_PRIVATE_KEY` de `omarchy-pkgs`.
  - Pública en `keys/omarchy-personal-repo.pub.asc`.
- **Deploy key SSH** write a `omarchy-personal-repo` en el secret `SSH_DEPLOY_KEY`.
- Rotación/DR:
  1. Generar par nuevo.
  2. Publicar la pública nueva + actualizar `keys/`.
  3. En TODAS las máquinas: `pacman-key --add` + `--lsign-key` de la clave nueva ANTES de cualquier
     update (lo que esté instalado sigue OK).
  4. Actualizar el secret en `omarchy-pkgs` (nunca en git).
  5. Re-publicar el par (mismo `pkgver`, `pkgrel+1`).
  6. Revocar/anular la anterior.
- Filtración → rotación inmediata (pasos 1–6) como mínimo.

## Consecuencias

- Sin clave dedicada privada en git, el único modo de ataque es el secret (controlado).
- "Sin passphrase" = coste asumido de CI automático; la clave solo firma paquetes del repo personal,
  la deploy key solo escribe en `gh-pages` (scope mínimo).
