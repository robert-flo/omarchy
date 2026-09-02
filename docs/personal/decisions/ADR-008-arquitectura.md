# ADR-008 — Todo viaja vía `omarchy update` (arquitectura 13ª parte)

- **Estado:** Aceptada (DECISIÓN ARQUITECTÓNICA FIRME, 2026-09-02)

## Contexto

El dueño detectó que no había un camino único que responda "¿dónde va cada cambio del fork?". La
Etapa 2 dejó un POC (`bin/omarchy-personal-bootstrap-launchers`) que instala dependencias por script
suelto corriéndose por curl por máquina — ese enfoque **no es el modelo upstream**. Tampoco era claro
si los configs de `$HOME` iban al fork o a un mecanismo aparte, y se evaluó (y descartó) el enfoque de
plugins de omarchy para llevar ejecutables/configs.

## Decisión

- **Todo cambio viaja vía `omarchy update`** en máquinas futuras. Nada por script suelto per-máquina,
  ni dotfiles, ni mecanismos paralelos.
- Se define la **Matriz de Decisión** (config de usuario / webapp / comando / wrapper de terceros /
  set de paquetes / provisioning-migración) como **puerta obligatoria** antes de tocar el fork; cada
  fila dicta dónde, en qué paquete, cómo validar y cómo llega a las máquinas.
- Dos y solo dos escenarios: **DEV** (`omarchy dev pkg-test` + refresh, deja la máquina en línea
  `-dev`) y **MÁQUINAS** (`omarchy update`, único gatillo de distribución).
- **`omarchy-personal-bootstrap-launchers` queda DEPRECADO como mecanismo vivo**; su lógica se
  absorbe en `install/user/*.sh` + `omarchy-mise-install` (fila "Wrapper de terceros"). El POC se
  conserva temporalmente como referencia/ejemplo de integración.
- **El enfoque de plugins de omarchy queda descartado** para ejecutables/configs: el sistema de
  plugins (`~/.config/omarchy/plugins/`) es SOLO para widgets del shell Quickshell.

## Consecuencias

- Es 100% el modelo upstream, anclado a los documentos autoritativos del fork (`docs/file-layout.md`,
  `agents/skills/*`, `AGENTS.md`). No se inventa ninguna nueva forma de entrega.
- Elimina la duplicidad "¿bootstrap, plugin, script o dotfile?" → siempre se responde con la Matriz.
- Esta documentación (skill + `docs/personal/`) nace para materializar esta decisión en el fork.

## Fuentes

- Antes: `ARCHITECTURE.md` del scratchpad (histórico) y WORKLOG 13ª parte.
