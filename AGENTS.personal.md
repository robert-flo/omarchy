# AGENTS.personal.md — Operating guide for the personal fork

This is the entry point for **any agent or human who will touch this fork**. It condenses the
knowledge that previously lived in the *scratchpad* notes repository (kept only as a historical
reference). The goal is that **every customization reaches client machines through `omarchy update`**
following the upstream pattern 100%, and that it is always clear where each change goes — without
inventing parallel mechanisms.

> **Read [`agents/skills/personal-fork/SKILL.md`](agents/skills/personal-fork/SKILL.md) first** — it
> is the mandatory operating document: it holds the **Decision Matrix** (where each change goes) and
> the two-scenario flow (`omarchy dev pkg-test` in dev / `omarchy update` on machines). This root file
> is only the index.

---

## Why this fork exists

The owner runs **N machines with Omarchy installed from the official ISO**. All of them must be
**identical systems, maintained automatically by `omarchy update`**, with personalizations applied on
top of a vanilla Omarchy. Agreed strategy:

1. **Fork of the upstream source** `omacom/omarchy`, kept in sync with upstream `quattro` (branch `personal`).
2. **Every personalization is a source change in the fork** (never an install-time patch or a loose
   per-machine script).
3. Changes are **packaged as own pacman packages**, published to a **personal pacman repository on
   GitHub Pages**, which machines consume through the normal `omarchy update` flow.
4. **The upstream flow is followed to the letter**; a secondary goal is to **contribute back
   upstream**, so each personalization must have the SAME shape as a change acceptable in a PR to
   `quattro`.

---

## Where each piece lives

| What | Where | Content |
|---|---|---|
| **Agent operations** (mandatory) | [`agents/skills/personal-fork/SKILL.md`](agents/skills/personal-fork/SKILL.md) | Decision Matrix + the two scenarios + how to operate |
| **Recipes W1–W10** | [`docs/personal/recipes.md`](docs/personal/recipes.md) | step-by-step flow for each Matrix row |
| **Release pipeline** (Action) | [`docs/personal/release-pipeline.md`](docs/personal/release-pipeline.md) | how the Action builds/publishes the personal repo |
| **Machine onboarding** | [`docs/personal/onboarding.md`](docs/personal/onboarding.md) | put a new machine on the personal system |
| **Cadence / upstream sync** | [`docs/personal/cadence.md`](docs/personal/cadence.md) | keep the fork up to date and re-release |
| **Web apps / launchers** | [`docs/personal/webapps.md`](docs/personal/webapps.md) | add/modify/remove web apps and their bootstrap |
| **Configs and migrations** | [`docs/personal/configs-and-migrations.md`](docs/personal/configs-and-migrations.md) | `~/.config` configs and one-off migrations |
| **Failure runbook** | [`docs/personal/runbook.md`](docs/personal/runbook.md) | what to do when something fails |
| **Glossary** | [`docs/personal/glossary.md`](docs/personal/glossary.md) | project terms |
| **Decisions (ADRs)** | [`docs/personal/decisions/`](docs/personal/decisions/) | why each thing was decided |

---

## Hard rules (breaking any of them is an architecture error)

1. **No parallel mechanisms**: no separate repos, no dotfiles managers, no loose per-machine scripts.
   Everything falls into a row of the **Decision Matrix**; if something does not fit, re-ask (never
   invent).
2. **`omarchy update` is the only distribution trigger** to client machines. `omarchy dev pkg-test`
   is **only** for the dev machine and leaves it on the `-dev` channel.
3. **`omarchy` + `omarchy-settings` are always published in lockstep** from the same commit and the
   same `pkgver` (§ lockstep).
4. **Keep the personal repo ahead of the official mirror** in version (the `pkgrel` rule); otherwise
   `omarchy update` would install the official pair and wipe out personalizations.
5. **`/etc/skel` only seeds new users.** On machines with existing users, materialize with
   `omarchy refresh …` / `omarchy reinstall-*` or a migration.
6. **Never touch `/usr/share/omarchy/` by hand** on any machine; everything that lives there is placed
   by the package.
7. **Never commit private keys** (private GPG, deploy keys). The repo is public; private material
   lives only as Action secrets.
8. Follow the **upstream conventions**: the root `AGENTS.md` (dev of the base repo), the
   `agents/skills/*` guides and `docs/file-layout.md`.

---

## Current state (single source)

Do not duplicate the version table here: it is the **single source of truth for project state** and
lives in `docs/personal/README.md`. The currently published and installed pair: see there.

---

## Relationship with the notes repository (scratchpad)

The scratchpad (`robert-flo/scratchpad`) remains as **history** for future reference (full log,
snapshots). **From now on the fork is the operational source**, and this tree
(AGENTS.personal.md + skill + `docs/personal/`) is where work happens and is kept up to date. In case
of contradiction, what is written here prevails.
