# Glosario del fork personal

Términos usados en la documentación del fork. Una definición por término; si algo no está, se busca
primero el término upstream (`docs/` del repo fuente).

| Término | Qué es (en este proyecto) |
|---|---|
| **Action / `release-personal.yml`** | Workflow de GitHub Actions en `robert-flo/omarchy-pkgs` que construye y publica el repo pacman personal en GitHub Pages. |
| **bootstrap** (dev) | Dejar una máquina lista como entorno dev: clones, `omarchy dev pkg-test` y par dev instalado. |
| **bootstrap de launchers** (POC) | `bin/omarchy-personal-bootstrap-launchers`; POC de la Etapa 2, **deprecado como mecanismo vivo**; su lógica se absorbe en `install/user/*.sh` + `omarchy-mise-install`. |
| **cadencia / sync (W9)** | Rutina de mantener el fork al día con `upstream/quattro` (rebase → re-pin → re-release). |
| **`clean` / `clean-repo`** | Paso del pipeline que poda versiones viejas del repo publicado → no hay "rollback" (roll-forward). |
| **db / database file** | Base de datos del repo pacman (`omarchy.db`; alias `omarchy-personal.db` por sección). |
| **deploy key** | Clave SSH (secret `SSH_DEPLOY_KEY`) para escribir en `gh-pages` de `omarchy-personal-repo`. |
| **dispatch** | Disparar el workflow: `gh workflow run release-personal.yml … --ref personal -f version=…`. |
| **`dry_run`** | Modo de la Action que ensaya todo sin publicar nada. |
| **fork** | Los forks personales: `robert-flo/omarchy` (fuente) y `robert-flo/omarchy-pkgs` (paquetes), rama `personal`. |
| **gh-pages** | Rama de `omarchy-personal-repo` servida como web estática (los archivos del repo pacman). |
| **guard §5.3** | Paso de la Action que aborta si el par personal quedara por detrás del estable oficial. |
| **guard fail-fast** | Paso de la Action que aborta si el workflow se disparó desde una rama ≠ `personal`. |
| **keyring / confianza de clave** | `pacman-key --add` + `--lsign-key` de la clave pública personal en cada máquina. |
| **lockstep (par)** | `omarchy` y `omarchy-settings` se construyen del mismo commit/source y comparten `pkgver`/`pkgrel`/`_tag`/`_commit`; `omarchy` depende de `omarchy-settings=${pkgver}` exacto. |
| **Matriz de Decisión** | Tabla canónica de `SKILL.md` que decide DÓNDE va cada cambio del fork (config / webapp / comando / wrapper / set / migración). |
| **`omarchy update`** | Flujo de actualización que mantiene las máquinas; actualiza lo instalado, no instala paquetes nuevos. |
| **par (lockstep)** | El par de paquetes `omarchy` + `omarchy-settings`. |
| **pin / pin engine** | `bin/omarchy-pkgs release` reescribe el par con `_tag`/`_commit`/`pkgver`/`sha256sums` del commit base. |
| **`pinned`** | Marca en `.omarchy/package.json` (`"pinned": true`): requiere un-pin temporal local para buildar a `stable`. |
| **`personal: true`** | Marca en `.omarchy/package.json` del PKGBUILD: hace que la Action lo publique en el repo personal. |
| **`pkgrel`** | Componente de versión tras el guion (`4.0.2-103`); en el par personal es contador de republicación (base 99, +1 por república del mismo `pkgver`, autoderivado). |
| **`pkgver`** | Versión del paquete (`4.0.2`); en el par personal = tag upstream base de la rama `personal`. |
| **repo personal** | `robert-flo/omarchy-personal-repo` (Pages), repo pacman de solo `stable`. |
| **shading / sombreado parcial** | `[omarchy-personal]` ANTES de `[omarchy]`: el par y los extras personales se sirven del repo personal, el resto del ecosistema del mirror oficial. |
| **stable** | Único canal publicado por el repo personal. |
| **un-pin temporal** | Marcar temporalmente `"pinned": false` (sin commitear) para que el par buildee directo a `stable`. |
| **`vercmp`** | Comparador de versiones pacman (gana el pkgver más alto; a igual pkgver, el pkgrel más alto). |
| **webapp** | Aplicación servida como `.desktop` estático (`applications/`); cualquier `.desktop` nuevo entra al paquete sin tocar PKGBUILD. |
