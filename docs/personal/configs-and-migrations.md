# User configs and migrations

How to materialize `~/.config` configs and write migrations for one-off changes on existing machines.
These correspond to the **"User config"** and **"Provisioning / migration"** rows of the Decision
Matrix (`SKILL.md`).

## User configs (`config/<app>/`)

- The file lives in `config/<app>/<file>` of the fork (mirrors `~/.config`), e.g.
  `config/kitty/kitty.conf` (already in the fork).
- `omarchy-settings` seeds them to `/etc/skel/.config` (new users) and `/usr/share/omarchy/config`
  (resync source for existing users).
- Apply to an existing user:
  - `omarchy refresh config <relpath>` — copies `$OMARCHY_PATH/config/<relpath>` to
    `~/.config/<relpath>` (with backup).
  - `omarchy refresh shell`, `omarchy refresh hyprland`, etc. — refresh a whole component.
  - `omarchy reinstall-configs` — re-copies all of `/etc/skel` over `$HOME` (**nuclear**, destructive).
- On a packaged install, `$OMARCHY_PATH=/usr/share/omarchy`.

> Key rule: **`/etc/skel` only seeds new users** (at `useradd`). Changing the package does NOT touch
> existing users; materialize with a refresh or a migration.

## Third-party wrappers (mise / npm / official) in `~/.local/bin`

These are NOT "configs" but their own Decision Matrix row (**"Third-party wrapper"**):

- The logic lives in `install/user/*.sh` (e.g. `install/user/mise.sh`) + `omarchy-mise-install
  <package> <cmd>` / `omarchy-install-*` lines.
- `omarchy refresh applications` runs `install/user/*.sh`, which writes idempotent stubs in
  `~/.local/bin/<cmd>`.
- They are packaged into `omarchy-settings`; they travel via `omarchy update`.

## Migrations (`migrations/*.sh`)

When a personalization must touch **existing state** (not just source files), the upstream mechanism
is migrations:

- `migrations/<unix-timestamp>.sh`, run per user via `omarchy-migrate` (markers in
  `~/.local/state/omarchy/migrations/`).
- Follow `agents/skills/migrations.md`.
- Rules: **idempotent**, run as the user, privileged work via a helper, one repair per file.
- Tied to package versions: a machine upgrading from the old pair to the new one runs the new
  migrations. They are packaged into `omarchy` (`migrations/` → `/usr/share/omarchy/migrations/`).

### When a refresh vs. a migration

- **Refresh** (dev): applies the change **right now** to the dev machine.
- **Migration**: makes **every existing machine** apply it automatically on its next `omarchy update`.
  The key distinction for the MACHINES scenario: existing users do not re-copy `$HOME` on their own;
  either a manual refresh (dev) or a migration (once per machine).

## Provisioning / setup scripts

- `install/` holds per-user setup leafs (`install/user/*.sh`) and per-system leafs
  (`install/hardware/`), orchestrated by `omarchy-apply-system` / `omarchy-finalize-user`.
- Follow `agents/skills/install-scripts.md`. Use `$OMARCHY_INSTALL` / `$OMARCHY_PATH`, not
  hard-coded paths. `install/user/` leafs may omit the shebang and are sourced/deployed.
