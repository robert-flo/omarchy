---
name: personal-fork
description: >
  REQUIRED for ANY work on the robert-flo/omarchy personal fork (branch `personal`).
  Use when adding or changing configs, webapps, omarchy-* commands, third-party wrappers,
  package sets, migrations, or provisioning in this fork; or when publishing to the personal
  pacman repo, onboarding a new machine, or syncing with upstream. Triggers: "add/change this
  config/app/command/wrapper", "publish the release", "install a new machine", "sync with upstream",
  "the fork needs an update". Use the Decision Matrix to decide WHERE every change goes.
  Do NOT use for end-user customization of an installed system (that is default/agents/skills/omarchy)
  or for generic upstream source development (that is agents/skills/* and AGENTS.md).
---

# Personal Fork Skill

Este skill enseña a **operar en el fork personal de Omarchy** (`robert-flo/omarchy`, rama `personal`):
dónde va cada cambio, cómo validarlo en la máquina dev y cómo llevarlo a todas las máquinas vía
`omarchy update`, siguiendo el patrón upstream con miras a contribuir de vuelta.

**Documento operativo de referencia:** [`AGENTS.personal.md`](../../../AGENTS.personal.md) (índice)
y [`docs/personal/`](../../../docs/personal/) (recetas detalladas).

## Cuándo SE DEBE usar este skill

**SIEMPRE** ante cualquiera de estos trabajos sobre el fork:

- Agregar/cambiar un **config de usuario** (`config/<app>/`)
- Agregar/cambiar una **webapp o launcher** (`applications/*.desktop` + `applications/icons/`)
- Agregar/cambiar un **comando `omarchy-*`** (`bin/omarchy-*`)
- Añadir/editar un **wrapper de terceros** (mise / npm / instaladores oficiales → `install/user/*.sh` + `omarchy-mise-install`)
- Tocar el **set de paquetes** (`install/omarchy-*.packages`)
- Escribir un **script de provisioning / migración** (`install/` / `migrations/*.sh`)
- **Publicar** el repo personal (Action `release-personal.yml`)
- **Onboarding** de una máquina nueva o **sync con upstream** (cadencia W9)
- Cualquier duda de "¿dónde va este cambio?"

**No** usar para:
- Customización end-user de un sistema instalado → `default/agents/skills/omarchy/SKILL.md`.
- Desarrollo genérico del repo base → `AGENTS.md` y `agents/skills/*`.

## Paso obligatorio: la Matriz de Decisión

**Antes de tocar el fork, clasificar el cambio en UNA fila de esta tabla.** La fila decide TODO lo
que sigue (dónde, paquete, validación dev y cómo llega a las máquinas). No existe un "cajón de
sastre"; si un cambio no encaja, es señal de no seguir el modelo upstream → parar y re-preguntar.

| Tipo de cambio | Dónde en el fork | Dónde se instala | Paquete | Validación dev | Llega a las máquinas |
|---|---|---|---|---|---|
| **Config de usuario** (kitty, foot, hypr…) | `config/<app>/` | `~/.config/<app>/` (seed `/etc/skel` + fuente de resync `/usr/share/omarchy/config`) | `omarchy-settings` | `omarchy dev pkg-test` + `omarchy refresh config <archivo>` | `omarchy update` |
| **Webapp / launcher** | `applications/*.desktop` + `applications/icons/` | `~/.local/share/applications/` (+ iconos hicolor) | `omarchy-settings` | `omarchy dev pkg-test` + `omarchy refresh-applications` | `omarchy update` |
| **Ejecutable propio** (`omarchy-*`) | `bin/omarchy-*` (con metadatos `# omarchy:summary=…`) | `/usr/bin/` | `omarchy` | `omarchy dev pkg-test` | `omarchy update` |
| **Wrapper de terceros** (mise, npm, oficiales) | `install/user/*.sh` + líneas `omarchy-mise-install` / `omarchy-install-*` | `~/.local/bin/` (idempotente) | `omarchy-settings` | `omarchy refresh-applications` (ejecuta `install/user/*.sh`) | `omarchy update` |
| **Set de paquetes** | `install/omarchy-base.packages` / `omarchy-other.packages` | instalado por pacman (ISO / `reinstall pkgs`) | `omarchy-settings` | `omarchy reinstall pkgs` | `omarchy update` |
| **Provisioning / migración** | `install/` + `migrations/*.sh` | `/usr/share/omarchy/` | `omarchy` | `omarchy dev pkg-test` (+ ejecutar) | `omarchy update` (migraciones solas) |

> **Nota sobre el POC `omarchy-personal-bootstrap-launchers`:** quedó **DEPRECADO como mecanismo
> vivo** (fue un POC para la Etapa 2). Su lógica se absorbe en la fila **"Wrapper de terceros"**
> (`install/user/*.sh` + `omarchy-mise-install`). El script se conserva en `bin/` como
> referencia/ejemplo de integración, no como flujo activo. No crear nuevos cambios por ese camino.

## Los dos escenarios (no hay un tercero)

### A) Escenario DEV — "estoy construyendo y validando en la máquina dev"

```text
editar la fuente en el fork → omarchy dev pkg-test → refresh del componente → validar
```

- `omarchy dev pkg-test` construye e instala **localmente** el par desde el checkout (`omarchy-dev` /
  `omarchy-settings-dev`, versión `dev.<sha>`). **No publica nada.** Deja la máquina en línea `-dev`.
- Luego **refresh** del componente que tocaste:
  - config → `omarchy refresh config <relpath>`
  - webapp/launcher o wrapper → `omarchy refresh-applications`
  - set de paquetes → `omarchy reinstall pkgs`
- En dev `pacman -Q omarchy omarchy-settings` muestra `dev.<sha>`.

### B) Escenario MÁQUINAS — "lo llevo a todas mis computadoras"

**El único gatillo de distribución es `omarchy update`.**

```text
git commit + push origin personal → Action release-personal → par republicado →
omarchy update (en cada máquina) → pacman instala el par personal → cambios presentes
```

- Los archivos nuevos llegan empaquetados; materializarlos en el `$HOME` de **usuarios existentes**
  requiere un refresh (dev) o una **migración** (una vez por máquina, automática). Usuarios **nuevos**
  los reciben al crearse vía `/etc/skel`.
- **Regla de oro:** nada se instala por script suelto per-máquina ni por mecanismos paralelos; todo
  viaja por `omarchy update`.

## Flujo de trabajo recomendado

1. **Clasificar** el cambio en la Matriz de Decisión (ver arriba).
2. **Implementar** el cambio en su ubicación del fork, siguiendo la receta W# correspondiente
   (ver `docs/personal/recetas.md`) y las convenciones de upstream (`AGENTS.md`, `agents/skills/*`,
   `docs/file-layout.md`); los scripts de `bin/` llevan metadatos `# omarchy:summary=` etc.
3. **Validar en dev** (Escenario A): `omarchy dev pkg-test` + refresh + verificar que funciona.
4. **Publicar** (Escenario B): `git commit + push origin personal`; disparar la Action de release con
   `--ref personal`; en cada máquina `omarchy update`.
5. Añadir **migración** si la personalización debe tocar un estado existente en máquinas ya creadas.

## Decisiones clave de arquitectura (resumen)

- **Dos repos, dos paquetes:** `omarchy` (motor → `bin/` a `/usr/bin/`) y `omarchy-settings`
  (archivos: `config/`, `applications/`, `install/user/`, sets). Lockstep obligatorio.
- **Sombreado parcial:** `[omarchy-personal]` antes de `[omarchy]` en `default/pacman/pacman-stable.conf`.
- **Regla `pkgrel`:** base alta `99`, +1 por republicación del mismo `pkgver` (autoderivado por la Action).
- **Plugins de omarchy = solo widgets del shell Quickshell**; no se usan para ejecutables/configs (descartado).
- Detalle en `docs/personal/pipeline-publicacion.md` y `docs/personal/decisions/`.

## Guía rápida de comandos de validación

```bash
omarchy dev pkg-test               # instala el par dev desde el checkout local
omarchy refresh-applications       # materializa .desktop + wrappers en ~
omarchy refresh config <relpath>   # copia un config suelto a ~/.config/
omarchy reinstall pkgs             # reconcilia el set con install/omarchy-*.packages
omarchy reinstall-configs          # re-copia TODO /etc/skel sobre ~ (nuclear)
./test/all                         # suites CLI + shell (correr antes de publicar)
```

## Troubleshooting

- ¿Un cambio "no aparece"? Reconstruir el paquete NO materializa nada en un usuario existente;
  hay que correr el refresh correspondiente.
- ¿`omarchy update` puso el par oficial y "perdió" mi personalización? Lag de cadencia/versión:
  republicar el personal con `pkgver >=` y `pkgrel` creciente (roll-forward). Ver `docs/personal/runbook.md`.
- ¿Dudas de dónde va algo? La Matriz de Decisión manda; re-leerla y si no encaja, preguntar.
