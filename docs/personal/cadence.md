# Cadence — sync the fork with upstream and re-publish

Routine to keep the fork up to date with `upstream/quattro` and re-publish, so the personalization
never falls behind official stable (the `pkgrel` rule / guard §5.3). Follow it **after each upstream
release** (tag `vX.Y.Z` on `quattro`) or when `omarchy update` on the dev machine announces it.

## Sync + re-publish

1. In the checkout (branch `personal`):

   ```bash
   git fetch upstream
   git rebase upstream/quattro      # onto the personal branch
   ```

2. Resolve conflicts if any (ideally never: personalizations should touch files upstream barely
   moves; if one conflicts, consider whether your change belongs upstream).
3. Run `./test/all`, `git push origin personal` and **run the release Action** (W7) with the `pkgver`
   of the newly-rebased tag (`pkgrel` is derived automatically).
4. On each machine: `omarchy update` (and `omarchy reinstall pkgs` if the package list changed).

```bash
# in the checkout
git fetch upstream && git rebase upstream/quattro
git push origin personal
# in ~/Work/omarchy/omarchy-pkgs
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v<UPSTREAM_TAG>
# optional: rehearsal without publishing anything
#   ... -f version=v<UPSTREAM_TAG> -f dry_run=true
```

## Post-sync checklist

1. [ ] Linear rebase without conflicts (`git rebase upstream/quattro`).
2. [ ] `git push origin personal`.
3. [ ] Dispatch with `--ref personal` and the new `pkgver`.
4. [ ] Run is green and "Validate the publication" OK (Pages serves the new pair + section alias + `.sig`).
5. [ ] On the dev machine: `omarchy update -y`; `pacman -Q omarchy omarchy-settings` → personal version.
6. [ ] `sync-check.yml` does not open a new `[Cadence]` issue (or it closes on its own the next day).

## Minimal verification after publishing

```bash
curl -s <REPO_URL>/omarchy.db.tar.zst | bsdtar -xOf - omarchy/desc   # (adjust db name to the section)
pacman -Q omarchy omarchy-settings   # on a machine
```

## Automatic monitoring

- `sync-check.yml` (daily cron 06:30 UTC) compares the upstream tag against the pin and opens/closes a
  `[Cadence]` issue if upstream publishes and the pin falls behind. It is registered on `personal`
  (source) and `master` (so GitHub schedules it).
- The Action's "Guard §5.3" step aborts if the pair would fall behind official stable.
- "Validate publication on GitHub Pages" after each push verifies delivery (60×20 s margin).

## Rebase conflicts

Ideally there are none if your personal changes touch files upstream barely moves. If one of your
files conflicts with upstream, ask whether your change belongs upstream (it is in the spirit of the
project to contribute back) and resolve the conflict by hand like any rebase.

## Status / lag

If the machinery ever fails or the fork falls behind, see **`runbook.md`** (failure F4 — cadence lag).
Golden rule: **roll-forward, not rollback** (the published repo is pruned to the latest version).
