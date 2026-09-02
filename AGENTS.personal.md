# AGENTS.personal.md — Guía operativa del fork personal

Esta es la puerta de entrada para **cualquier agente o humano que vaya a tocar este fork**.
Condensa el conocimiento que antes vivía en el repositorio de notas *scratchpad* (que queda como
histórico de referencias). El objetivo es que **todas las personalizaciones viajen vía
`omarchy update`** a las máquinas cliente siguiendo 100% el patrón upstream, y que siempre se sepa
dónde colocar cada cambio sin inventar mecanismos paralelos.

> **Lee primero `agents/skills/personal-fork/SKILL.md`** — es el documento operativo obligatorio:
> contiene la **Matriz de Decisión** (dónde va cada cambio) y el flujo de los dos escenarios
> (`omarchy dev pkg-test` en dev / `omarchy update` en las máquinas). Esta raíz solo es el índice.

---

## Por qué existe este fork

El dueño usa **N máquinas con Omarchy** instalado desde la ISO oficial. Todas deben ser **sistemas
idénticos, mantenidos automáticamente por `omarchy update`**, con sus personalizaciones aplicadas
por encima de un Omarchy vanilla. Estrategia acordada:

1. **Fork del repo fuente** `omacom/omarchy` mantenido en sync con upstream `quattro` (rama `personal`).
2. **Toda personalización es un cambio de fuente en el fork** (nunca un parche de instalación ni un
   script suelto por máquina).
3. Los cambios se **empaquetan como paquetes pacman propios**, publicados en un **repo pacman
   personal en GitHub Pages**, que las máquinas consumen por el flujo normal `omarchy update`.
4. **Se sigue el flujo upstream al pie de la letra**; el objetivo secundario es **contribuir de
   vuelta upstream**, así que cada personalización debe tener la MISMA forma que un cambio aceptable
   en un PR a `quattro`.

---

## Dónde vive cada pieza

| Qué | Dónde | Contenido |
|---|---|---|
| **Operación del agente** (obligatorio) | [`agents/skills/personal-fork/SKILL.md`](agents/skills/personal-fork/SKILL.md) | Matriz de Decisión + los dos escenarios + cómo operar |
| **Recetas W1–W10** | [`docs/personal/recetas.md`](docs/personal/recetas.md) | flujo paso a paso de cada fila de la Matriz |
| **Pipeline de publicación** (Action) | [`docs/personal/pipeline-publicacion.md`](docs/personal/pipeline-publicacion.md) | cómo la Action construye/publica el repo personal |
| **Onboarding de máquina** | [`docs/personal/onboarding.md`](docs/personal/onboarding.md) | dejar una máquina nueva en el sistema personal |
| **Cadencia / sync con upstream** | [`docs/personal/cadencia.md`](docs/personal/cadencia.md) | mantener el fork al día y republicar |
| **Webapps / launchers** | [`docs/personal/webapps.md`](docs/personal/webapps.md) | agregar/modificar/quitar webapps y su bootstrap |
| **Configs y migraciones** | [`docs/personal/configs-migraciones.md`](docs/personal/configs-migraciones.md) | configs de `~/.config` y migraciones únicas |
| **Runbook de fallos** | [`docs/personal/runbook.md`](docs/personal/runbook.md) | qué hacer cuando algo falla |
| **Glosario** | [`docs/personal/glosario.md`](docs/personal/glosario.md) | términos del proyecto |
| **Decisiones (ADRs)** | [`docs/personal/decisions/`](docs/personal/decisions/) | por qué se decidió cada cosa |

---

## Reglas duras (incumplirlas es un error de arquitectura)

1. **Nada de mecanismos paralelos**: no crear repos aparte, no dotfiles managers, no scripts
   per-máquina sueltos. Todo cae en una fila de la **Matriz de Decisión**; si algo no encaja,
   re-preguntar (nunca inventar).
2. **`omarchy update` es el único gatillo de distribución** a máquinas cliente. `omarchy dev
   pkg-test` es **solo** para la máquina dev y la deja en línea `-dev`.
3. **`omarchy` + `omarchy-settings` siempre se publican en lockstep** desde el mismo commit y al
   mismo `pkgver` (§ lockstep).
4. **Mantener el repo personal por delante del mirror oficial** en versión (regla `pkgrel` alta);
   si no, `omarchy update` instalaría el par oficial y borraría personalizaciones.
5. **`/etc/skel` solo siembra usuarios nuevos.** En máquinas con usuarios existentes, materializar
   con `omarchy refresh ...` / `omarchy reinstall-*` o una migración.
6. **Nunca tocar `/usr/share/omarchy/` a mano** en ninguna máquina; todo lo que vive ahí lo pone el
   paquete.
7. **Nunca commitear claves privadas** (GPG privada, deploy keys). El repo es público; las privadas
   solo viven como secrets de la Action.
8. Seguir las **convenciones de upstream**: el `AGENTS.md` de la raíz (dev del repo base), los
   skills de `agents/skills/*` y `docs/file-layout.md`.

---

## Estado conocido (fuente puntual)

No duplicar aquí la tabla de versiones: es la **fuente única de estado** del proyecto y vive en
`docs/personal/README.md`. El par publicado e instalado actual: ver ahí.

---

## Relación con el repositorio de notas (scratchpad)

El scratchpad (`robert-flo/scratchpad`) queda como **histórico** para futuras referencias (bitácora
completa, snapshots). **Desde ahora el fork es la fuente operativa** y este árbol
(AGENTS.personal.md + skill + `docs/personal/`) es donde se trabaja y actualiza. Si hay
contradicciones, manda lo que hay aquí.
