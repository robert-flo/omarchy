# Webapps y launchers

Cómo agregar, cambiar y quitar webapps del fork, y el estado de los launchers que las materializan
en las máquinas. Este documento debe leerse **a la luz de la fila "Webapp / launcher" de la Matriz de
Decisión** (`SKILL.md`) y de la nota de deprecación del POC de launchers.

## En Omarchy las webapps viven dentro del paquete

Las webapps **NO** son accesos que se agregan a mano al menú: son archivos `.desktop` que viajan
*dentro* del paquete `omarchy-settings`. En el repo del fork viven en:

- `applications/<Nombre>.desktop` — el lanzador.
- `applications/icons/<Nombre>.png` (o `.svg`) — el icono.

Al construir el paquete, el PKGBUILD captura por globo (cualquier `.desktop` o icono nuevo entra sin
tocar el PKGBUILD):

1. Copia los `.desktop` a `/usr/share/omarchy/applications/`; de ahí `omarchy-refresh-applications`
   los copia a `~/.local/share/applications/` (la carpeta que ve el launcher del usuario).
2. Convierte el icono con `magick` a los tamaños hicolor
   `/usr/share/icons/hicolor/{256,48}x{256,48}/apps/<icon_id>.png`, donde `icon_id` = nombre en
   **minúsculas** + no-alfanuméricos → `-`.
3. Siembra los `.desktop` en `/etc/skel/.local/share/applications/` para usuarios nuevos.

El `Exec=` apunta a `omarchy-launch-webapp <URL>`, que abre el navegador por defecto en **modo app**
(ventana sin barra de navegación) vía `uwsm-app -- <browser> --app=<url>`.

## El `.desktop` (plantilla)

```desktop
[Desktop Entry]
Version=1.0
Name=Xataka
Exec=omarchy-launch-webapp https://www.xataka.com/
Terminal=false
Type=Application
Icon=xataka
StartupNotify=true
```

Reglas rápidas:
- `Exec` siempre `omarchy-launch-webapp <URL>` (o un handler propio). Si la URL lleva caracteres
  reservados (`?&#`…), entre comillas dobles. Para launchers que necesitan shell
  (`cd "$HOME/src" && exec …`) el canon es `sh -c "…\"\$HOME…\"…"` (dobles + `\"` y `\$`).
- `Icon` = nombre en minúsculas con espacios/acentos → guion (`Google Photos.png` → `google-photos`).
- Si maneja un esquema (mailto, ...): `MimeType=x-scheme-handler/<esquema>` y `xdg-mime default`.

## Agregar una webapp (en 4 pasos)

Trabaja en el fork, rama `personal`:

```bash
cd ~/Work/omarchy/omarchy-installer

# 1) Crear los dos archivos (modelo: applications/Xataka.desktop e icons/Xataka.png)
# 2) Commitear
git add applications/<Nombre>.desktop applications/icons/<Nombre>.png
git commit -m "personal: add <Nombre> webapp"
git push origin personal
```

```bash
# 3) Publicar (reprisa el repo personal con la Action; pkgrel autoderivado)
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v4.0.2
```

```bash
# 4) En cada máquina: actualizar y refrescar lanzadores
omarchy update
omarchy-refresh-applications
```

## Cambiar o quitar una webapp

- **Cambiar** (URL, nombre, icono): edita el `.desktop` / icono, commit `personal: update <app>`,
  publica (paso 3) y actualiza (paso 4).
- **Quitar**: borra los dos archivos, commit `personal: remove <app>`, publica y actualiza. En las
  máquinas existentes, `omarchy-refresh-applications` quita el lanzador sobrante al refrescar.

## Estado del bootstrap de launchers (POC deprecado)

La Etapa 2 cosechó 60 launchers nuevos (39 webapps + 19 TUI/custom + 2 de Microsoft Edge) + sus 41
iconos, publicados en el par 4.0.2-103; **operativos en dev** (los 78 launchers del menú resuelven sus
bins). Para dejarlos operativos se creó un POC, `bin/omarchy-personal-bootstrap-launchers` (idempotente),
que instala las dependencias que corren los launchers (CLIs de mise/npm, instaladores oficiales,
Hermes, `~/src`).

> **⚠️ DEPRECADO como mecanismo vivo (13ª parte).** Ese POC no es el camino correcto a futuro: lo
> correcto es que su lógica viva en `install/user/*.sh` + `omarchy-mise-install` (fila **"Wrapper de
> terceros"** de la Matriz) y viaje a las máquinas vía `omarchy update`. El script se conserva en
> `bin/` como **referencia/ejemplo de integración**, no como flujo activo. No crear nuevos cambios
> por ese camino.

### Cómo es el patrón correcto (wrapper de terceros)

`omarchy refresh-applications` → `install/user/mise.sh` → `omarchy-mise-install <paquete> <cmd>`
escribe un stub idempotente en `~/.local/bin/<cmd>` (MISE_MINIMUM_RELEASE_AGE=0, `mise use -g` +
`exec mise x`). Ejemplos en el fork: `agy`, `opencode`, `omp`, `grok`, `gh`, `hey`, `ori`, `ghui`,
`hunk`, `codex`, `claude`, `playwright`, `pi`, + `omarchy-install-hermes-cli || true`. Ver
`docs/personal/recetas.md` (fila Wrapper de terceros) y `docs/personal/configs-migraciones.md`.
