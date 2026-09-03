# Machine bootstrap — the two on-boarding flows

This folder holds `bootstrap-omarchy-machine.sh` — the single script that puts **any** machine onto
the personal Omarchy system, plus this explanation. Read it with the **two-scenario model** of
[`AGENTS.personal.md`](../../../AGENTS.personal.md) and the
[personal-fork skill](../../../agents/skills/personal-fork/SKILL.md) in mind: there are **exactly two**
kinds of machines, and the script mirrors that split with a flag.

> This absorbs what used to be `scratchpad/bootstrap-omarchy-dev.sh` (the old dev phase). As decided,
> the fork is the operational source; the scratchpad keeps the old copy as history. Do not duplicate a
> machine-setup helper elsewhere.

---

## The two machines (there is no third)

| Kind | Runs | Delivered by | After this, maintains itself with |
|---|---|---|---|
| **child** (`--child`) | `omarchy update` once, after the ISO | the **published package** (no local source) | `omarchy update` |
| **dev** (`--dev`) | builds from the **local checkout** | the **local** `-dev` pair | refresh commands (**not** `omarchy update`) |

A **child machine only receives**. It is the reliable, reproducible one: everything it gets comes from
the pair you publish, so it can't drift from the source. A **dev machine is where you build**; it
deliberately runs ahead of the published pair.

There is intentionally **no third mode**. If you find yourself wanting one (a machine that is partly
dev and partly child, or one that runs loose scripts), that is the Point of the decision matrix — stop
and re-ask rather than inventing a parallel delivery method.

---

## `--child` — the reliable path (default)

Use it on **every machine except the one(s) you build on**, right after installing the official stable
ISO. It is safe to re-run (idempotent) and is the reference flow in
[`onboarding.md`](../onboarding.md).

```bash
./bootstrap-omarchy-machine.sh --child
```

It does, in order:

1. **Trust the personal repo's public key** (`pacman-key --add` + `--lsign-key`). The public key lives
   in the fork (`keys/omarchy-personal-repo.pub.asc`) and is fetched from there; or pass `--key <path>`
   to use a local copy.
2. **Derive the published pair version from the personal repo's own pacman database** — never
   hard-coded (see the "no literals" rule in the State table). It reads the newest `omarchy-<version>`
   directory and takes its version.
3. **Install `omarchy-<version>` + `omarchy-settings-<version>` together** (lockstep, via the `.sig`
   verified automatically), so the exact-version dependency between them holds.
4. **`omarchy refresh pacman`** — writes the fork's `pacman.conf` with `[omarchy-personal]` **before**
   `[omarchy]` (partial shading).
5. **`omarchy update`** — full convergence (packages + migrations + hooks).
6. **`omarchy provision user --force`** — materializes configs, launchers and the lazy first-use stubs
   into the current user. See "the provision lesson" below — this is the step that fix the "why didn't
   the launchers appear?" symptom.
7. **`omarchy reinstall pkgs`** — reconciles the package set.
8. **Verifies** (`pacman -Q omarchy omarchy-settings`).

### The provision lesson (the one thing that isn't obvious)

`omarchy update` installs the pair but does **not** rewrite an existing user's `$HOME`. The
per-user finalization — which runs `install/user/all.sh`, and through it `install/user/launchers.sh`
and `mise.sh` — is gated by the `finalize-user` marker and is skipped once done. So after a pair update
that ships **new launchers or stubs**, you must re-run it explicitly:

```bash
omarchy provision user --force
```

(It is cheap and idempotent, which is why the script always runs it.) This is exactly what was
discovered validating the first real `omarchy update` on the dev machine in 2026-09-02: the pair was
`4.0.2-104` and the four commands registered, but the five lazy stubs had not materialized until this
command ran. Keep it in mind whenever you intro a new launcher/stub.

---

## `--dev` — where you build

Use it on **the** machine where you edit the fork. It clones the layout under
`~/Work/omarchy/{omarchy-installer,omarchy-pkgs,scratchpad}` with the `origin` (fork) and `upstream`
(official) remotes configured for the W9 rebase cadence, then builds and installs the **local** pair
`omarchy-dev` + `omarchy-settings-dev` from the working tree.

```bash
./bootstrap-omarchy-machine.sh --dev            # full: clone + build + install dev pair
./bootstrap-omarchy-machine.sh --dev --no-install   # clone/layout only
```

- `--no-install` stops before building; handy when you only want the layout.
- The build replicates `omarchy dev pkg-test` but uses **`pkexec`** instead of `sudo` (so it works
  without a TTY, per Omarchy's privilege rule), and installs **both** halves of the pair in a single
  `pacman -U --ask 4 --overwrite='*'` (they conflict with the stock pair and `omarchy` depends on
  `omarchy-settings=<pkgver>` exactly — see the script header for the full reasoning).

> **Warning (the reason dev is its own scenario):** a dev machine must **not** run `omarchy update`.
> The official repo also publishes `omarchy-dev`/`omarchy-settings-dev`, versioned with git-describe of
> quattro, and that version beats our `dev.<sha>` by `vercmp` — so `omarchy update` "upgrades" to the
> official dev pair and drops all local work. If this happens, re-run `--dev`; the script detects the
> mismatch and says so. (Recorded as the LESSON LEARNED of 2026-09-01 in the script header.)

---

## Getting the script onto a machine

Because it is in the fork, every machine can fetch it from the raw source (and the public key with it):

```bash
curl -fsSL -o bootstrap-omarchy-machine.sh \
  https://raw.githubusercontent.com/robert-flo/omarchy/personal/docs/personal/machine-bootstrap/bootstrap-omarchy-machine.sh
chmod +x bootstrap-omarchy-machine.sh
./bootstrap-omarchy-machine.sh --child   # or --dev
```

--child will fetch the key itself; use `--key <path>` if you prefer to supply it locally.

---

## Where this sits in the reasoning

- The **Decision Matrix** (`SKILL.md`) decides where a *change* goes — this script is not a change, it
  is the *delivery* of the two agreed scenarios, and it only calls existing `omarchy …` commands.
- It is the executable form of [`onboarding.md`](../onboarding.md) (`--child`) and of the old dev
  bootstrap (`--dev`).
- The **golden rule still holds**: after the first bootstrap, the only thing that maintains a child
  machine is `omarchy update` (+ `omarchy provision user --force` when a new par ships launchers).
