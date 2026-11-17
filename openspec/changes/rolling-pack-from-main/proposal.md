# Proposal

## Why

Publishing a pack needs a tag, a GitHub release and, for testing, a release candidate, while players only ever need the current pack: once a new version is out the old one is useless. One permanent download link that always serves the pack on `main`, with merging to `main` as the only release step, removes that ceremony. Because merging then publishes to every player, acceptance has to happen before the merge.

## What Changes

- **BREAKING** The pack is published as one tracked file, `dist/cobblemon.mrpack` on `main`, downloaded from a fixed raw link. Every push to `main` rebuilds it in CI; when its contents change, CI commits it back to `main`, together with the version file `dist/cobblemon.env` (only `PACK_VERSION=<version>`), in one bot commit that names the new version and skips CI.
- **BREAKING** The pack version is derived from the commit that changed it, `YYYY.MM.DD-<7-character commit>`, instead of a release tag. Tag-triggered builds, release candidates, the pre-release job and the release-notes table are retired; existing releases stay as they are.
- **BREAKING** The deployment reads `PACK_VERSION` from `dist/cobblemon.env` instead of `.env`, so `git pull` brings the pack and its version together. The administrator sets `COMPOSE_ENV_FILES=.env,dist/cobblemon.env` once in the shell profile of the account that runs the server; `PACK_VERSION` leaves `.env.example`, so Compose refuses to start without the setting, and the helper scripts supply it themselves. The smoke check refuses a `PACK_VERSION` left in `.env` and a version file that disagrees with the pack. The check that the checkout carries a release tag is removed: the pack now comes from the checkout itself.
- The pre-filled server entry carries the pack version in its name, so players compare it with the version in the MOTD.
- Acceptance moves before the merge: staging checks out a branch, builds that branch's pack on the host and runs the gameplay checklist; only then is the branch merged.
- `AGENTS.md`, the README, the administrator, upgrade, rollback and player documents follow; `.gitignore` tracks `dist/cobblemon.mrpack` and `dist/cobblemon.env`; ADR 0004 is marked superseded.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `mrpack-distribution`: the release requirements are replaced by a rolling build on `main` with a fixed link, a commit-derived version and a bot commit; export writes the fixed file name and the version file; inspection takes the expected version explicitly; the workflow's write access moves to the publishing job; template copies publish by pushing to `main`; the player guide uses the fixed link.
- `compose-services`: the server installs the fixed pack file from the checkout and reads its version from the committed version file; the version check accepts the new format, refuses a version left in `.env` and compares the version file with the pack; the release-tag checkout check is removed; staging can run a branch and its pack for acceptance.
- `public-server-info`: the pre-filled entry's name carries the pack version.
- `game-requirements`: the gameplay checklist runs on staging before the merge and on production after the deployment.

## Impact

- `.github/workflows/ci.yml`, `.gitignore`, `.env.example`, `compose.yaml`, `compose.staging.yaml`.
- `scripts/lib.sh`, `scripts/ci-env.sh`, `scripts/pack-export.sh`, `scripts/pack-inspect.sh`, `scripts/pack-inspect.py`, `scripts/version-check.sh`, `scripts/smoke.sh`, `scripts/staging-clone-world.sh`; new `scripts/pack-publish.sh`.
- `AGENTS.md`, `README.md`, `docs/admin-guide.md`, `docs/upgrade.md`, `docs/rollback.md`, `docs/player-guide.md`, `docs/player-guide.zh-TW.md`, `docs/acceptance-checklist.md`, `docs/adr/0004-git-tag-is-the-release-version.md`.
- Players: the download link changes once. Administrators: deployments come from `git pull` instead of a downloaded file; once, they remove `PACK_VERSION` from `.env` and set `COMPOSE_ENV_FILES` in the shell profile, which then applies to every Compose command of that account. Template copies must stay public for the raw link to work, and the bot must be allowed to push to `main`.
