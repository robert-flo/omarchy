# Web apps and launchers

How to add, change and remove web apps in the fork, and the state of the launchers that materialize
them on machines. Read this **in light of the "Web app / launcher" row of the Decision Matrix**
(`SKILL.md`) and the deprecated-launcher-bootstrap note.

## In Omarchy, web apps live inside the package

Web apps are **NOT** menu entries you add by hand: they are `.desktop` files that travel *inside* the
`omarchy-settings` package. In the fork repo they live at:

- `applications/<Name>.desktop` — the launcher.
- `applications/icons/<Name>.png` (or `.svg`) — the icon.

When building the package, the PKGBUILD captures them by glob (any new `.desktop` or icon enters
without touching the PKGBUILD):

1. Copies `.desktop` files to `/usr/share/omarchy/applications/`; from there
   `omarchy refresh applications` copies them to `~/.local/share/applications/` (the folder the user's
   launcher sees).
2. Converts the icon with `magick` to hicolor sizes
   `/usr/share/icons/hicolor/{256,48}x{256,48}/apps/<icon_id>.png`, where `icon_id` = name
   **lowercased** + non-alphanumerics → `-`.
3. Seeds the `.desktop` files into `/etc/skel/.local/share/applications/` for new users.

`Exec=` points to `omarchy-launch-webapp <URL>`, which opens the default browser in **app mode** (a
window with no navigation bar) via `uwsm-app -- <browser> --app=<url>`.

## The `.desktop` (template)

```desktop
[Desktop Entry]
Version=1.0
Name=Xataka
Exec=omarchy-launch-webapp https://www.xataka.com/
Terminal=false
Type=Application
Icon=xataka
StartupNotify=true
```

Quick rules:
- `Exec` is always `omarchy-launch-webapp <URL>` (or a custom handler). If the URL contains reserved
  characters (`?&#`…), wrap it in double quotes. For launchers that need a shell
  (`cd "$HOME/src" && exec …`), the canon is `sh -c "…\"\$HOME…\"…"` (double quotes + `\"` and `\$`).
- `Icon` = name in lowercase with spaces/accents → hyphen (`Google Photos.png` → `google-photos`).
- If it handles a scheme (mailto, ...): `MimeType=x-scheme-handler/<scheme>` and `xdg-mime default`.

## Add a web app (in 4 steps)

Work on the fork, branch `personal`:

```bash
cd <CHECKOUT>   # the omarchy fork checkout

# 1) Create the two files (model: applications/Xataka.desktop and icons/Xataka.png)
# 2) Commit
git add applications/<Name>.desktop applications/icons/<Name>.png
git commit -m "personal: add <Name> webapp"
git push origin personal
```

```bash
# 3) Publish (the Action re-runs the personal repo; pkgrel derived automatically)
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v<UPSTREAM_TAG>
```

```bash
# 4) On each machine: update and refresh launchers
omarchy update
omarchy refresh applications
```

## Change or remove a web app

- **Change** (URL, name, icon): edit the `.desktop`/icon, commit `personal: update <app>`, publish
  (step 3) and update (step 4).
- **Remove**: delete the two files, commit `personal: remove <app>`, publish and update. On existing
  machines, `omarchy refresh applications` removes the leftover launcher when refreshing.

## State of the launcher bootstrap (deprecated PoC)

Stage 2 harvested 60 new launchers (39 web apps + 19 TUI/custom + 2 Microsoft Edge) + their icons,
published in the `<CURRENT_PAR>` pair, **operational in dev** (the `<CURRENT_LAUNCHERS>` launchers in
the menu resolve their bins). To make them operational, a PoC was created,
`bin/omarchy-personal-bootstrap-launchers` (idempotent), which installs the dependencies the launchers
run (mise/npm CLIs, official installers, Hermes, `~/src`).

> **⚠️ DEPRECATED as a living mechanism.** That PoC is not the right path forward: the correct one is
> for its logic to live in `install/user/*.sh` + `omarchy-mise-install` (the "Third-party wrapper" row
> of the Decision Matrix) and to travel to machines via `omarchy update`. The script stays in `bin/`
> as a **reference/example of integration**, not as an active flow. Do not create new changes through
> that path.

### How the correct pattern works (third-party wrapper)

`omarchy refresh applications` → `install/user/mise.sh` → `omarchy-mise-install <package> <cmd>`
writes an idempotent stub in `~/.local/bin/<cmd>` (MISE_MINIMUM_RELEASE_AGE=0, `mise use -g` +
`exec mise x`). Live examples in the fork: `agy`, `opencode`, `omp`, `grok`, `gh`, `hey`, `ori`,
`ghui`, `hunk`, `codex`, `claude`, `playwright`, `pi`, + `omarchy-install-hermes-cli || true`. See
[`recipes.md`](recipes.md) (Third-party wrapper row) and
[`configs-and-migrations.md`](configs-and-migrations.md).
