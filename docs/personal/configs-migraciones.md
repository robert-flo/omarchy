# Configs de usuario y migraciones

Cómo materializar configs de `~/.config` y escribir migraciones para cambios únicos en máquinas
existentes. Corresponden a las filas **"Config de usuario"** y **"Provisioning / migración"** de la
Matriz de Decisión (`SKILL.md`).

## Configs de usuario (`config/<app>/`)

- El archivo vive en `config/<app>/<archivo>` del fork (espeja `~/.config`), p. ej.
  `config/kitty/kitty.conf` (ya existe en el fork).
- `omarchy-settings` los siembra a `/etc/skel/.config` (usuarios nuevos) y
  `/usr/share/omarchy/config` (fuente de resync de usuarios existentes).
- Aplicar a un usuario existente:
  - `omarchy refresh config <relpath>` — copia `$OMARCHY_PATH/config/<relpath>` a
    `~/.config/<relpath>` (con backup).
  - `omarchy refresh shell`, `omarchy refresh hyprland`, etc. — refrescan un componente completo.
  - `omarchy reinstall-configs` — re-copia `/etc/skel` completo sobre `$HOME` (**nuclear**, destructivo).
- En un install empaquetado `$OMARCHY_PATH=/usr/share/omarchy`.

> Regla clave: **`/etc/skel` solo siembra usuarios nuevos** (al `useradd`). Cambiar el paquete no
> toca a usuarios existentes; materializar con refresh o una migración.

### Wrappers de terceros (mise / npm / oficiales) en `~/.local/bin`

Estos NO son "configs" sino una fila propia de la Matriz (**"Wrapper de terceros"**):

- La lógica vive en `install/user/*.sh` (p. ej. `install/user/mise.sh`) + líneas
  `omarchy-mise-install <paquete> <cmd>` / `omarchy-install-*`.
- `omarchy refresh-applications` ejecuta `install/user/*.sh`, que escribe stubs idempotentes en
  `~/.local/bin/<cmd>`.
- Se empaquetan en `omarchy-settings`; viajan por `omarchy update`.

## Migraciones (`migrations/*.sh`)

Cuando una personalización debe tocar un **estado existente** (no solo archivos de fuente), el
mecanismo upstream son las migraciones:

- `migrations/<unix-timestamp>.sh`, corren por usuario vía `omarchy-migrate` (marcadores en
  `~/.local/state/omarchy/migrations/`).
- Seguir `agents/skills/migrations.md`.
- Reglas: **idempotentes**, corren como el usuario, trabajo privilegiado por helper, una sola
  reparación por archivo.
- Se vinculan a versiones de paquete: una máquina que actualiza del par viejo al nuevo corre las
  migraciones nuevas. Se empaqueta en `omarchy` (`migrations/` → `/usr/share/omarchy/migrations/`).

### Cuándo un refresh vs una migración

- **Refresh** (dev): aplica el cambio **ya mismo** a la máquina dev.
- **Migración**: hace que **cada máquina existente** lo aplique automáticamente en su próximo
  `omarchy update`. Distinción clave para el escenario MÁQUINAS: usuarios existentes no re-copian
  `$HOME` solos; o refresh manual (dev) o migración (una vez por máquina).

## Provisioning / scripts de setup

- `install/` contiene leafs de setup por usuario (`install/user/*.sh`) y por sistema
  (`install/hardware/`), orquestados por `omarchy-apply-system` / `omarchy-finalize-user`.
- Seguir `agents/skills/install-scripts.md`. Usar `$OMARCHY_INSTALL` / `$OMARCHY_PATH`, no rutas
  hardcodeadas. Leafs de `install/user/` pueden omitir shebang y son source/deployed.
