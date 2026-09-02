# docs/personal — Documentación del fork personal

Documentación operativa del **fork personal de Omarchy** (`robert-flo/omarchy`, rama `personal`).
Aquí vive el conocimiento que antes residía en el repositorio de notas *scratchpad* (que queda como
histórico). Esta carpeta es la **fuente operativa**; cualquier agente/humano que trabaje el fork debe
leer el skill obligatorio y luego las recetas según la tarea.

> **Empieza por [`agents/skills/personal-fork/SKILL.md`](../../agents/skills/personal-fork/SKILL.md)**:
> contiene la **Matriz de Decisión** y los dos escenarios. Este índice solo ordena los documentos.

---

## Lectura por tarea

| Quiero… | Leo |
|---|---|
| …decidir dónde va cada cambio (puerta obligatoria) | [`SKILL.md`](../../agents/skills/personal-fork/SKILL.md) — Matriz de Decisión |
| …la receta exacta de un flujo (W1–W10) | [`recetas.md`](recetas.md) |
| …cómo publica la Action el repo personal | [`pipeline-publicacion.md`](pipeline-publicacion.md) |
| …instalar/actualizar una máquina nueva | [`onboarding.md`](onboarding.md) |
| …seguir un release de upstream (cadencia) | [`cadencia.md`](cadencia.md) |
| …agregar/quitar una webapp o su bootstrap | [`webapps.md`](webapps.md) |
| …modificar configs de `~/.config` o escribir una migración | [`configs-migraciones.md`](configs-migraciones.md) |
| …qué hacer si algo falla | [`runbook.md`](runbook.md) |
| …definición de un término | [`glosario.md`](glosario.md) |
| …por qué se decidió algo | [`decisions/`](decisions/) |
| …la versión publicada/instalada actual | la tabla "Estado" abajo |

---

## Estado (fuente única de versiones)

> Esta tabla es la **fuente única de estado** del proyecto. No inventar versiones; leerlas de aquí.

| Paquete | Publicado | En la máquina dev |
|---|---|---|
| `omarchy` + `omarchy-settings` (par lockstep) | **4.0.2-103** | **4.0.2-103** (convergida; 78 launchers en el menú) |
| `hola-mundo` (PoC de paquete personal) | **0.1.0-2** | **0.1.0-2** |

Repo personal publicado (firmado con la clave dedicada `D5E75EAC51A44715`):
<https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64>.

> **Nota operativa:** la Action corre en `robert-flo/omarchy-pkgs`; el dispatch SIEMPRE con
> `--ref personal`. Desde el endurecimiento L8 aborta sola si se dispara desde otra rama, deriva el
> `pkgrel` del par y admite ensayo con `dry_run`. La vigilancia de cadencia (`sync-check.yml`, cron)
> avisa vía issue `[Cadencia]` si upstream publica y el pin se queda atrás.

---

## Contexto de una frase

N máquinas Omarchy **idénticas y mantenidas solas por `omarchy update`**, con personalizaciones que
viajan como **cambios de fuente en este fork** y se sirven desde un **repo pacman personal en GitHub
Pages** generado por una **GitHub Action**, siguiendo el modelo upstream con miras a contribuir de
vuelta.

## Repos implicados

| Repo | Rol |
|---|---|
| `robert-flo/omarchy` | fork fuente, rama `personal` sobre `upstream/quattro` (este repo) |
| `robert-flo/omarchy-pkgs` | PKGBUILDs + maquinaria de build/release; ahí corre la Action |
| `robert-flo/omarchy-personal-repo` | repo pacman servido en GitHub Pages (branch `gh-pages`) |
| `robert-flo/scratchpad` | **histórico** (bitácora y snapshots pasados; ya no es la fuente operativa) |
