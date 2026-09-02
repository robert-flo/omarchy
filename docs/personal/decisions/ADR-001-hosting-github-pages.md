# ADR-001 — Hosting del repo pacman personal: GitHub Pages + GitHub Actions

- **Estado:** Aceptada
- **Hito:** Etapa 3 (4ª parte del WORKLOG pasado)

## Contexto

El sistema personal necesita un repo pacman propio que las máquinas consuman por el flujo normal
`omarchy update`. Queremos build host CI (no el portátil) y entrega estática con HTTPS, sin
infraestructura propia (sin VPS, sin rclone/S3, sin servidor de archivos propio).

## Decisión

- Repo publicador: `robert-flo/omarchy-personal-repo`, branch `gh-pages` (solo `stable`).
- Build host: GitHub Actions en `robert-flo/omarchy-pkgs` replicando el pipeline de `omarchy-pkgs`
  (`build → sign → promote → update → clean`).
- **Única desviación operativa** vs upstream: el entregable final es un commit+push a `gh-pages` en
  vez de `sync-repo`/rclone (Pages no acepta push por SSH/rclone).
- El runner necesita escribir en `omarchy-personal-repo` → deploy key SSH (`SSH_DEPLOY_KEY`, write)
  en vez del `GITHUB_TOKEN` del huésped (que no escribe en otro repo).

## Consecuencias

- Los builds dependen de runners de GitHub; sin runner no hay release.
- Publicar = girar el workflow; hay `dry_run=true` para ensayar sin publicar.
- Pages sirve los `.pkg.tar.zst` como archivo estático plano; no hay symlinks (los `omarchy.db`/
  `.files` se resuelven a copias reales), se firman db y artefactos.
- URL canónica: `https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/…`.

## Alternativas descartadas

- Hosting en la máquina dev / NAS doméstico: sin disponibilidad garantizada.
- OCI (GHCR) como repo pacman: no es el mecanismo de upstream.
