# Cadencia — sincronizar el fork con upstream y republicar

Rutina para mantener el fork al día con `upstream/quattro` y republicar, para que la personalización
nunca se quede atrás del estable oficial (regla `pkgrel` / guard §5.3). Se sigue **tras cada release
upstream** (tag `vX.Y.Z` en `quattro`) o cuando `omarchy update` en la máquina dev lo anuncie.

## Sync + republicación

1. En `~/Work/omarchy/omarchy-installer` (rama `personal`):

   ```bash
   git fetch upstream
   git rebase upstream/quattro      # sobre la rama personal
   ```

2. Resolver conflictos si los hubiera (idealmente nunca: las personalizaciones deben tocar archivos
   que upstream apenas mueve; si uno choca, revisar si tu cambio conviene upstream).
3. Correr `./test/all`, `git push origin personal` y **correr la Action de release** (W7) con el
   `pkgver` del tag recién rebasado (pkgrel autoderivado).
4. En cada máquina: `omarchy update` (y `omarchy reinstall pkgs` si cambió la lista de paquetes).

```bash
# en ~/Work/omarchy/omarchy-installer
git fetch upstream && git rebase upstream/quattro
git push origin personal
# en ~/Work/omarchy/omarchy-pkgs
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v<tag-upstream>
# opcional: ensayo sin tocar nada
#   ... -f version=v<tag> -f dry_run=true
```

## Checklist post-sync

1. [ ] Rebase lineal sin conflictos (`git rebase upstream/quattro`).
2. [ ] `git push origin personal`.
3. [ ] Dispatch con `--ref personal` y el `pkgver` nuevo.
4. [ ] Run verde y "Validar publicación" OK (Pages sirve el par nuevo + alias de sección + `.sig`).
5. [ ] En la máquina dev: `omarchy update -y`; `pacman -Q omarchy omarchy-settings` → versión personal.
6. [ ] `sync-check.yml` no abre nuevo issue `[Cadencia]` (o se cierra solo al día siguiente).

## Verificación mínima tras publicar

```bash
curl -s https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/omarchy.db.tar.zst | bsdtar -xOf - omarchy/desc
pacman -Q omarchy omarchy-settings   # en una máquina
```

## Vigilancia automática

- `sync-check.yml` (cron diario 06:30 UTC) compara el tag upstream con el pin y abre/cierra un issue
  `[Cadencia]` si upstream publica y el pin se queda atrás. Está registrado en `personal` (fuente) y
  `master` (para que GitHub lo programe).
- El paso "Guard §5.3" de la Action aborta si el par quedara por detrás del estable oficial.
- El paso "Validar publicación en GitHub Pages" tras cada push verifica la entrega (margen 60×20 s).

## Conflictos de rebase

Ideales: no deberían existir si tus cambios personales tocan archivos que upstream apenas mueve.
Si un archivo tuyo choca con upstream, pregunta si tu cambio conviene upstream (está en el espíritu
del proyecto contribuir de vuelta) y resuelve el conflicto a mano como cualquier rebase.

## Status / lag

Si alguna vez la maquinaria falla o el fork queda atrás, ver **`runbook.md`** (F4 — lag de cadencia).
Regla de oro: **roll-forward**, no rollback (el repo publicado se poda a la última versión).
