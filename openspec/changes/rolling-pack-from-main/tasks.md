# Tasks

## 1. Version, export and inspection

- [x] 1.1 Add a commit-version helper and a pack-version format check to `scripts/lib.sh`, and make `scripts/version-check.sh` keep the placeholder rule for `pack/pack.toml` and validate a given version in the new format instead of a release tag; the release-version and release-checkout helpers stay until task 2.2 removes their last caller; first show the current check rejecting `2026.11.17-dbb7da6`, then show it accepting that and rejecting `1.0.1`, `v1.0.1` and `2026.11.17-xyz1234` (verify: L1)
- [x] 1.2 Make `scripts/pack-export.sh` accept only the new version format and the placeholder, write `dist/cobblemon.mrpack` and `dist/cobblemon.env` (only `PACK_VERSION=<version>`), default to the version of the checked-out commit, and name the pre-filled entry `<display name> (<version>)`; make `.gitignore` track only those two files in `dist/`; first show the current export writing a versioned file name and no version file (verify: L1, L2)
- [x] 1.3 Make `scripts/pack-inspect.sh` and `scripts/pack-inspect.py` inspect `dist/cobblemon.mrpack` by default, take the expected version as an option and check the version format and the versioned entry name; show a fresh export passing and a pack with the old entry name and one with a wrong expected version failing (verify: L2)
- [x] 1.4 Add `scripts/pack-publish.sh` with a dry-run mode: it rebuilds with the committed pack's version, compares archive members byte for byte, and reports either "unchanged" or the version it would commit with both files in `dist/`; show "unchanged" for an untouched tree and a would-commit report after a change to `pack/options.txt` that is then reverted (verify: L1, L2)

## 2. Server and smoke check

- [x] 2.1 Point the server at `/packs/cobblemon.mrpack` in `compose.yaml` and keep `PACK_VERSION` for the MOTD only, with a `${PACK_VERSION:?...}` message naming `COMPOSE_ENV_FILES=.env,dist/cobblemon.env`; remove `PACK_VERSION` from `.env.example`, leaving a comment that says where it comes from, and make `scripts/version-check.sh` refuse a `PACK_VERSION` in `.env.example`; make `scripts/lib.sh` use `.env,dist/cobblemon.env` when `COMPOSE_ENV_FILES` is unset and read `PACK_VERSION` from the version file; make `scripts/ci-env.sh` write `dist/cobblemon.env` from the version helper when it is missing; first show the current configuration rendering without the version file and the current version check accepting a `PACK_VERSION` in `.env.example`, then show the configuration refusing without the setting and naming it, rendering the version file's version in the MOTD with it, for production and staging, and the version check rejecting an `.env.example` that sets `PACK_VERSION` (verify: L1, L2)
- [x] 2.2 Update `scripts/smoke.sh` to accept the new version format and the placeholder, require `dist/cobblemon.mrpack` and `dist/cobblemon.env`, refuse a `PACK_VERSION` in `.env`, name both versions when the version file and the pack differ, and drop the release-tag checkout check; remove the release-version and release-checkout helpers from `scripts/lib.sh`, which then have no caller; first show the current smoke check accepting a `PACK_VERSION` in `.env`, then show it refusing that line and a mismatched version file before the server starts; remove the `PACK_VERSION` line from this machine's `.env` (no other line is touched or shown), then show a passing run (verify: L1, L3)
- [ ] 2.3 Run the persistence and restore checks on the rebuilt stack (verify: L4)

## 3. Branch acceptance on staging

- [ ] 3.1 Give `scripts/staging-clone-world.sh` an option naming the production checkout, so that run from a worktree it pauses production's saves and copies production's world (verify: L1)
- [ ] 3.2 Rehearse the procedure on this machine: add a worktree of a test branch, copy `.env`, build the branch's pack and version file, clone the world from the production checkout, run the staging stack and its smoke, persistence and restore checks from the worktree, then remove the worktree; stop production meanwhile if the Docker VM cannot hold both (verify: L3, L4)
- [ ] 3.3 Rewrite `docs/upgrade.md` around branch acceptance, publish on merge and a production `git pull` that brings the version file; update `docs/rollback.md` to revert on `main` or check out an earlier commit; update `docs/acceptance-checklist.md` to staging before the merge and production after the deployment (verify: L1)

## 4. CI

- [ ] 4.1 Remove the release trigger and the pre-release and release jobs; make the `pack` job export with the pushed commit's version and run `scripts/pack-publish.sh --dry-run`; make the `validate` and `smoke` jobs use the version file (written by `scripts/ci-env.sh` or by the export) instead of a `PACK_VERSION` in `.env` (verify: L1)
- [ ] 4.2 Add the `publish` job: pushes to `main` of the repository only, after `lint`, `validate` and `pack`; `contents: write`; real-host guard; `scripts/pack-publish.sh` committing only `dist/cobblemon.mrpack` and `dist/cobblemon.env` as `pack <version> [skip ci]`; serialized and never cancelled (verify: L1)
- [ ] 4.3 Push the branch and a `smoke/*` branch, and confirm lint, validate, pack with its dry-run report, and the hosted smoke, persistence and restore jobs pass (verify: L1, L2, L3, L4)

## 5. Documentation and rules

- [ ] 5.1 Update `README.md` (making a copy: push to `main`, keep the repository public, let the bot push; quick start: the pack and its version file are in the checkout, and `COMPOSE_ENV_FILES=.env,dist/cobblemon.env` is set once; the version contract; the fixed link) and the first-deployment steps of `docs/admin-guide.md`, including that the setting applies to every Compose command of the account and how to empty it for one command (verify: L1)
- [ ] 5.2 Update both player guides with the fixed link and comparing the entry name with the MOTD, keeping the same sections in both (verify: L1)
- [ ] 5.3 Update `AGENTS.md` (CI alone commits `dist/cobblemon.mrpack` and `dist/cobblemon.env`; `.env.example` lists every variable except `PACK_VERSION`; the placeholder rule; a release is a merge to `main`; the L3 and L5 descriptions) and mark `docs/adr/0004-git-tag-is-the-release-version.md` superseded; confirm with a search that no document still presents tag releases, release candidates or the Releases page as current (verify: L1)

## Workflow follow-up

- Present the change for the archive gate.
- After the merge to `main`: confirm the first `publish` run commits `dist/cobblemon.mrpack` and `dist/cobblemon.env` with the merge commit's version, the raw link serves it, and a documentation-only push commits nothing.
- On production: `git pull`, remove `PACK_VERSION` from `.env`, set `COMPOSE_ENV_FILES=.env,dist/cobblemon.env` in the shell profile once, run the smoke check, then send players the fixed link.
