# Recipes W1–W10 — exact personalization flows

Iterative dev cycle: **edit source → `omarchy dev pkg-test` → refresh the component → validate**.
The publish cycle is W7.

> **Mandatory gate:** before choosing a W#, classify the change in the **Decision Matrix**
> (see [`SKILL.md`](../../agents/skills/personal-fork/SKILL.md)). The right W# follows from the row;
> never the other way around.

Versions are read from the **State table** in [`README.md`](README.md) — they are not repeated here.

---

## W1 — Add a web app

1. Create `applications/<Name>.desktop`:

   ```ini
   [Desktop Entry]
   Version=1.0
   Name=<Name>
   Exec=omarchy-launch-webapp https://<domain>/
   Terminal=false
   Type=Application
   Icon=<icon_id>
   StartupNotify=true
   ```

   - `Exec` may be `omarchy-launch-webapp <url>` or a custom handler.
   - If it handles a scheme (mailto, zoommtg…): `MimeType=x-scheme-handler/<scheme>` and, where
     applicable, `xdg-mime default <Name>.desktop <scheme>`.
2. Icon in `applications/icons/<Name>.png` (or `.svg`). `<icon_id>` = name **lowercased** +
   non-alphanumerics → `-` (`Google Photos.png` → `google-photos`). The `.desktop` `Icon=` must use
   that `icon_id`.
3. Dev cycle: `omarchy dev pkg-test omarchy-settings` → `omarchy refresh applications`.
4. **Validate:** it appears in the launcher; it opens in a frameless web-app window.

> Watch out (common mistake): rebuilding the package does NOT materialize the `.desktop` into an
> existing user; you must run `omarchy refresh applications`.

`Exec` rules:
- `omarchy-launch-webapp <URL>`; if the URL contains reserved characters (`?&#`…), wrap it in double
  quotes. For launchers that need a shell (`cd "$HOME/src" && exec …`), the canon is
  `sh -c "…\"\$HOME…\"…"` (double quotes + `\"` and `\$`).

---

## W2 — Add an `omarchy-*` command

1. Create `bin/omarchy-<group>-<verb>` with shebang `#!/bin/bash` and metadata (`# omarchy:summary=`,
   `# omarchy:args=`, etc.). Follow `agents/skills/command-metadata.md` and `AGENTS.md`.
2. If it is a new group, register it in `GROUP_DESCRIPTIONS` of `bin/omarchy`.
3. The `omarchy` PKGBUILD captures `bin/*` by glob → **no PKGBUILD change needed**. Rebuild:
   `omarchy dev pkg-test omarchy`.
4. Add a CLI test if appropriate (`test/cli`, `test/shell.d/base-test.sh`); run `./test/all` before
   publishing.
5. **Validate:** `omarchy <group> <verb> --help`; `pacman -Ql omarchy-dev | grep my-command`.

---

## W3 — Executables in `~/.local/bin`

- **Case A (default, recommended):** if it fits as a system command → publish it as a `bin/omarchy-*`
  command (W2). It goes to `/usr/bin`, packaged on its own, directly contributable.
- **Case B — a user script that must live in `~/.local/bin`:**
  1. Put it in `default/local-bin/<name>` (the `env-bootstrap` already adds `~/.local/bin` to PATH).
  2. In the `omarchy-settings` PKGBUILD, per file:
     `install -Dm755 default/local-bin/<name> "$pkgdir/etc/skel/.local/bin/<name>"`.
  3. New users receive it at creation; existing users via `omarchy reinstall-configs`.
  4. **Validate:** the command resolves from the shell in a new user (or after `reinstall-configs`).

Dev alternative (no rebuild): `omarchy dev link` and copy to `~/.local/bin` by hand while iterating;
the source of truth remains `default/local-bin/`.

---

## W4 — Change user configs (`~/.config`)

1. The file lives in `config/<app>/<file>` of the fork (mirrors `~/.config`), e.g.
   `config/kitty/kitty.conf`.
2. `omarchy-settings` seeds them to `/etc/skel/.config` (new users) and `/usr/share/omarchy/config`
   (resync).
3. Apply to an existing user: `omarchy refresh config <relpath>` (e.g. `kitty/kitty.conf`),
   `omarchy refresh shell`, `omarchy refresh hyprland`, etc. Each refresh makes a backup before
   copying.
4. Dev: `omarchy dev link` points `$OMARCHY_PATH` at the checkout, so refreshes read from the fork.
5. **Validate:** for hypr `hyprctl configerrors`; re-open the bar for `shell.json` (hot-reload).

---

## W5 — Add / modify a theme

1. Stock (all machines): `themes/<name>/` with `colors.toml` and, if themed colors are used in
   templates, `default/themed/*.tpl`. The `omarchy` package ships `themes/` → rebuild
   `omarchy dev pkg-test omarchy`.
2. Apply with `omarchy theme set <name>` (see `docs/theming.md`).
3. Personal non-shareable theme: `~/.config/omarchy/themes/<name>/` (outside the fork) — but the norm
   is **in the fork** (identical machines).
4. **Validate:** `omarchy theme set` with no errors and the visual scheme changes.

---

## W6 — System package set (identical machines)

1. Add/remove in `install/omarchy-base.packages` (base set) and/or `install/omarchy-other.packages`.
2. A new ISO pacstraps those lists. For existing machines: `omarchy reinstall pkgs` installs
   `--needed` EVERYTHING listed and aligns versions. A package only uninstalled: `omarchy pkg drop`,
   but if it remains in `base.packages` it will come back — decide whether it also leaves the fork's
   list.
3. If a package is not in Arch/AUR and should enter the official flow: follow `omarchy-pkgs`
   (`bin/add-package ... --local`), do not invent a separate repo.
4. **Validate:** `omarchy update` + `omarchy reinstall pkgs` and compare `pacman -Qq` across machines.

---

## W7 — Publish personal packages (the core piece)

Status: **implemented, verified and generalized** (2026-09-01). The Action no longer hard-codes the
pair: it publishes **all** PKGBUILDs with `"personal": true`. Full detail in
[`release-pipeline.md`](release-pipeline.md). Summary:

Preconditions (verified): dedicated GPG key (`<GPG_KEY_ID>`, no passphrase); secrets
`GPG_PRIVATE_KEY`, `GPG_PASSPHRASE="unused"` and `SSH_DEPLOY_KEY` (deploy key write to
`omarchy-personal-repo`) in `robert-flo/omarchy-pkgs`. The workflow is committed on `personal` **and a
record copy on `master`**.

> **CRITICAL — dispatch ALWAYS with `--ref personal`.** The Action has a fail-fast guard: if
> `github.ref != refs/heads/personal` it aborts before touching anything. Without `--ref`, GitHub uses
> the `master` workflow (record copy) and the run re-publishes wrongly (historical incident).

**Trigger:**

```bash
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v<UPSTREAM_TAG>
```

Variants:
- Rehearsal without publishing anything: add `-f dry_run=true`.
- Emergency override of the pair's `pkgrel`: `-f pkgrel=<n>`.
- Two simultaneous dispatches join a queue (concurrency group); they never interleave.

**Lifecycle of a personal package:** `omarchy update` runs `pacman -Syu` (+AUR + mise): it
**updates** already-installed packages, it does **NOT** install new ones. A new personal package is
installed **once** on each machine with `pacman -S <pkg>`; from then on `omarchy update` maintains it.
If it must be on ALL machines from onboarding, add it to `install/omarchy-base.packages` of the source
fork.

---

## W8 — Apply personalizations to a new machine (onboarding)

x86_64 machine, installed with the official stable Omarchy ISO. Detail in
[`onboarding.md`](onboarding.md). Summary:

1. **Trust the personal key:** `pacman-key --add <key>.asc` + `pacman-key --lsign-key <GPG_KEY_ID>`.
2. **Bootstrap the personal pair** (first boot): download the pair `.pkg.tar.zst` (+`.sig`) from
   GitHub Pages and `sudo pacman -U` both together (same version).
3. **`omarchy refresh pacman`** → writes the fork's `pacman.conf`/mirrorlist (already with
   `[omarchy-personal]` BEFORE `[omarchy]`).
4. **`omarchy update`** → convergence (packages + migrations + hooks).
5. **`omarchy reinstall pkgs`** → reconcile the set with `install/omarchy-base.packages`.
6. **`omarchy reinstall-configs`** (optional; before creating users) → materialize `/etc/skel`.
7. **Validate:** `pacman -Q omarchy omarchy-settings` report the personal version; the web app appears
   in the launcher.

> Steps 1–4 are repeatable/automatable as an `bin/omarchy-install-*` command (the shape of the existing
> installers), NOT as a loose script.

---

## W9 — Sync the fork with upstream and re-publish

Cadence: after each upstream release (tag `vX.Y.Z` on `quattro`) or when `omarchy update` on the dev
machine announces it. Detail in [`cadence.md`](cadence.md). Summary:

1. In the checkout (branch `personal`):
   ```bash
   git fetch upstream
   git rebase upstream/quattro
   ```
2. Resolve conflicts if any (ideally never; if one conflicts, consider whether it belongs upstream).
3. `./test/all`, `git push origin personal` and **run the Action** (W7) with the `pkgver` of the
   newly-rebased tag.
4. On each machine: `omarchy update` (and `omarchy reinstall pkgs` if the package list changed).

---

## W10 — Migrations (one-off changes on existing machines)

When a personalization must touch **existing state** (not just source files), the upstream mechanism
is migrations: `migrations/<unix-timestamp>.sh`, run per user via `omarchy-migrate` (markers in
`~/.local/state/omarchy/migrations/`). Follow `agents/skills/migrations.md`. Rules: **idempotent**,
run as the user, privileged work via a helper, one repair per file. They are tied to package versions:
a machine upgrading from the old pair to the new one runs the new migrations.
