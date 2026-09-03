# Personal fork glossary

Terms used in this fork's documentation. One definition per term; if something is missing, look first
at the upstream terms (`docs/` of the source repo).

| Term | What it is (in this project) |
|---|---|
| **Action / `release-personal.yml`** | GitHub Actions workflow on `robert-flo/omarchy-pkgs` that builds and publishes the personal pacman repo on GitHub Pages. |
| **bootstrap** (machine) | `docs/personal/machine-bootstrap/bootstrap-omarchy-machine.sh` — one script, two modes: `--child` (machine that only *receives*: trust key → install pair → refresh pacman → `omarchy update` → `omarchy provision user --force` → `reinstall pkgs`) and `--dev` (build machine: clone layout + install the local `-dev` pair). The executable form of onboarding/recipes W8. |
| **bootstrap** (dev, historical) | The old dev-only phase, formerly `scratchpad/bootstrap-omarchy-dev.sh`; now the `--dev` mode of the machine bootstrap. |
| **launcher bootstrap** (removed PoC) | `bin/omarchy-personal-bootstrap-launchers`; the Stage-2 proof of concept, **removed** once its logic was absorbed: system packages → `omarchy-base.packages`; CLIs → `install/user/mise.sh` (`omarchy-mise-install`); heavy/AUR tools → lazy first-use stubs provisioned by `install/user/launchers.sh` (`omarchy-install-mimo`, `omarchy-install-opencode-desktop`, `omarchy-install-aur`); openclaw gateway → `omarchy-install-service-openclaw`; Hermes Web shim → `omarchy-install-hermes-cli`; `~/src` → `install/user/mise-work.sh`. |
| **cadence / sync** | The routine of keeping the fork up to date with `upstream/quattro` (rebase → re-pin → re-release). |
| **`clean` / clean-repo** | Pipeline step that prunes old versions of the published repo → there is no "rollback" (roll-forward). |
| **db / database file** | Pacman repo database (`omarchy.db`; alias `omarchy-personal.db` by section). |
| **deploy key** | SSH key (secret `SSH_DEPLOY_KEY`) to write to the `gh-pages` of `omarchy-personal-repo`. |
| **dispatch** | Trigger the workflow: `gh workflow run release-personal.yml … --ref personal -f version=…`. |
| **`dry_run`** | Action mode that rehearses everything without publishing anything. |
| **fork** | The personal forks: `robert-flo/omarchy` (source) and `robert-flo/omarchy-pkgs` (packages), branch `personal`. |
| **gh-pages** | Branch of `omarchy-personal-repo` served as a static web site (the pacman repo files). |
| **guard §5.3** | Action step that aborts if the personal pair would fall behind official stable. |
| **fail-fast guard** | Action step that aborts if the workflow was triggered from a branch ≠ `personal`. |
| **first-use / lazy stub** | An idle launcher in `~/.local/bin/<cmd>` that installs its tool on the first actual launch (like `~/.local/bin/ori`), never at provision time. Covers mise CLIs, heavy GUI tools and AUR pkgs. |
| **`omarchy-install-aur`** | `omarchy install aur <package> <binary>`. Writes a first-use stub for an AUR package: cold path runs `omarchy-pkg-aur-add <pkg>` then `exec /usr/bin/<bin>` by absolute path; inert once `/usr/bin/<bin>` exists (it shadows the stub on PATH). |
| **`omarchy-install-mimo`** | `omarchy install mimo [--stub]`. Installs MiMo (official binary) now, or `--stub` writes the lazy `~/.local/bin/mimo` launcher. |
| **`omarchy-install-opencode-desktop`** | `omarchy install opencode desktop [--stub]`. Installs the OpenCode Desktop AppImage now, or `--stub` writes the lazy launcher. |
| **`omarchy-install-service-openclaw`** | `omarchy install service openclaw`. Installs + enables the `openclaw-gateway` systemd user service (dashboard `http://127.0.0.1:18789`). The deliberate non-lazy case: a systemd service is never spawned from a launcher stub. Needs the `openclaw` CLI present first. |
| **keyring / key trust** | `pacman-key --add` + `--lsign-key` of the personal public key on each machine. |
| **lockstep (pair)** | `omarchy` and `omarchy-settings` are built from the same commit/source and share `pkgver`/`pkgrel`/`_tag`/`_commit`; `omarchy` depends on `omarchy-settings=${pkgver}` exactly. |
| **Decision Matrix** | The canonical table in `SKILL.md` that decides WHERE each fork change goes (config / web app / command / wrapper / set / migration). |
| **`omarchy provision user --force`** | Forcibly re-runs the per-user finalization (`install/user/all.sh` incl. `launchers.sh` + `mise.sh`). Needed because `omarchy update` installs the pair but does **not** re-provision an existing `$HOME` (gated by the `finalize-user` marker); run it after an update that ships new launchers/stubs. |
| **`omarchy update`** | Update flow that maintains machines; updates what is installed, does not install new packages, and does not re-provision user state. |
| **pair (lockstep)** | The `omarchy` + `omarchy-settings` package pair. |
| **pin / pin engine** | `bin/omarchy-pkgs release` rewrites the pair with `_tag`/`_commit`/`pkgver`/`sha256sums` of the base commit. |
| **`pinned`** | `"pinned": true` marker in the PKGBUILD's `.omarchy/package.json`: requires a temporary local un-pin to build to `stable`. |
| **`personal: true`** | `"personal": true` marker in the PKGBUILD's `.omarchy/package.json`: makes the Action publish it to the personal repo. |
| **`pkgrel`** | Version component after the hyphen (`<CURRENT_PAR>`); in the personal pair it is a re-publication counter (base 99, +1 per re-publication of the same `pkgver`, derived automatically). |
| **`pkgver`** | Package version (`x.y.z`); in the personal pair = the upstream base tag of the `personal` branch. |
| **personal repo** | `robert-flo/omarchy-personal-repo` (Pages), a `stable`-only pacman repo. |
| **shading / partial shadow** | `[omarchy-personal]` BEFORE `[omarchy]`: the pair and personal extras are served from the personal repo, the rest of the ecosystem from the official mirror. |
| **stable** | The only channel published by the personal repo. |
| **temporary un-pin** | Temporarily mark `"pinned": false` (not committed) so the pair builds straight to `stable`. |
| **`vercmp`** | The pacman version comparator (higher `pkgver` wins; at equal `pkgver`, higher `pkgrel` wins). |
| **web app** | An app served as a static `.desktop` (`applications/`); any new `.desktop` enters the package without touching the PKGBUILD. |
