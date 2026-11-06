# Tasks: compose-cobblemon 1.0.0

Branch `feat/cobblemon-1.0.0`. One commit per task. Details, dependencies and checkpoints in `tasks/plan.md`.

## Phase 1: Foundation and pack

- [x] Task 1: Lint harness and repo hygiene
  - Acceptance: `scripts/lint.sh` passes on the repo and fails on a known-bad scratch file; `.gitignore` covers all runtime paths
  - Verify: `scripts/lint.sh`; `git status --ignored`
  - Files: `.gitignore`, `scripts/lint.sh`, `.yamllint.yaml`, `.hadolint.yaml`

- [x] Task 2: packwiz tools image and `tools` profile
  - Acceptance: tools image builds, hadolint clean, `packwiz --help` and `python3 --version` run, files owned by host user
  - Verify: `scripts/lint.sh`; `docker compose config -q`; `docker compose --profile tools build`; `docker compose --profile tools run --rm packwiz --help`
  - Files: `tools/packwiz/Dockerfile`, `compose.yaml`, `.env.example`

- [x] Task 3: Pack skeleton with required mods, export and inspect scripts
  - Acceptance: `pack.toml` pins 1.21.1, Fabric loader, version 1.0.0; Cobblemon 1.8.4 and Fabric API installed; export produces `dist/cobblemon-1.0.0.mrpack`; inspect passes; refresh is a no-op
  - Verify: `scripts/pack-export.sh && scripts/pack-inspect.sh`; `git diff --exit-code pack/`
  - Files: `pack/pack.toml`, `pack/index.toml`, `pack/mods/cobblemon.pw.toml`, `pack/mods/fabric-api.pw.toml`, `scripts/pack-export.sh`, `scripts/pack-inspect.sh`

- [x] Task 4: Full 1.0.0 mod list with explicit sides
  - Acceptance: 14 mods present with sides per the plan's side table; inspect asserts every env marker; refresh is a no-op
  - Verify: `scripts/pack-export.sh && scripts/pack-inspect.sh`; `git diff --exit-code pack/`
  - Files: `pack/mods/*.pw.toml`, `pack/index.toml`, `scripts/pack-inspect.sh`

- [x] Task 5: Client overrides: `options.txt` and generated `servers.dat`
  - Acceptance: mrpack carries `overrides/options.txt` and a generated `overrides/servers.dat` with `SERVER_NAME` and `SERVER_PUBLIC_HOST`; `pack/` has no `servers.dat`; generator self-verifies
  - Verify: `scripts/pack-export.sh && scripts/pack-inspect.sh`; `git diff --exit-code pack/`
  - Files: `pack/options.txt`, `scripts/make-servers-dat.py`, `scripts/pack-export.sh`, `scripts/pack-inspect.sh`, `.env.example`

- [x] Checkpoint A: L1 and L2 green; human imports the mrpack into Modrinth App and reviews the side table and `options.txt`

## Phase 2: Production server

- [x] Task 6: Production server service and smoke test
  - Acceptance: `up -d` healthy within 10 min with local `MEMORY=3G`; status reports 1.21.1; no client-only JAR in `data/mods`; RCON not published; image pinned by multi-arch index digest; `SPEC.md` digest corrected
  - Verify: `scripts/lint.sh && docker compose config -q`; `scripts/smoke.sh`; `docker buildx imagetools inspect <ref>`
  - Files: `compose.yaml`, `.env.example`, `scripts/smoke.sh`, `config/server-icon.png`, `SPEC.md`

- [x] Task 7: Persistence and graceful shutdown test
  - Acceptance: orderly stop under 2 min with save evidence in the log; world and admin files survive restart; RED after `docker compose kill` fails clearly
  - Verify: `scripts/lint.sh`; `scripts/persist-test.sh`
  - Files: `scripts/persist-test.sh`, `compose.yaml`

- [x] Task 8: Backup sidecar and restore drill
  - Acceptance: startup backup and `backup now` both produce archives in `backups/`; restore drill extracts the newest archive and finds `world/level.dat` and `whitelist.json`; keep location confirmed outside prune scope
  - Verify: `scripts/lint.sh && docker compose config -q`; `scripts/restore-drill.sh`
  - Files: `compose.yaml`, `.env.example`, `scripts/restore-drill.sh`, `.gitignore`

- [x] Checkpoint B: L1 through L4 green locally; human reviews `docker compose config` output and `.env.example`

## Phase 3: Staging and release pipeline

- [x] Task 9: Staging override
  - Acceptance: staging config differs only in names, port, paths; prod and staging run together on 25565 and 25566; smoke passes against staging
  - Verify: `docker compose -f compose.yaml -f compose.staging.yaml config -q`; `COMPOSE_FILE=compose.yaml:compose.staging.yaml COMPOSE_PROJECT_NAME=cobblemon-staging scripts/smoke.sh`
  - Files: `compose.staging.yaml`, `scripts/smoke.sh`, `scripts/persist-test.sh`, `scripts/staging-clone-world.sh`, `.env.example`

- [x] Task 10: Version contract and release script
  - Acceptance: `version-check.sh` passes on HEAD and fails on mismatch; `release.sh --dry-run` prints steps; real run on a throwaway branch produces commit, tag and dist file
  - Verify: `scripts/lint.sh`; `scripts/version-check.sh`
  - Files: `scripts/version-check.sh`, `scripts/release.sh`, `docs/releases.md`

- [x] Task 11: CI workflow
  - Acceptance: actionlint and yamllint clean; after the human approves the push, `lint`, `validate`, `pack` jobs green; `release` job wired for `v*` tags; `smoke` on manual dispatch
  - Verify: `scripts/lint.sh`; GitHub Actions run link
  - Files: `.github/workflows/ci.yml`, `scripts/lint.sh`

- [x] Checkpoint C: `v1.0.0-rc.1` released by CI with the mrpack attached (run 41644430544); client test done with portablemc instead of Modrinth App/Prism (joined the local server, see docs/releases.md); the rc.2 `servers.dat` update test is moot because the player guide updates by installing a new profile

## Phase 4: Documentation and acceptance

- [x] Task 12: Player guide, English and Traditional Chinese
  - Acceptance: a person following only the guide installs rc.1 and joins staging; zh-TW mirrors EN section by section; links resolve
  - Verify: `scripts/lint.sh`; human read-through
  - Files: `docs/player-guide.md`, `docs/player-guide.zh-TW.md`

- [x] Task 13: Admin runbooks
  - Acceptance: every admin command executed once locally; upgrade SOP rehearsed on staging; rollback SOP rehearsed with the rc backup; checklist covers the ten Phase 1 items
  - Verify: `scripts/lint.sh`; rehearsal summary in the commit message
  - Files: `docs/admin-guide.md`, `docs/upgrade.md`, `docs/rollback.md`, `docs/acceptance-checklist.md`

- [x] Task 14: README, ADRs and clean-clone rehearsal
  - Acceptance: quick start works verbatim from a clean clone ending in a passing smoke; three ADRs with context, decision, consequences; links resolve
  - Verify: `scripts/lint.sh`; clean-clone transcript summary
  - Files: `README.md`, `docs/adr/0001-single-pack-for-client-and-server.md`, `docs/adr/0002-itzg-image-and-mc-backup-sidecar.md`, `docs/adr/0003-servers-dat-generated-at-export.md`

- [ ] Task 15: L5 acceptance on staging and the 1.0.0 release
  - Acceptance: checklist passes on staging and production with at least two players; SPEC success criteria 1 to 7 demonstrated; tag, `pack.toml`, mrpack name, `PACK_VERSION`, MOTD all read 1.0.0
  - Verify: `scripts/version-check.sh`; `scripts/smoke.sh && scripts/persist-test.sh && scripts/restore-drill.sh` on production
  - Files: `docs/acceptance-checklist.md`, `docs/releases.md`, `pack/pack.toml`, `.env.example`

- [x] Checkpoint D (2026-11-04): review, code-simplify and ship done; ship findings fixed; L3/L4 green on a Linux runner (run 41774973583). Remaining: Task 15 by the human, then tag v1.0.0

## Phase 5: The git tag is the release version (SPEC decision 10, 2026-11-06)

- [x] Task 16: Tag-derived version in the scripts
  - Acceptance: `pack-export.sh 9.8.7` writes `dist/cobblemon-9.8.7.mrpack` with internal version 9.8.7 and leaves git clean; default is `0.0.0-dev`; RED cases for inspect, version-check and smoke recorded; `scripts/release.sh` deleted
  - Verify: `scripts/lint.sh && docker compose config -q`; `scripts/pack-export.sh && scripts/pack-inspect.sh && scripts/version-check.sh`; `scripts/smoke.sh`
  - Files: `pack/pack.toml`, `.env.example`, `scripts/pack-export.sh`, `scripts/pack-inspect.sh`, `scripts/pack-inspect.py`, `scripts/version-check.sh`, `scripts/smoke.sh`, `scripts/release.sh` (deleted)

- [ ] Task 17: CI builds the pack when a release is published
  - Acceptance: trigger is `release: published`, no job on a bare tag push; release job derives the version from the tag, requires the real host, uploads the mrpack to the existing release and appends the pack contents table; branch builds stay green
  - Verify: `scripts/lint.sh`; GitHub Actions run on the branch push
  - Files: `.github/workflows/ci.yml`

- [ ] Task 18: Documentation for the release-from-GitHub flow
  - Acceptance: no document mentions `scripts/release.sh` or `docs/releases.md`; README "Make it yours" is enough to release without a clone; ADR 0004 written; `docs/releases.md` deleted; Task 15 wording updated
  - Verify: `scripts/lint.sh`; grep for the two removed names
  - Files: `README.md`, `docs/admin-guide.md`, `docs/upgrade.md`, `docs/adr/0004-git-tag-is-the-release-version.md`, `docs/releases.md` (deleted), `tasks/todo.md`, `tasks/plan.md`

- [ ] Checkpoint E: the human publishes pre-release `v1.0.0-rc.4` from the Releases page targeting this branch; CI attaches the mrpack with internal version 1.0.0-rc.4 and the real host; review; merge to `main`
