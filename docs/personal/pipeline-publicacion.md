# Pipeline de publicación — la Action `release-personal.yml`

Cómo la **GitHub Action** construye y publica el repo pacman personal en GitHub Pages, replicando el
pipeline de upstream de punta a punta. Este es el corazón de la entrega a las máquinas: **el único
gatillo de distribución es `omarchy update`** y la Action es lo que re-pública el par con cada cambio
de fuente del fork.

## El modelo

- La Action vive en `robert-flo/omarchy-pkgs` (rama `personal`; copia de registro en `master`).
- Replica `bin/repo` de `omarchy-pkgs` (`build → sign → promote → update → clean`) corriendo en CI.
- Solo cambia la capa final de entrega: en vez de `sync-repo`/rclone (Pages no lo acepta), hace un
  **commit + push al branch `gh-pages`** de `robert-flo/omarchy-personal-repo`.

## Pasos

1. **Checkouts** (`actions/checkout@v4`): `omarchy@personal`→`./source`, `omarchy-pkgs@personal`→
   `./pkgs`, `omarchy-personal-repo@gh-pages`→`./repo` (con `ssh-key: ${{ secrets.SSH_DEPLOY_KEY }}`).
2. **Pin del par en lockstep** dentro de `archlinux:base-devel` como **no-root**:
   `./bin/omarchy-pkgs release <vX.Y.Z> --commit <sha> --no-push --yes` por un usuario `builder`.
   El engine resetea `pkgrel` a 1.
   - **`pkgrel` autoderivado:** la Action lee el estado previo commitado del PKGBUILD del par y
     aplica — `pkgver` nuevo → `99`; mismo `pkgver` → última republicada +1. Solo al subconjunto
     `pinned` (el par); los genéricos conservan el de su PKGBUILD. Override: `-f pkgrel=<n>`.
   - El commit del pin y su push están gateados por `dry_run`.
3. **Guard §5.3** antes de buildar: `vercmp` del par personal contra el oficial actual en
   `pkgs.omarchy.org/stable` (aborta si queda por detrás).
4. **Recolección del conjunto `personal: true`** y **build** `--mirror stable`:
   - Delta FORK clave: los `pinned:true` no buildan nativo a `stable` por diseño; se hace un
     **un-pin temporal LOCAL** (`pinned:false` vía jq, sin commitear) y se builda stable directo, con
     deps resueltas contra `pkgs.omarchy.org/stable` (el Dockerfile del fork mantiene ese `[omarchy]`
     remoto en `MIRROR=stable`).
5. **Firmar** (1:1 con upstream).
6. **Promover, db y poda**: `promote`, luego `update`, luego `clean` (subcomandos reales de `bin/repo`).
7. **Publicar a `gh-pages`** (única desviación operativa): resolver symlinks de la db a copias reales
   (`cp -L`), firmarlas (`*.sig`). **Aliases de sección:** publicar también `omarchy-personal.db`/
   `.files` (+`.sig`) — pacman deriva el nombre de db de la sección. `git add -A && git commit
   -m "publish: <v>"; git push origin gh-pages` (guard: saltar si no hay cambios).
8. **Validar** con `curl` a
   `https://<user>.github.io/omarchy-personal-repo/stable/x86_64/…`: recorre todos los
   `PERSONAL_PKGS` y deriva el nombre del `.pkg.tar.zst` desde el árbol publicado (margen 60×20 s).

## Guard fail-fast y concurrency

- **Guard fail-fast:** si `github.ref != refs/heads/personal`, aborta en el primer paso (por eso la
  copia en `master` es puro registro). Dispatch SIEMPRE con `--ref personal`.
- **Concurrency:** grupo `release-personal`; dos dispatches simultáneos corren en cola, nunca
  intercalados.

## Modelo de repos en la máquina (sombreado parcial)

- El fork shippea `default/pacman/pacman-stable.conf` con `[omarchy-personal]` **ANTES** de
  `[omarchy]`. `omarchy refresh pacman` lo propaga a cualquier máquina.
- pacman elige la **versión más alta**; a versión igual, el repo **listado primero**.
- El mirror oficial `pkgs.omarchy.org` sigue proveyendo el resto del ecosistema.

## Regla `pkgrel` (§5.3) — por qué el par lleva base 99

- El `pkgver` del par personal = tag upstream base de la rama `personal` (pin engine, lockstep).
- El `pkgrel` oficial de stable es `1`. El personal arranca en `99` y sube +1 por republicación del
  mismo `pkgver`. Así `4.0.2-103` (personal) gana a `4.0.2-1` (oficial) por `vercmp`, y cada
  republicación cambia `pkgrel` (dispara "needs build").
- **Recuperación automática (lag):** si una máquina quedó en el par oficial, republicar el personal
  con `pkgver >=` y `pkgrel` creciente la devuelve al próxima update. La única pérdida real es la
  ventana entre release oficial y republicación personal.
- **Guard operativo:** la Action aborta si `vercmp` del par personal queda por detrás del stable
  oficial.

## Lockstep del par

`omarchy` depende de `omarchy-settings=${pkgver}` **exacto**. Nunca publicar la pareja a distinto
`pkgver`. `bin/omarchy-pkgs release` es el pin engine que los reescribe acompasados (mismo
`_tag`/`_commit`/`pkgver`/`sha256sums`); en nuestro flujo lo corre la Action (paso 2).

## Claves y firma

- Repo personal usa la clave propia (`D5E75EAC51A44715`); cada paquete firmado (`.sig`), db firmada.
- Máquinas: `pacman-key --add` + `--lsign-key` (W8 paso 1 / onboarding).
- En gh-pages entregar `*.db.tar.zst` como `*.db` y `*.files` (copias, no symlinks) y sus firmas.

## Signing / secrets

- Clave GPG privada SOLO en el secret `GPG_PRIVATE_KEY`; público en `keys/omarchy-personal-repo.pub.asc`.
- Deploy key SSH (write a `omarchy-personal-repo`) en `SSH_DEPLOY_KEY`.
- **Nunca commitear claves privadas** (repo público).
