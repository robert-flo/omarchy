# Omarchy — Personal Fork

> **The Alternate Universe:** A customized layer over vanilla [Omarchy](https://omarchy.org), engineered to maintain $N$ personal machines identically and effortlessly via standard `omarchy update`.

---

## 1. Why This Fork Exists (The Philosophy)

Vanilla Omarchy (developed by [Basecamp / OMACOM](https://github.com/omacom/omarchy)) provides an opinionated, agentic, beautiful Linux distribution based on Arch Linux.

This fork exists to solve a specific operational challenge:
1. **Fleet Consistency:** Run multiple physical machines from the official Omarchy ISO, but have every machine automatically converge onto personal customizations without manual setup scripts, loose dotfiles, or divergent configurations.
2. **Standard Upstream Delivery:** Deliver all customizations through standard pacman packages consumed natively by `omarchy update`.
3. **Upstream Harmony & Contribution:** Maintain clean separation from upstream so official updates can be rebased continuously, and personal improvements can be cleanly contributed back upstream as Pull Requests to `quattro`.

---

## 2. The 4-Piece Puzzle (Local Workspace ↔ GitHub Cloud)

Our setup operates across multiple GitHub repositories coordinated locally within the `/pj-omarchy-fork/` workspace:

```mermaid
graph TD
    subgraph Local ["Local Workspace (pj-omarchy-fork/)"]
        L_Personal["robert-flo_omarchy-personal<br/>(branch: personal)"]
        L_Quattro["robert-flo_omarchy-quattro<br/>(branch: quattro)"]
        L_Pkgs["robert-flo_omarchy-pkgs<br/>(branches: personal, master)"]
        L_Repo["robert-flo-omarchy-personal-repo<br/>(branch: gh-pages)"]
        L_Scratch["robert-flo-scratchpad<br/>(branch: main)"]
    end

    subgraph GitHub ["GitHub Cloud (@robert-flo)"]
        GH_Omarchy["robert-flo/omarchy<br/>• personal (fork)<br/>• quattro (upstream mirror)"]
        GH_Pkgs["robert-flo/omarchy-pkgs<br/>• personal (fork recipes)<br/>• master (upstream mirror)"]
        GH_Repo["robert-flo-omarchy-personal-repo<br/>• gh-pages (pacman hosting)"]
        GH_Scratch["robert-flo/scratchpad<br/>• main (canonical docs)"]
    end

    subgraph Target ["Physical Machines"]
        Machine["End Machines<br/>(Runs 'omarchy update')"]
    end

    L_Personal -->|push origin personal| GH_Omarchy
    GH_Omarchy -->|triggers release-personal.yml| GH_Pkgs
    GH_Pkgs -->|publishes signed packages| GH_Repo
    GH_Repo -->|serves [omarchy-personal]| Machine
    L_Scratch -->|push origin main| GH_Scratch
```

### Component Breakdown

| Local Directory | GitHub Repository | Branch | Ecosystem Role |
| :--- | :--- | :--- | :--- |
| **`robert-flo_omarchy-personal`** | [`robert-flo/omarchy`](https://github.com/robert-flo/omarchy) | `personal` | **Fork Source Code:** Houses all personal configurations (`applications/`, `config/`, `themes/`, `bin/`), custom GPG trust, and pacman configuration. Rebased cleanly over `quattro`. |
| **`robert-flo_omarchy-quattro`** | [`robert-flo/omarchy`](https://github.com/robert-flo/omarchy) | `quattro` | **Upstream Mirror:** 100% pristine mirror of `omacom/omarchy:quattro`. Serves as the baseline for rebases and official upstream Pull Requests. |
| **`robert-flo_omarchy-pkgs`** | [`robert-flo/omarchy-pkgs`](https://github.com/robert-flo/omarchy-pkgs) | `personal` & `master` | **Packaging & Build Engine:** Recipes for `omarchy` and `omarchy-settings` (`"personal": true`, pinned with `pkgrel >= 99`), Docker build container, and GitHub Actions workflows (`release-personal.yml`, `sync-check.yml`). |
| **`robert-flo-omarchy-personal-repo`** | [`robert-flo-omarchy-personal-repo`](https://github.com/robert-flo/omarchy-personal-repo) | `gh-pages` | **Pacman Binary Repository:** Serves signed package databases (`omarchy-personal.db`, `.sig`, `.files`) and binaries via GitHub Pages. |
| **`robert-flo-scratchpad`** | [`robert-flo/scratchpad`](https://github.com/robert-flo/scratchpad) | `main` | **Canonical Architecture & Knowledge Base:** Contains the architectural specification ([`ARCHITECTURE.md`](https://github.com/robert-flo/scratchpad/blob/main/ARCHITECTURE.md)), master plan ([`agents_fork.md`](https://github.com/robert-flo/scratchpad/blob/main/agents_fork.md)), operational runbook ([`RUNBOOK.md`](https://github.com/robert-flo/scratchpad/blob/main/RUNBOOK.md)), and ADRs. |

---

## 3. The Machinery (How It Works)

### Layer 1: Pacman Shadowing
In `default/pacman/pacman-stable.conf`, the personal repository is declared **before** the official repository:
```ini
[omarchy-personal]
Server = https://robert-flo.github.io/omarchy-personal-repo/stable/$arch

[omarchy]
Include = /etc/pacman.d/omarchy-mirrorlist
```
Because pacman resolves duplicate packages from the first repository listed, `[omarchy-personal]` takes precedence over official upstream packages.

### Version Precedence (`pkgrel >= 99`)
To guarantee that `omarchy update` never replaces personal packages with official builds, the personal packaging recipes enforce a strict versioning rule:
- Official packages: `pkgver=4.0.x`, `pkgrel=1`
- Fork packages: `pkgver=4.0.x`, `pkgrel=99+` (e.g. `4.0.2-104`)

According to `vercmp`, version `4.0.x-104` will always supersede `4.0.x-1`, ensuring seamless shadowing.

### The Two Worlds (Operational Flows)

| World | Command / Workflow | When to Use | Result |
| :--- | :--- | :--- | :--- |
| **DEV** | `omarchy dev pkg-test` + `omarchy refresh <component>` | Iterating on the local development machine. | Builds and tests packages locally (`dev.<sha>`). Nothing is published. |
| **MACHINES** | `git push origin personal` → Action → `omarchy update` | Propagating approved changes to all computers in your fleet. | Builds, signs with GPG key `D5E75EAC51A44715`, and publishes to GitHub Pages. Running `omarchy update` on any computer pulls the new version. |

---

## 4. Mandatory Rules for Contributors & AI Agents

1. **Strict Branching Policy:**
   - **NEVER** push directly to trunk branches (`personal`, `quattro`, `master`, `gh-pages`).
   - **ALWAYS** create a dedicated working branch (`docs/...`, `feat/...`, `fix/...`), commit, push to the branch, merge into the target branch, and immediately delete the feature branch both locally and remotely:
     ```bash
     git branch -d <branch-name>
     git push origin --delete <branch-name>
     ```
2. **Canonical Decision Matrix:**
   - Before modifying or adding any file to the fork, consult the **Decision Matrix** in [`robert-flo-scratchpad/ARCHITECTURE.md`](https://github.com/robert-flo/scratchpad/blob/main/ARCHITECTURE.md) (§2) to ensure it is placed in the correct location (user config, desktop app, CLI tool, mise wrapper, or migration).

---

## 5. Upstream Omarchy Reference

This repository is a fork of [Basecamp / OMACOM Omarchy](https://github.com/omacom/omarchy). The official distribution manual is available in [`manual/`](manual/):

- [The Omarchy Manual](manual/01-welcome-to-omarchy.md)
- [Official Website](https://omarchy.org)
