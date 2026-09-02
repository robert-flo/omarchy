# Runbook — fallos y recuperación del fork personal

Para el mantenedor/agente. Qué hacer **cuando algo falla** en la publicación, la cadencia o una
máquina. También define la **operación preventiva**.

## Cómo funciona la publicación (en 10 segundos)

- La Action `release-personal.yml` (en `robert-flo/omarchy-pkgs`) recolecta los PKGBUILD con
  `"personal": true`, pinea el par lockstep al tag base de `personal`, **deriva el `pkgrel` solo**
  (mismo `pkgver` → última +1; `pkgver` nuevo → 99), builda/signa/promueve/limpia y **commitea a
  `gh-pages`**.
- Dispatch SIEMPRE con `--ref personal`; desde otra rama la Action aborta sola (guard fail-fast).
- `dry_run=true` = ensayo completo **sin publicar**.
- Concurrency: dos dispatches corren en cola (nunca intercalados).

## Estrategia de rollback declarada (LÉEME ANTES DE ENTRAR EN PÁNICO)

**Regla general: roll-forward, no rollback.** El repo publicado se poda (`clean-repo`) a la última
versión; **no se puede "despublicar"** a una anterior. Si publicas algo mal, reparas publicando
**otra versión por encima** (mismo `pkgver` + `pkgrel` incrementado, o `pkgver` nuevo).

Recaídas puntuales (solo si una MÁQUINA quedó rota y no puedes esperar al next `pkgrel`):

| Situación | Herramienta | Cuándo |
|---|---|---|
| Reparar una máquina puntual con un artefacto bueno | `pacman -U` del `.zst` + `.sig` del historial de `gh-pages` | la máquina no converge tras el update |
| Volver a un paquete público anterior | `git log gh-pages` → `git show <sha>:stable/x86_64/<pkg>.pkg.tar.zst` | emergencia real |

## Modos de fallo conocidos

### F1 — Dispatch sin `--ref` (o desde rama equivocada)
Hoy es inofensivo: el guard fail-fast aborta si `github.ref != refs/heads/personal`.
- Síntoma: run termina rojo en el primer paso con "FORK ABORT".
- Respuesta: re-disparar con `--ref personal`. Nada quedó publicado.

### F2 — `pkgrel` equivocado
Hoy es automático (la Action lo deriva). Override manual `-f pkgrel=<n>` solo para emergencias.
- Síntoma de error: el par "no pesca" el cambio en alguna máquina (pkgrel igual = no rebuild).
- Respuesta: re-dispatch sin `-f pkgrel` (deriva +1) y `omarchy update` en la máquina.

### F3 — Publicación mala (artefacto/db/firma corruptos, o push a Pages falló)
- Síntoma: el paso "Validar publicación" falla, o `pacman -Sy` en una máquina da error de firma/datos.
- Respuesta: 1) diagnosticar (`git -C <clone-gh-pages> log --oneline -3`, `curl -fsSI`); 2) ensayar
  con `dry_run=true`; 3) si pasó el ensayo, re-publicar (mismo `pkgver`, `pkgrel+1`); el alias
  de sección se regenera en el publish.

### F4 — Lag de cadencia (upstream publica y el fork no)
- Síntoma: `sync-check.yml` abre issue `[Cadencia]`; o el par de una máquina es el OFICIAL
  (→ desaparece la personalización).
- Respuesta (roll-forward): cadencia (`docs/personal/cadencia.md`) — rebase + re-publicación con el
  `pkgver` nuevo. Mientras tanto, por máquina: no hagas `omarchy update` si no puedes republicar en
  el día; si ya sucedió, republica y el próximo update regresa al par personal (recuperación
  automática §5.3).

### F5 — Fallos transitorios de red (TLS de archlinux.org, rate limit de gh)
- Respuesta: si falló en la parte de descargas, re-disparar tal cual (idempotente, el pin ya está en
  `personal`). Si falló DESPUÉS de publicar, ver F3.

### F6 — Rotación / pérdida de la clave GPG o de la deploy key
Resumen práctico (DR completo en `decisions/ADR-006-claves-gpg.md`):
- **Pérdida de `GPG_PRIVATE_KEY`:** clave nueva; publicar la `.asc` nueva en `keys/`; en CADA máquina
  `pacman-key --add` + `--lsign-key` de la clave nueva ANTES de cualquier update.
- **Pérdida de `SSH_DEPLOY_KEY`:** regenerar en `omarchy-personal-repo` (Settings → Deploy keys) y
  actualizar el secret en `omarchy-pkgs`.
- **Regla fija:** la privada solo vive como secret; nunca commitearla. Sospecha de filtración =
  rotación inmediata.

### F7 — Rescate por máquina (volver al personal sin esperar el próximo update)
1. Descargar el `.pkg.tar.zst` (+`.sig`) actual del par desde
   `https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/`.
2. `sudo pacman -U --noconfirm ./omarchy-<ver>-any.pkg.tar.zst ./omarchy-settings-<ver>-any.pkg.tar.zst`.
3. `sudo omarchy refresh pacman` (o verificar orden de secciones) y `omarchy update -y`.

### F8 — Quirk de `sudo -v` en `omarchy update` viejos / no interactivo
`omarchy update` puede pedir `sudo -v` antes de empezar (falla en sesiones sin TTY). Respuesta:
ejecutar con TTY, o `sudo -v` previo, o drop-in `Defaults:USER !authenticate` temporal. No es un
fallo del repo.

## Operación preventiva

### Cadencia
Rebase + re-dispatch (ver `cadencia.md`). Con dudas, primero `-f dry_run=true`.

### Vigilancia (qué mira por ti)
- `sync-check.yml` (cron diario 06:30 UTC): tag upstream vs pin; abre/cierra issue `[Cadencia]`.
- "Guard §5.3" de la Action: aborta si el par queda por detrás del estable oficial.
- "Validar publicación en GitHub Pages" tras cada push.

### Fuente única de estado
`docs/personal/README.md` → tabla "Estado". No inventar versiones.

## Enlaces para un incidente

| Recurso | Uso |
|---|---|
| `docs/personal/pipeline-publicacion.md` | mecánica de la publicación + regla `pkgrel` |
| `docs/personal/cadencia.md` | rebase/re-publicación |
| `docs/personal/onboarding.md` | reseate/onboarding por máquina |
| `docs/personal/decisions/` | ADRs (hosting, sombreado, pkgrel, claves, build) |
| `agents/skills/personal-fork/SKILL.md` | Matriz de Decisión (dónde va cada cambio) |
