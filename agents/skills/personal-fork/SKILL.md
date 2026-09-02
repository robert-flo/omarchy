---
name: personal-fork
description: >
  REQUIRED for ANY work on the robert-flo/omarchy personal fork (branch `personal`).
  Use when adding or changing configs, web apps, omarchy-* commands, third-party wrappers,
  package sets, migrations, or provisioning in this fork; or when publishing to the personal
  pacman repo, onboarding a new machine, or syncing with upstream. Triggers: "add/change this
  config/app/command/wrapper", "publish the release", "install a new machine", "sync with upstream",
  "the fork needs an update". Use the Decision Matrix to decide WHERE every change goes.
  Do NOT use for end-user customization of an installed system (that is
  default/agents/skills/omarchy/SKILL.md) or for generic upstream source development (that is
  agents/skills/* and AGENTS.md).
---

# Personal Fork Skill

This skill teaches how to **operate Omarchy's personal fork** (`robert-flo/omarchy`, branch
`personal`): where each change goes, how to validate it on the dev machine, and how to deliver it to
all machines via `omarchy update`, following the upstream pattern with a view to contributing back.

**Reference index:** [`AGENTS.personal.md`](../../../AGENTS.personal.md) (overview + hard rules) and
[`docs/personal/`](../../../docs/personal/) (detailed recipes).

---

## When to use this skill — and when not to

**Always** use it for the following work on the fork:

- Add/change a **user config** (`config/<app>/`)
- Add/change a **web app or launcher** (`applications/*.desktop` + `applications/icons/`)
- Add/change an **`omarchy-*` command** (`bin/omarchy-*`)
- Add/edit a **third-party wrapper** (mise / npm / official installers → `install/user/*.sh` + `omarchy-mise-install`)
- Touch the **package set** (`install/omarchy-*.packages`)
- Write a **provisioning / migration script** (`install/` / `migrations/*.sh`)
- **Publish** the personal repo (Action `release-personal.yml`)
- **Onboard** a new machine or **sync with upstream** (cadence)
- Any "where does this change go?" question

**Not** for:

- End-user customization of an installed system → `default/agents/skills/omarchy/SKILL.md`.
- Generic base-repo development → `AGENTS.md` and `agents/skills/*`.

---

## Mandatory first step: the Decision Matrix

**Before touching the fork, classify the change into EXACTLY ONE row of this table.** The row decides
everything that follows (where, package, dev validation, and how it reaches machines). There is no
"catch-all"; if a change does not fit a row, that is a signal the change does not follow the upstream
model — stop and re-ask.

| Change type | Where in the fork | Where it installs | Package | Dev validation | Reaches machines via |
|---|---|---|---|---|---|
| **User config** (kitty, foot, hypr…) | `config/<app>/` | `~/.config/<app>/` (seed `/etc/skel` + resync source `/usr/share/omarchy/config`) | `omarchy-settings` | `omarchy dev pkg-test` + `omarchy refresh config <relpath>` | `omarchy update` |
| **Web app / launcher** | `applications/*.desktop` + `applications/icons/` | `~/.local/share/applications/` (+ hicolor icons) | `omarchy-settings` | `omarchy dev pkg-test` + `omarchy refresh applications` | `omarchy update` |
| **Own executable** (`omarchy-*`) | `bin/omarchy-*` (with `# omarchy:summary=…` metadata) | `/usr/bin/` | `omarchy` | `omarchy dev pkg-test` | `omarchy update` |
| **Third-party wrapper** (mise, npm, official) | `install/user/*.sh` + `omarchy-mise-install` / `omarchy-install-*` lines | `~/.local/bin/` (idempotent) | `omarchy-settings` | `omarchy refresh applications` (runs `install/user/*.sh`) | `omarchy update` |
| **Package set** | `install/omarchy-base.packages` / `omarchy-other.packages` | installed by pacman (ISO / `reinstall pkgs`) | `omarchy-settings` | `omarchy reinstall pkgs` | `omarchy update` |
| **Provisioning / migration** | `install/` + `migrations/*.sh` | `/usr/share/omarchy/` | `omarchy` | `omarchy dev pkg-test` (+ run it) | `omarchy update` (migrations only) |

> **Deprecated POC — `omarchy-personal-bootstrap-launchers`:** it is **DEPRECATED as a living
> mechanism** (it was the Stage-2 proof of concept). Its logic is absorbed by the **"Third-party
> wrapper"** row (`install/user/*.sh` + `omarchy-mise-install`). The script remains in `bin/` only as
> a reference/example of integration, not as an active flow. Do not create new changes through that
> path.

---

## The two scenarios (there is no third)

### A) DEV scenario — "I am building and validating on the dev machine"

```text
edit the source in the fork → omarchy dev pkg-test → refresh the component → validate
```

- `omarchy dev pkg-test` builds and installs **locally** the pair from the checkout (`omarchy-dev` /
  `omarchy-settings-dev`, version `dev.<sha>`). **It publishes nothing.** It leaves the machine on the
  `-dev` channel.
- Then **refresh** the component you touched:
  - config → `omarchy refresh config <relpath>`
  - web app/launcher or wrapper → `omarchy refresh applications`
  - package set → `omarchy reinstall pkgs`
- In dev, `pacman -Q omarchy omarchy-settings` reports `dev.<sha>`.

### B) MACHINES scenario — "I take it to all my computers"

**The only distribution trigger is `omarchy update`.**

```text
git commit + push origin personal → Action release-personal → pair re-published →
omarchy update (on each machine) → pacman installs the personal pair → changes are present
```

- New files arrive packaged; materializing them into the `$HOME` of **existing users** requires a
  refresh (dev) or a **migration** (once per machine, automatic). **New** users receive them at
  creation via `/etc/skel`.
- **Golden rule:** nothing is installed by a loose per-machine script or a parallel mechanism;
  everything travels through `omarchy update`.

---

## Recommended workflow

1. **Classify** the change in the Decision Matrix (above).
2. **Implement** the change in its fork location, following the corresponding W# recipe
   (`docs/personal/recipes.md`) and the upstream conventions (`AGENTS.md`, `agents/skills/*`,
   `docs/file-layout.md`); `bin/` scripts carry `# omarchy:summary=` etc. metadata.
3. **Validate in dev** (scenario A): `omarchy dev pkg-test` + refresh + verify it works.
4. **Publish** (scenario B): `git commit + push origin personal`; trigger the release Action with
   `--ref personal`; on each machine `omarchy update`.
5. Add a **migration** if the change must touch existing state on already-created machines.

---

## Key architecture decisions (summary)

- **Two repos, two packages:** `omarchy` (engine → `bin/` to `/usr/bin/`) and `omarchy-settings`
  (files: `config/`, `applications/`, `install/user/`, sets). Mandatory lockstep.
- **Partial shading:** `[omarchy-personal]` before `[omarchy]` in
  `default/pacman/pacman-stable.conf`.
- **`pkgrel` rule:** high base `99`, `+1` per re-publication of the same `pkgver` (derived by the
  Action automatically).
- **Omarchy plugins = only Quickshell shell widgets**; not used for executables/configs (rejected).
- Details in `docs/personal/release-pipeline.md` and `docs/personal/decisions/`.

---

## Validation command quick reference

```bash
omarchy dev pkg-test               # install the dev pair from the local checkout
omarchy refresh applications       # materialize .desktop files + wrappers into ~
omarchy refresh config <relpath>   # copy a single config into ~/.config/
omarchy reinstall pkgs             # reconcile the set with install/omarchy-*.packages
omarchy reinstall-configs          # re-copy ALL of /etc/skel over ~ (nuclear)
./test/all                         # CLI + shell suites (run before publishing)
```

---

## Troubleshooting

- **A change "is not showing up"?** Rebuilding the package does NOT materialize anything into an
  existing user; run the corresponding refresh.
- **`omarchy update` put the official pair and "lost" my personalization?** Cadence/version lag:
  re-publish the personal with `pkgver >=` and a growing `pkgrel` (roll-forward). See
  `docs/personal/runbook.md`.
- **Not sure where something goes?** The Decision Matrix rules; re-read it and, if it does not fit,
  ask.
