# Recetas W1–W10 — flujos exactos de personalización

Ciclo dev iterativo: **editar fuente → `omarchy dev pkg-test` → refresh del componente → validar**.
El ciclo de publicación es W7.

> **Entrada obligatoria:** antes de elegir una W, ubicar el cambio en la **Matriz de Decisión**
> (ver [`SKILL.md`](../../agents/skills/personal-fork/SKILL.md)). La W correcta se sigue de la fila;
> nunca al revés.

---

## W1 — Agregar una webapp

1. Crear `applications/<Nombre>.desktop`:

   ```ini
   [Desktop Entry]
   Version=1.0
   Name=<Nombre>
   Exec=omarchy-launch-webapp https://<dominio>/
   Terminal=false
   Type=Application
   Icon=<icon_id>
   StartupNotify=true
   ```

   - `Exec` puede ser `omarchy-launch-webapp <url>` o un handler propio.
   - Si maneja un esquema (mailto, zoommtg…): `MimeType=x-scheme-handler/<esquema>` y, si aplica,
     `xdg-mime default <Nombre>.desktop <esquema>`.
2. Icono en `applications/icons/<Nombre>.png` (o `.svg`). `<icon_id>` = nombre **minúsculas** +
   no-alfanuméricos → `-` (`Google Photos.png` → `google-photos`). El `Icon=` del `.desktop` debe
   usar ese `icon_id`.
3. Ciclo dev: `omarchy dev pkg-test omarchy-settings` → `omarchy-refresh-applications`.
4. **Validar:** aparece en el launcher; abre en ventana webapp frameless.

> OJO (error común): reconstruir el paquete NO materializa el `.desktop` en un usuario existente;
> hay que correr `omarchy-refresh-applications`.

Reglas de `Exec`:
- `omarchy-launch-webapp <URL>`; si la URL lleva caracteres reservados (`?&#`…), entre comillas
  dobles. Para launchers que necesitan shell (`cd "$HOME/src" && exec …`) el canon es
  `sh -c "…\"\$HOME…\"…"` (dobles + `\"` y `\$`).

---

## W2 — Agregar un comando `omarchy-*`

1. Crear `bin/omarchy-<grupo>-<verbo>` con shebang `#!/bin/bash` y metadatos `# omarchy:summary=`,
   `# omarchy:args=`, etc. Seguir `agents/skills/command-metadata.md` y `AGENTS.md`.
2. Si es un grupo nuevo, registrarlo en `GROUP_DESCRIPTIONS` de `bin/omarchy`.
3. PKGBUILD de `omarchy` captura `bin/*` por globo → **no tocar PKGBUILD**. Rebuild:
   `omarchy dev pkg-test omarchy`.
4. Test de CLI si corresponde (`test/cli`, `test/shell.d/base-test.sh`); correr `./test/all` antes
   de publicar.
5. **Validar:** `omarchy <grupo> <verbo> --help`; `pacman -Ql omarchy-dev | grep mi-comando`.

---

## W3 — Ejecutables en `~/.local/bin`

- **Caso A (recomendado por defecto):** si encaja como comando del sistema → publicar como
  `bin/omarchy-*` (W2). Va a `/usr/bin`, empaquetado solo, contribuible directo.
- **Caso B — script de usuario que debe vivir en `~/.local/bin`:**
  1. Ponerlo en `default/local-bin/<nombre>` (el `env-bootstrap` ya agrega `~/.local/bin` al PATH).
  2. En el PKGBUILD de `omarchy-settings`, por archivo:
     `install -Dm755 default/local-bin/<nombre> "$pkgdir/etc/skel/.local/bin/<nombre>"`.
  3. Usuarios nuevos lo reciben al crearse; existentes con `omarchy reinstall-configs`.
  4. **Validar:** el comando resuelve desde el shell en un usuario nuevo (o tras `reinstall-configs`).

Alternativa dev (sin rebuild): `omarchy dev link` y copiar a `~/.local/bin` a mano mientras se itera;
la fuente de verdad sigue siendo `default/local-bin/`.

---

## W4 — Modificar configs de usuario (`~/.config`)

1. El archivo vive en `config/<app>/<archivo>` del fork (espeja `~/.config`), p. ej.
   `config/kitty/kitty.conf`.
2. `omarchy-settings` los siembra a `/etc/skel/.config` (nuevos) y `/usr/share/omarchy/config` (resync).
3. Aplicar a un usuario existente: `omarchy refresh config <relpath>` (p. ej. `kitty/kitty.conf`),
   `omarchy refresh shell`, `omarchy refresh hyprland`, etc. Cada refresh hace backup antes de copiar.
4. Dev: `omarchy dev link` deja `$OMARCHY_PATH` apuntando al checkout, así los refresh leen del fork.
5. **Validar:** para hypr `hyprctl configerrors`; reabrir el bar para `shell.json` (hot-reload).

---

## W5 — Agregar/modificar un tema

1. Stock (todas las máquinas): `themes/<nombre>/` con `colors.toml` y, si usa colores temáticos en
   templates, `default/themed/*.tpl`. El paquete `omarchy` shippea `themes/` → rebuild
   `omarchy dev pkg-test omarchy`.
2. Aplicar con `omarchy theme set <nombre>` (ver `docs/theming.md`).
3. Tema personal no repartible: `~/.config/omarchy/themes/<nombre>/` (fuera del fork) — pero la norma
   es **en el fork** (máquinas idénticas).
4. **Validar:** `omarchy theme set` sin errores y el esquema visual cambia.

---

## W6 — Set de paquetes del sistema (máquinas idénticas)

1. Agregar/remover en `install/omarchy-base.packages` (set base) y/o
   `install/omarchy-other.packages`.
2. ISO nueva pacstraps esas listas. Para máquinas existentes: `omarchy reinstall pkgs` instala
   `--needed` TODO lo listado y alinea versiones. Un paquete solo desinstalado: `omarchy pkg drop`,
   pero si sigue en `base.packages` volverá — decidir si además sale de la lista del fork.
3. Si el paquete no está en Arch/AUR y quiere entrar al flujo oficial: seguir `omarchy-pkgs`
   (`bin/add-package ... --local`), no inventar un repo aparte.
4. **Validar:** `omarchy update` + `omarchy reinstall pkgs` y comparar `pacman -Qq` entre máquinas.

---

## W7 — Publicar paquetes personales (la pieza central)

Estado: **implementada, verificada y generalizada** (2026-09-01). La Action ya no hardcodea el par:
publica **todos** los PKGBUILD con `"personal": true`. Detalle completo en
[`pipeline-publicacion.md`](pipeline-publicacion.md). Aquí el resumen:

Precondiciones verificadas: clave GPG dedicada (`D5E75EAC51A44715`, sin passphrase); secrets
`GPG_PRIVATE_KEY`, `GPG_PASSPHRASE="unused"` y `SSH_DEPLOY_KEY` (deploy key write a
`omarchy-personal-repo`) en `robert-flo/omarchy-pkgs`. El workflow se commitea en `personal` **y una
copia de registro en `master`**.

> **CRÍTICO — dispatch SIEMPRE con `--ref personal`.** La Action tiene un guard fail-fast: si
> `github.ref != refs/heads/personal` aborta antes de tocar nada. Sin `--ref`, GitHub usa el
> workflow de `master` (copia de registro) y el run republica mal (incidente histórico `33582420572`).

**Trigger:**

```bash
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v4.0.2
```

Variantes:
- Ensayo sin publicar nada: añade `-f dry_run=true`.
- Override de emergencia del pkgrel del par: `-f pkgrel=<n>`.
- Dos dispatches simultáneos entran en cola (grupo de concurrency), nunca corren intercalados.

**Ciclo de vida de un paquete personal:** `omarchy update` hace `pacman -Syu` (+AUR + mise):
**actualiza** los paquetes ya instalados, **NO instala** nuevos. Un paquete personal nuevo se instala
**una vez** en cada máquina con `pacman -S <pkg>`; a partir de ahí `omarchy update` lo mantiene. Si
debe estar en TODAS las máquinas desde el onboarding, añadirlo a `install/omarchy-base.packages` del
fork fuente.

---

## W8 — Aplicar personalizaciones a una máquina nueva (onboarding)

Máquina x86_64, instalada con la ISO oficial estable de omarchy.org. Detalle en
[`onboarding.md`](onboarding.md). Resumen:

1. **Trust de la clave personal:** `pacman-key --add <clave>.asc` + `pacman-key --lsign-key D5E75EAC51A44715`.
2. **Bootstrap del par personal** (primer arranque): descargar el par `.pkg.tar.zst` (+ `.sig`) del
   GitHub Pages y `sudo pacman -U` de ambos juntos (misma versión).
3. **`omarchy refresh pacman`** → copia el `pacman.conf` y mirrorlist del fork (ya con
   `[omarchy-personal]` ANTES de `[omarchy]`).
4. **`omarchy update`** → convergencia (paquetes + migraciones + hooks).
5. **`omarchy reinstall pkgs`** → reconcilia el set con `install/omarchy-base.packages`.
6. **`omarchy reinstall-configs`** (opcional; antes de crear usuarios) → materializa `/etc/skel`.
7. **Validar:** `pacman -Q omarchy omarchy-settings` reportan la versión personal; la webapp aparece
   en el launcher.

> Los pasos 1–4 son repetibles/automatizables como comando `bin/omarchy-install-*` (forma de los
> installers existentes), NO como script suelto.

---

## W9 — Sincronizar el fork con upstream y republicar

Cadencia: tras cada release upstream (tag `vX.Y.Z` en `quattro`) o cuando `omarchy update` en la
máquina dev lo anuncie. Detalle en [`cadencia.md`](cadencia.md). Resumen:

1. En `~/Work/omarchy/omarchy-installer` (rama personal):
   ```bash
   git fetch upstream
   git rebase upstream/quattro
   ```
2. Resolver conflictos si los hubiera (idealmente nunca; si uno choca, revisar si conviene upstream).
3. `./test/all`, `git push origin personal` y **correr la Action** (W7) con el `pkgver` del tag
   recién rebasado.
4. En cada máquina: `omarchy update` (y `omarchy reinstall pkgs` si cambió la lista).

---

## W10 — Migraciones (cambios únicos en máquinas existentes)

Cuando una personalización debe tocar un **estado existente** (no solo archivos de fuente), el
mecanismo upstream son las migraciones: `migrations/<unix-timestamp>.sh`, corren por usuario vía
`omarchy-migrate` (marcadores en `~/.local/state/omarchy/migrations/`). Seguir
`agents/skills/migrations.md`. Reglas: idempotentes, corren como el usuario, trabajo privilegiado por
helper, una sola reparación por archivo. Se vinculan a versiones de paquete: una máquina que
actualiza del par viejo al nuevo corre las migraciones nuevas.
