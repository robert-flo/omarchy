# Omarchy — Personal Fork

> **The Alternate Universe:** A tailored, reproducible layer over vanilla [Omarchy](https://omarchy.org), engineered to keep an entire fleet of personal machines identically configured and continuously updated via standard `omarchy update`.

---

## 1. Why This Fork Exists (Philosophy & Core Concept)

Vanilla Omarchy (developed by [Basecamp / OMACOM](https://github.com/omacom/omarchy)) provides an opinionated, beautiful, and agentic Linux distribution built on Arch Linux.

This fork exists to solve a fundamental operational challenge:
1. **Zero-Drift Fleet Consistency:** Run multiple physical machines installed from the official Omarchy ISO, but have every machine automatically converge onto personal customizations without snowflake dotfiles, divergent local hacks, or manual post-install scripts.
2. **Native Upstream Delivery:** Ship every configuration, webapp launcher, theme, CLI tool, and package override through standard pacman packages consumed natively by `omarchy update`.
3. **Upstream Harmony & Rebaseability:** Maintain clean separation from upstream so official releases can be rebased smoothly, while personal fixes or generic features can be cleanly contributed back upstream as Pull Requests against upstream `quattro`.

---

## 2. The Multi-Repository Ecosystem (The Puzzle Pieces)

Rather than maintaining a monolithic repository, the architecture is distributed across four modular repositories on GitHub:

```mermaid
graph TD
    subgraph Repos ["GitHub Cloud Infrastructure (@robert-flo)"]
        R_Source["robert-flo/omarchy<br/>• personal (custom fork source)<br/>• quattro (upstream clean mirror)"]
        R_Pkgs["robert-flo/omarchy-pkgs<br/>• personal (packaging recipes)<br/>• master (upstream packaging mirror)"]
        R_Pacman["robert-flo/omarchy-personal-repo<br/>• gh-pages (binary pacman repository)"]
        R_Docs["robert-flo/scratchpad<br/>• main (canonical architecture & runbooks)"]
    end

    subgraph Roles ["Machine Personas"]
        Dev["Dev Machine<br/>(Source changes + local pkg-test)"]
        Consumer["Fleet / Daughter Machines<br/>(Standard omarchy update)"]
    end

    Dev -->|1. push personal| R_Source
    R_Source -->|2. triggers release-personal Action| R_Pkgs
    R_Pkgs -->|3. builds, GPG signs & publishes| R_Pacman
    R_Pacman -->|4. pacman resolves [omarchy-personal]| Consumer
    R_Pacman -->|4. pacman resolves [omarchy-personal]| Dev
    R_Docs -.->|architectural guidelines| Dev
```

### Component Roles & Repositories

| Repository | Active Branch | Role in the Ecosystem |
| :--- | :--- | :--- |
| [**`robert-flo/omarchy`**](https://github.com/robert-flo/omarchy) | `personal` | **Fork Source Code:** Contains all custom configurations (`config/`), webapps (`applications/`), scripts (`bin/`), and package lists. Rebased continuously on top of `quattro`. |
| [**`robert-flo/omarchy`**](https://github.com/robert-flo/omarchy) | `quattro` | **Upstream Mirror:** 100% clean mirror of official `omacom/omarchy:quattro`. Serves as the immutable baseline for rebases and official upstream Pull Requests. |
| [**`robert-flo/omarchy-pkgs`**](https://github.com/robert-flo/omarchy-pkgs) | `personal` / `master` | **Packaging Engine & CI:** Houses the PKGBUILD recipes for the personal pair (`omarchy` & `omarchy-settings`), Docker build environment, and GitHub Actions automation ([`release-personal.yml`](https://github.com/robert-flo/omarchy-pkgs/blob/personal/.github/workflows/release-personal.yml)). |
| [**`robert-flo/omarchy-personal-repo`**](https://github.com/robert-flo/omarchy-personal-repo) | `gh-pages` | **Pacman Binary Repository:** Hosted on GitHub Pages. Serves the pacman package databases (`omarchy-personal.db`, `.sig`, `.files`) and binary packages signed by GPG key `D5E75EAC51A44715`. |
| [**`robert-flo/scratchpad`**](https://github.com/robert-flo/scratchpad) | `main` | **Canonical Knowledge Base:** The single source of truth for architectural specifications ([`ARCHITECTURE.md`](https://github.com/robert-flo/scratchpad/blob/main/ARCHITECTURE.md)), the Master Plan ([`agents_fork.md`](https://github.com/robert-flo/scratchpad/blob/main/agents_fork.md)), operational recovery ([`RUNBOOK.md`](https://github.com/robert-flo/scratchpad/blob/main/RUNBOOK.md)), and ADRs. |

---

## 3. The Machinery: How the Fork Operates

### Layer 1: Pacman Shadowing
In `default/pacman/pacman-stable.conf`, the personal repository is declared **before** the official repository:
```ini
[omarchy-personal]
Server = https://robert-flo.github.io/omarchy-personal-repo/stable/$arch

[omarchy]
Include = /etc/pacman.d/omarchy-mirrorlist
```
Because pacman resolves duplicate packages from the first repository listed, any package present in `[omarchy-personal]` **shadows** (overrides) the official package of the same name.

### Version Precedence (`pkgrel >= 99`)
To guarantee that `omarchy update` never accidentally replaces personal packages with official builds, the personal packaging recipes enforce a strict versioning rule:
- **Official packages:** `pkgver=4.0.x`, `pkgrel=1`
- **Personal packages:** `pkgver=4.0.x`, `pkgrel=99+` (e.g. `4.0.2-104`)

By Arch Linux package version comparison rules (`vercmp`), version `4.0.x-104` will always supersede `4.0.x-1`. Official upstream mirrors continue to supply the rest of the ecosystem (Hyprland, Waybar, Neovim, etc.) without modification.

---

## 4. How to Start Fresh: Dev Machine vs Daughter Machine

Every computer in your setup operates in one of two clearly defined roles:

```
┌────────────────────────────────────────────────────────┐
│                   STARTING FRESH                       │
└────────────────────────────────────────────────────────┘
                           │
         Is this machine used to modify the code?
          /                                    \
       YES                                      NO
        │                                        │
  ▼───────────▼                            ▼───────────▼
   DEV MACHINE                           DAUGHTER MACHINE
 (The "Factory")                          (The "Consumer")
```

### Option A: Setting Up a Dev Machine (The Factory)
*Use this role on the primary computer where you write code, customize configs, and develop the fork.*

1. **Clone the repositories:** Clone [`robert-flo/omarchy`](https://github.com/robert-flo/omarchy) (checkout `personal`) and [`robert-flo/scratchpad`](https://github.com/robert-flo/scratchpad).
2. **Iterate locally (Fast Dev Loop):**
   ```bash
   # Make a change in applications/, config/, bin/, etc.
   omarchy dev pkg-test         # Compiles and installs the package locally as dev.<sha>
   omarchy refresh <component>  # Materializes the change immediately (e.g., shell, hyprland, config)
   ```
   *In dev mode, packages are tagged `dev.<sha>`. Nothing is published to other machines.*
3. **Publish to the fleet:**
   When your changes are tested and ready:
   - Commit and push to `personal` using the strict branch workflow.
   - GitHub Actions ([`release-personal.yml`](https://github.com/robert-flo/omarchy-pkgs/blob/personal/.github/workflows/release-personal.yml)) automatically compiles the packages inside an Arch container, signs them with GPG key `D5E75EAC51A44715`, and publishes them to [`omarchy-personal-repo`](https://github.com/robert-flo/omarchy-personal-repo).

---

### Option B: Setting Up a Daughter Machine (The Consumer Fleet)
*Use this role on any other personal laptop or desktop where you want your personal environment delivered automatically without doing development work.*

A daughter machine is installed from the **standard official Omarchy ISO**. You onboard it into your personal universe **once**:

1. **Trust your personal GPG key (One-time setup):**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/robert-flo/scratchpad/main/keys/omarchy-personal-repo.pub.asc | sudo pacman-key --add -
   sudo pacman-key --lsign-key D5E75EAC51A44715
   ```
2. **Install the initial personal package pair:**
   ```bash
   # Download and install the current personal package pair from your repository
   sudo pacman -U \
     https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/omarchy-4.0.2-104-any.pkg.tar.zst \
     https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/omarchy-settings-4.0.2-104-any.pkg.tar.zst
   ```
3. **Configure pacman shadowing & converge:**
   ```bash
   omarchy refresh pacman       # Injects [omarchy-personal] before [omarchy]
   omarchy update               # Runs pacman -Syu, migrations, and hooks
   omarchy reinstall-configs    # Materializes user configurations from /etc/skel
   ```

### Day-to-Day Operation on Daughter Machines:
Once onboarded, **you never configure anything manually again**. Whenever you publish changes from your Dev machine, simply run:
```bash
omarchy update
```
Pacman detects the new personal package version, downloads it from GitHub Pages, runs migrations, executes post-update hooks, and synchronizes your environment automatically.

---

## 5. Mandatory Rules for AI Agents and Contributors

To maintain architectural integrity across all repositories, human developers and AI assistants must adhere strictly to these two rules:

### 1. Strict Git Branching Policy
- **NEVER** push directly to base branches (`personal`, `quattro`, `master`, `gh-pages`, `main`).
- **ALWAYS** create a feature branch (`feat/...`, `docs/...`, `fix/...`), push to the feature branch, merge into the target branch, and immediately delete the feature branch both locally and remotely:
  ```bash
  git checkout -b feat/my-change
  # ... make commits ...
  git push -u origin feat/my-change
  git checkout personal
  git merge --ff-only feat/my-change
  git push origin personal
  git branch -d feat/my-change
  git push origin --delete feat/my-change
  ```

### 2. The Decision Matrix
Before placing or moving any file in the fork, consult the **Decision Matrix** in [`robert-flo-scratchpad/ARCHITECTURE.md`](https://github.com/robert-flo/scratchpad/blob/main/ARCHITECTURE.md) (§2). Every customization must be categorized into its authoritative destination:
- **User configurations:** `config/<app>/` (installed to `~/.config/<app>/` via `omarchy-settings`).
- **Webapps & Launchers:** `applications/*.desktop` (installed to `~/.local/share/applications/`).
- **System executables:** `bin/omarchy-*` (installed to `/usr/bin/` via `omarchy`).
- **Third-party wrappers:** `install/user/*.sh` + `omarchy-mise-install`.
- **Migrations:** `migrations/*.sh` (executed automatically by `omarchy update`).

---

## 6. Official Omarchy Documentation

This repository is a fork of [Basecamp / OMACOM Omarchy](https://github.com/omacom/omarchy). The complete official user manual is available in [`manual/`](manual/):

- [The Omarchy Manual](manual/01-welcome-to-omarchy.md)
- [Official Website](https://omarchy.org)
