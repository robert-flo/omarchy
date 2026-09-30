# Personal Fork Changelog

This document tracks all custom changes, features, and fixes applied specifically to the **`personal`** branch of this Omarchy fork. 

Because upstream (`omacom/omarchy`) receives frequent commits and releases, this log serves as the authoritative record of personal customizations maintained on top of upstream, making it easy to audit differences without inspecting upstream git history.

## [2026-09-30]

### Key Rotation & v4.0.4-99 Release Alignment

- **Author:** Roberto Flores (`25asab015@ujmd.edu.sv`)
- **Resolved Issues:** `robert-flo/omarchy-pkgs#3`, `robert-flo/omarchy-pkgs#4`

#### What was changed:
1. **`keys/omarchy-personal-repo.pub.asc`**:
   - Rotated personal package signing key to dedicated 4096-bit RSA key `CD92AB07B1D24DC9A74EB60E76AFFCC217DB9FC4` (`76AFFCC217DB9FC4`) following ADR-006 DR procedure.
2. **`default/pacman/pacman-stable.conf`**:
   - Updated documentation comment to reference new key fingerprint `CD92AB07B1D24DC9A74EB60E76AFFCC217DB9FC4`.
3. **`README.md`**:
   - Updated consumer machine onboarding instructions with the new GPG key ID and target binary packages (`omarchy-4.0.4-99` and `omarchy-settings-4.0.4-99`).

### Upstream Fast-Forward & Personal Rebase Workflow

- **Author:** Roberto Flores (`25asab015@ujmd.edu.sv`)
- **Resolved Issues:** [`robert-flo/omarchy#1`](https://github.com/robert-flo/omarchy/issues/1)

#### What was changed:
1. **`.github/workflows/sync-upstream.yml`**:
   - Added standalone `workflow_dispatch` workflow for automated or manual Fast-Forward of `quattro` from `omacom/omarchy:quattro` and clean rebase of `personal`.
   - Incorporates automated conflict detection and GitHub Issue creation with manual resolution instructions upon collision.
2. **Deploy Key Authentication:**
   - Authorized deploy key `omarchy-source-sync` with write permissions to support automated push operations from the CI/CD pipeline.

---

## [2026-09-29]

### `acad076a` — personal: shade official omarchy with the personal pacman repo

- **Commit Hash:** [`acad076a0d5e790c79adab86e3fd1e83f0c4effa`](https://github.com/robert-flo/omarchy/commit/acad076a0d5e790c79adab86e3fd1e83f0c4effa)
- **Author:** Roberto Flores (`25asab015@ujmd.edu.sv`)
- **Parent Commit (Upstream Base):** `8b4eae66da2938ba9559f103b18dbf85cdf28a70`

#### What was changed:
1. **`default/pacman/pacman-stable.conf`**:
   - Inserted the `[omarchy-personal]` repository block immediately before the upstream `[omarchy]` section:
     ```ini
     # Repositorio de personalizacion del fork. Va ANTES de [omarchy] para
     # sombrearlo con el par personal. Dbs y paquetes van firmados con la clave
     # del repo personal (D5E75EAC51A44715): confiar esa clave en el keyring.
     # Hereda el SigLevel global (Required DatabaseOptional).
     [omarchy-personal]
     Server = https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64

     [omarchy]
     Server = https://pkgs.omarchy.org/stable/$arch
     ```
2. **`keys/omarchy-personal-repo.pub.asc`**:
   - Added the official 4096-bit RSA GPG public signing key for `Omarchy Personal Repo (robert-flo pacman repo signing) <omarchy-personal@robert-flo.github.io>` (Key ID: `46A51DFFA19CFB26B2937A48D5E75EAC51A44715`).

#### Why it was done (Rationale):
- **Package Shadowing Layer:** In this fork architecture, personal package pairs (`omarchy` and `omarchy-settings`) are built and hosted in the custom repository `omarchy-personal`. Placing `[omarchy-personal]` ahead of `[omarchy]` ensures pacman prioritizes the personal builds over upstream packages.
- **Automated Distribution:** Allows changes to propagate cleanly to all personal machines via standard `omarchy update` without requiring manual per-machine setup scripts.
- **Keyring Trust:** Shipping the public GPG key allows the system pacman keyring to verify and trust packages signed by the personal repository.
- **Upstream Rebase:** Rebased and verified on top of latest upstream `quattro` (`8b4eae66`), carrying forward 328 upstream updates while preserving the personal package shadow configuration intact.
