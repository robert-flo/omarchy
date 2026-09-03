# ADR-008 — Everything travels via `omarchy update` (Stage-3 architecture)

- **Status:** Accepted (firm architectural decision, 2026-09-02)

## Context

The owner found there was no single path answering "where does each fork change go?". Stage 2 left a
PoC (`bin/omarchy-personal-bootstrap-launchers`) that installs dependencies via a loose script run by
curl per machine — that approach **is not the upstream model**. It was also unclear whether `$HOME`
configs belonged in the fork or a separate mechanism, and the omarchy plugin approach (for carrying
executables/configs) was evaluated and rejected.

## Decision

- **Every change travels via `omarchy update`** on future machines. Nothing by a loose per-machine
  script, no dotfiles, no parallel mechanisms.
- The **Decision Matrix** (user config / web app / command / third-party wrapper / package set /
  provisioning-migration) is defined as a **mandatory gate** before touching the fork; each row says
  where, in which package, how to validate, and how it reaches machines.
- Two and only two scenarios: **DEV** (`omarchy dev pkg-test` + refresh; leaves the machine on
  `-dev`) and **MACHINES** (`omarchy update`, the sole distribution trigger).
- **`omarchy-personal-bootstrap-launchers` was REMOVED**; its logic is absorbed into canonical rows:
  system packages → `install/omarchy-base.packages`; CLIs → `install/user/mise.sh`
  (`omarchy-mise-install`); heavy/AUR tools → lazy first-use stubs provisioned by
  `install/user/launchers.sh` (`omarchy-install-mimo`, `omarchy-install-opencode-desktop`,
  `omarchy-install-aur`); openclaw gateway → `omarchy-install-service-openclaw`; Hermes Web shim →
  `omarchy-install-hermes-cli`; `~/src` → `install/user/mise-work.sh`.
- **The omarchy plugin approach is rejected** for executables/configs: the plugin system
  (`~/.config/omarchy/plugins/`) is ONLY for Quickshell shell widgets.

## Consequences

- It is 100% the upstream model, anchored to the fork's authoritative documents
  (`docs/file-layout.md`, `agents/skills/*`, `AGENTS.md`). No new delivery method is invented.
- It removes the "bootstrap, plugin, script or dotfile?" duplication → always answered by the Matrix.
- This documentation (skill + `docs/personal/`) exists to materialize this decision in the fork.

## Sources

- Before: the scratchpad's `ARCHITECTURE.md` (history) and the L13 work log.
