# Implementation Plan: compose-cobblemon 1.0.0

**Status:** DRAFT, awaiting human approval (SDD gate 2: Plan, and gate 3: Tasks via `tasks/todo.md`)
**Plan version:** 0.1.0 (2026-11-03)
**Source:** `SPEC.md` 0.2.0

## Overview

Fifteen tasks in four phases turn `SPEC.md` into a shipped 1.0.0. The order follows the dependency graph: lint harness and the packwiz tools image first, then the pack itself (the single source of truth), then the server that consumes the pack, then staging and the release pipeline, then documentation and the human acceptance pass. Every task leaves the repo in a state where `scripts/lint.sh` and every previously introduced check still pass. Each task is one commit on branch `feat/cobblemon-1.0.0`.

## Verified Facts Used by This Plan

Verified on 2026-11-03 (sources in `SPEC.md` plus the ones below).

| Fact | Value | Consequence |
|---|---|---|
| Cobblemon 1.8.4F for Fabric 1.21.1 | file `Cobblemon-fabric-1.8.4+1.21.1.jar`, only required dependency is Fabric API (`P7dR8mSH`) | No Kotlin runtime mod needed |
| All 14 planned mods | available for 1.21.1 on Fabric, all hosted on Modrinth | mrpack references CDN downloads; no JAR is redistributed |
| packwiz | no official container image; latest commit `170b22d785959dda5876b54b7f16e1b807a57fb6` (2026-10-14) | Build our own image from source at that commit |
| packwiz non-interactive use | `packwiz init --name --author --version --mc-version --modloader fabric --fabric-version/--fabric-latest`; `packwiz modrinth install <slug> -y`; `packwiz modrinth export -o <file>` | All pack operations are scriptable |
| packwiz side to mrpack env mapping | side `client` gives `server: unsupported`; side `server` gives `client: unsupported`; universal gives both | Explicit `side` per mod controls what the server installs |
| itzg `MODRINTH_MODPACK` | accepts a container path ending in `.mrpack` | Server mounts `./dist:/packs:ro` |
| itzg/mc-backup | `RCON_HOST`, `BACKUP_INTERVAL`, `PAUSE_IF_NO_PLAYERS`, `PRUNE_BACKUPS_DAYS`, `INITIAL_DELAY`, `BACKUP_ON_STARTUP`, `backup now` | Sidecar needs no custom scripting |
| GitHub remote | `github.com/gjchentw/compose-cobblemon` | CI and Releases are possible |
| Local dev machine | macOS arm64, Docker Desktop VM 4 CPU / 4.8 GB, bash 3.2, jq, python3 | Local smoke runs with `MEMORY=3G`; scripts must be bash 3.2 compatible; images must be multi-arch |

## Architecture Decisions (plan level)

Decisions already made in `SPEC.md` are not repeated. These are the implementation-level choices this plan adds; each becomes an ADR where marked.

1. **packwiz runs in our own image built from source** (`tools/packwiz/Dockerfile`, Go builder pinned by digest, packwiz pinned by commit). The host needs only Docker and bash. ADR 0002 covers this together with the itzg image choice.
2. **`servers.dat` is generated at export time, never committed.** The committed `pack/` holds no real hostname. `scripts/pack-export.sh` copies `pack/` to a build directory, writes `servers.dat` from `SERVER_PUBLIC_HOST` and `SERVER_NAME`, refreshes and exports there. `packwiz refresh` on the committed `pack/` therefore stays a no-op. ADR 0003.
3. **Explicit `side` per mod.** packwiz guesses sides from Modrinth metadata, which would put EMI and both Xaero's mods on the server (`server: optional`). The plan sets sides explicitly so the server installs only what it needs:

   | Mod | side | Server installs it |
   |---|---|---|
   | cobblemon, fabric-api | both | yes |
   | lithium, ferrite-core | both | yes (server performance) |
   | appleskin | both | yes (accurate hunger values) |
   | sodium, immediatelyfast, entityculling, modmenu, placeholder-api (Mod Menu dependency), mouse-tweaks | client | no |
   | emi, xaeros-minimap, xaeros-world-map | client | no |

4. **Image pins use the multi-arch index digest**, not a per-platform digest. The amd64 digest quoted in `SPEC.md` would fail to pull on the arm64 dev machine. Task 6 records the index digest and verifies both platforms with `docker buildx imagetools inspect`. `SPEC.md` is corrected in the same commit.
5. **Local `.env` for development uses `MEMORY=3G`**; `.env.example` keeps the production default `6G`. Smoke and persistence tests read the value from `.env` and do not care which.
6. **Staging is a Compose override plus a separate project name** (`-p cobblemon-staging`), not a second copy of the files.
7. **Release candidates are real releases.** `v1.0.0-rc.1` exercises the whole pipeline (tag, CI, GitHub Release, player install) before `v1.0.0`.

## Dependency Graph

```
T1 lint harness
 └─ T2 packwiz tools image
     └─ T3 pack skeleton + export + inspect
         └─ T4 full mod list with sides
             └─ T5 client overrides (options.txt, generated servers.dat)
                 └─ [Checkpoint A]
                     └─ T6 production server service + smoke (L3)
                         └─ T7 persistence + graceful stop (L4)
                             └─ T8 backup sidecar + restore drill (L4)
                                 └─ [Checkpoint B]
                                     ├─ T9  staging override
                                     ├─ T10 version contract + release script
                                     └─ T11 CI workflow
                                         └─ [Checkpoint C: v1.0.0-rc.1 published]
                                             ├─ T12 player guide EN + zh-TW
                                             ├─ T13 admin runbooks
                                             └─ T14 README + ADRs + clean-clone rehearsal
                                                 └─ T15 L5 acceptance + v1.0.0 release
                                                     └─ [Checkpoint D] → /review → /code-simplify → /ship
```

## Task List

### Phase 1: Foundation and pack

#### Task 1: Lint harness and repo hygiene

**Description:** Establish the L1 tooling every later task is verified with. Add `.gitignore` for every runtime path named in the spec, and `scripts/lint.sh` that runs hadolint, yamllint and shellcheck through pinned container images with repo-level config files. The script must run on bash 3.2.

**Acceptance criteria:**
- [ ] `scripts/lint.sh` exits 0 on the repo and exits non-zero when pointed at a scratch file with a known violation (the RED run is recorded in the commit message).
- [ ] `.gitignore` covers `.env`, `data/`, `backups/`, `staging/`, `dist/`, `*.log`, and any build directory the export uses.
- [ ] Nothing beyond Docker and bash is required on the host.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] `git status --ignored` lists the runtime directories as ignored once they exist

**Dependencies:** None
**Files likely touched:** `.gitignore`, `scripts/lint.sh`, `.yamllint.yaml`, `.hadolint.yaml`
**Estimated scope:** S

#### Task 2: packwiz tools image and `tools` profile

**Description:** `tools/packwiz/Dockerfile` builds packwiz from source at commit `170b22d7` in a Go builder stage pinned by digest, then copies the binary into a small runtime image with `python3` (needed by Task 5) and a non-root user. `compose.yaml` is created with a single `packwiz` service under profile `tools`, mounting the repo root at `/work`, with `user: "${UID:-1000}:${GID:-1000}"` so generated files belong to the host user on Linux hosts.

**Acceptance criteria:**
- [ ] `docker compose --profile tools build` succeeds and hadolint is clean.
- [ ] `docker compose --profile tools run --rm packwiz --help` prints packwiz usage; `python3 --version` works inside the image.
- [ ] A file created through the service is owned by the host user, not root.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] `docker compose config -q`
- [ ] the two run commands above, plus an ownership check with `ls -l`

**Dependencies:** Task 1
**Files likely touched:** `tools/packwiz/Dockerfile`, `compose.yaml`, `.env.example`
**Estimated scope:** S

#### Task 3: Pack skeleton with required mods, export and inspect scripts

**Description:** Initialise `pack/` non-interactively (name "Cobblemon Pack", version `1.0.0`, Minecraft `1.21.1`, Fabric loader resolved once with `--fabric-latest` and then written explicitly into `pack.toml`), install `fabric-api` and `cobblemon` at 1.8.4. Add `scripts/pack-export.sh` (copy `pack/` to a build directory, `packwiz refresh`, `packwiz modrinth export -o dist/cobblemon-<PACK_VERSION>.mrpack`) and `scripts/pack-inspect.sh` (unzip `modrinth.index.json`, assert with jq: game version, loader, expected mods, env markers).

**Acceptance criteria:**
- [ ] `pack/pack.toml` pins `minecraft = "1.21.1"`, an explicit Fabric loader version, and `version = "1.0.0"`; `pack/mods/cobblemon.pw.toml` resolves to `Cobblemon-fabric-1.8.4+1.21.1.jar`.
- [ ] `scripts/pack-export.sh` produces `dist/cobblemon-1.0.0.mrpack`; `scripts/pack-inspect.sh` passes and fails (RED) when run against an empty expectation list first.
- [ ] `packwiz refresh` on `pack/` leaves `git status` clean.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] `scripts/pack-export.sh && scripts/pack-inspect.sh`
- [ ] `docker compose --profile tools run --rm packwiz refresh && git diff --exit-code pack/`

**Dependencies:** Task 2
**Files likely touched:** `pack/pack.toml`, `pack/index.toml`, `pack/mods/cobblemon.pw.toml`, `pack/mods/fabric-api.pw.toml`, `scripts/pack-export.sh`, `scripts/pack-inspect.sh`
**Estimated scope:** M

#### Task 4: Full 1.0.0 mod list with explicit sides

**Description:** Install the performance and QoL mods decided in `SPEC.md`, set `side` in each `.pw.toml` according to the side table above, and extend `pack-inspect.sh` to assert every mod and its env markers. Run the extended inspect first so it fails (RED), then install.

**Acceptance criteria:**
- [ ] All 14 mods are present and each `.pw.toml` `side` matches the table.
- [ ] `pack-inspect.sh` asserts the env markers per mod and fails if any mod is missing or mis-sided.
- [ ] `packwiz refresh` is a no-op after the change.

**Verification:**
- [ ] `scripts/pack-export.sh && scripts/pack-inspect.sh`
- [ ] `git diff --exit-code pack/` after refresh

**Dependencies:** Task 3
**Files likely touched:** `pack/mods/*.pw.toml` (12 generated files), `pack/index.toml`, `scripts/pack-inspect.sh`
**Estimated scope:** M (generated files dominate)

#### Task 5: Client overrides: `options.txt` and generated `servers.dat`

**Description:** Commit `pack/options.txt` with the spec's client defaults (render distance 10, simulation distance 6, entity distance 75 %, particles decreased, biome blend 2, clouds fast, max FPS 120). Add `scripts/make-servers-dat.py` (stdlib only, runs inside the tools image) that writes an NBT `servers.dat` for `SERVER_NAME` at `SERVER_PUBLIC_HOST` and can verify its own output with `--verify`. Wire it into `pack-export.sh` so the file is generated in the build directory only. Extend `pack-inspect.sh` to assert both override files.

**Acceptance criteria:**
- [ ] The exported mrpack contains `overrides/options.txt` identical to `pack/options.txt` and `overrides/servers.dat` containing `SERVER_NAME` and `SERVER_PUBLIC_HOST` from `.env` (defaults from `.env.example`).
- [ ] `pack/` contains no `servers.dat`; `packwiz refresh` on `pack/` stays a no-op.
- [ ] `make-servers-dat.py --verify` parses its own output back and reports the host string.

**Verification:**
- [ ] `scripts/pack-export.sh && scripts/pack-inspect.sh`
- [ ] `git diff --exit-code pack/`

**Dependencies:** Task 4
**Files likely touched:** `pack/options.txt`, `scripts/make-servers-dat.py`, `scripts/pack-export.sh`, `scripts/pack-inspect.sh`, `.env.example`
**Estimated scope:** M

### Checkpoint A: Pack

- [ ] L1 green: `scripts/lint.sh`, `docker compose config -q`
- [ ] L2 green: export and inspect pass; `packwiz refresh` leaves the tree clean
- [ ] Human imports `dist/cobblemon-1.0.0.mrpack` into Modrinth App once; the game launches to the title screen with all 14 mods listed in Mod Menu
- [ ] Human reviews the side table and the `options.txt` values before proceeding

### Phase 2: Production server

#### Task 6: Production server service and smoke test

**Description:** Add the `cobblemon` service to `compose.yaml` exactly in the style of the `SPEC.md` Code Style block: image pinned by tag and multi-arch index digest, environment from `.env` with `:?` for secrets and `:-` defaults, `MODRINTH_MODPACK=/packs/cobblemon-${PACK_VERSION}.mrpack`, healthcheck with a 5 minute start period, `stop_grace_period: 2m`, volumes for `./data`, `./dist:/packs:ro` and a committed placeholder `config/server-icon.png`. Complete `.env.example`. Add `scripts/smoke.sh`: `up -d`, poll health until healthy or a 600 s timeout, query status through `mc-monitor` inside the container, grep the log for the Fabric "Done" line and Cobblemon loading, assert no client-only JAR landed in `data/mods`, assert RCON is not published. Correct the digest in `SPEC.md` to the index digest.

**Acceptance criteria:**
- [ ] With `.env` (`MEMORY=3G` locally) and the exported mrpack, `docker compose up -d` reaches `healthy` within 10 minutes; status reports Minecraft 1.21.1.
- [ ] `scripts/smoke.sh` passes; `data/mods` contains none of sodium, immediatelyfast, entityculling, modmenu, mouse-tweaks, emi, xaeros; `docker compose port cobblemon 25575` prints nothing.
- [ ] `docker buildx imagetools inspect` of the pinned reference lists both `linux/amd64` and `linux/arm64`.

**Verification:**
- [ ] `scripts/lint.sh && docker compose config -q`
- [ ] `scripts/smoke.sh`

**Dependencies:** Task 5
**Files likely touched:** `compose.yaml`, `.env.example`, `scripts/smoke.sh`, `config/server-icon.png`, `SPEC.md` (digest correction)
**Estimated scope:** M

#### Task 7: Persistence and graceful shutdown test

**Description:** Add `scripts/persist-test.sh`: require healthy, issue `save-all flush` through `rcon-cli`, record a hash of `data/world/level.dat`, run `docker compose stop` and time it, assert the log shows an orderly stop (server "Stopping" and save lines, no SIGKILL), `up -d`, wait healthy, assert `level.dat`, `whitelist.json` and `ops.json` survived. The RED run is `docker compose kill` followed by the script, which must fail on the missing orderly-stop evidence.

**Acceptance criteria:**
- [ ] `scripts/persist-test.sh` passes and stop time is under the 2 minute grace period.
- [ ] The RED run after `docker compose kill` fails with a clear message.
- [ ] World and admin files persist across the restart.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] `scripts/persist-test.sh`

**Dependencies:** Task 6
**Files likely touched:** `scripts/persist-test.sh`, `compose.yaml` (only if tuning is needed)
**Estimated scope:** S

#### Task 8: Backup sidecar and restore drill

**Description:** Add the `backup` service (`itzg/mc-backup`, newest dated tag at task time, pinned with its index digest) depending on `cobblemon` being healthy: `RCON_HOST=cobblemon`, `BACKUP_INTERVAL=${BACKUP_INTERVAL:-24h}`, `PAUSE_IF_NO_PLAYERS=true`, `PRUNE_BACKUPS_DAYS=14`, `INITIAL_DELAY=0`, `BACKUP_ON_STARTUP=true`, `./data:/data:ro`, `./backups:/backups`. Add `scripts/restore-drill.sh`: trigger `backup now`, take the newest archive, extract into `staging/restore-check/`, assert `world/level.dat` and `whitelist.json` are present, print the archive size. Verify where pruning looks so that `backups/keep/` is safe; if pruning recurses, use a sibling path and update the spec.

**Acceptance criteria:**
- [ ] After `up -d`, `backups/` receives an archive from the startup backup, and `backup now` creates another.
- [ ] `scripts/restore-drill.sh` passes, and fails (RED) when `backups/` is empty.
- [ ] The pre-upgrade keep location is confirmed outside the prune scope, with the check recorded in the commit message.

**Verification:**
- [ ] `scripts/lint.sh && docker compose config -q`
- [ ] `scripts/restore-drill.sh`

**Dependencies:** Task 7
**Files likely touched:** `compose.yaml`, `.env.example`, `scripts/restore-drill.sh`, `.gitignore`
**Estimated scope:** S

### Checkpoint B: Production stack

- [ ] L1 through L4 green locally: `lint.sh`, `compose config`, `pack-export.sh`, `pack-inspect.sh`, `smoke.sh`, `persist-test.sh`, `restore-drill.sh`
- [ ] `docker compose config` output reviewed by the human against the `SPEC.md` Code Style block
- [ ] `.env.example` reviewed: every `${VAR}` in any compose file is present with a default or placeholder

### Phase 3: Staging and release pipeline

#### Task 9: Staging override

**Description:** Add `compose.staging.yaml` overriding container names, the published port (`${STAGING_PORT:-25566}`), data and backup paths under `staging/`, while reusing `./dist`. Make `smoke.sh` and `persist-test.sh` accept the compose file list and project name (through `COMPOSE_FILE` and `COMPOSE_PROJECT_NAME` or flags). Add `scripts/staging-clone-world.sh` that copies the production world into `staging/data` after a `save-all flush`, as the upgrade SOP requires.

**Acceptance criteria:**
- [ ] `docker compose -f compose.yaml -f compose.staging.yaml config` differs from production only in names, port and paths.
- [ ] Production and staging run at the same time on 25565 and 25566 with separate data directories (on the dev machine this needs the Docker VM raised to 8 GB, otherwise staging is tested alone).
- [ ] `scripts/smoke.sh` passes against staging.

**Verification:**
- [ ] `scripts/lint.sh && docker compose -f compose.yaml -f compose.staging.yaml config -q`
- [ ] `COMPOSE_FILE=compose.yaml:compose.staging.yaml COMPOSE_PROJECT_NAME=cobblemon-staging scripts/smoke.sh`

**Dependencies:** Checkpoint B
**Files likely touched:** `compose.staging.yaml`, `scripts/smoke.sh`, `scripts/persist-test.sh`, `scripts/staging-clone-world.sh`, `.env.example`
**Estimated scope:** M

#### Task 10: Version contract and release script

**Description:** Add `scripts/version-check.sh` asserting `pack/pack.toml` version equals `PACK_VERSION` in `.env.example`, and equals the tag when HEAD is tagged. Add `scripts/release.sh X.Y.Z` with `--dry-run`: require a clean tree, set both versions, export and inspect, append a row to `docs/releases.md` (date, pack, Minecraft, loader, Cobblemon, image tag), commit "Release X.Y.Z", tag `vX.Y.Z`. The MOTD already derives from `PACK_VERSION`.

**Acceptance criteria:**
- [ ] `version-check.sh` passes on HEAD and fails (RED) when the two versions disagree.
- [ ] `release.sh --dry-run 1.0.0-rc.1` prints every step without changing anything; a real run on a throwaway branch produces the commit, the tag and the dist file, then the branch and tag are deleted.
- [ ] `docs/releases.md` has the table header and the 1.0.0 row placeholder.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] `scripts/version-check.sh`

**Dependencies:** Checkpoint B
**Files likely touched:** `scripts/version-check.sh`, `scripts/release.sh`, `docs/releases.md`
**Estimated scope:** S

#### Task 11: CI workflow

**Description:** Add `.github/workflows/ci.yml` with jobs `lint` (`scripts/lint.sh`), `validate` (both compose configurations), `pack` (build tools image, `packwiz refresh` no-diff check, export with `.env.example` defaults, inspect, upload the mrpack as an artifact) on push and pull request; `release` on tags `v*` creating a GitHub Release with the mrpack attached; `smoke` on `workflow_dispatch` running L3 with `MEMORY=4G` and a 15 minute timeout. Add actionlint to `scripts/lint.sh`. Pushing the branch to GitHub is an outward action and is done only after the human approves at this task.

**Acceptance criteria:**
- [ ] actionlint and yamllint are clean.
- [ ] After the human approves the push, `lint`, `validate` and `pack` are green on the first run.
- [ ] The `release` job is exercised at Checkpoint C.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] GitHub Actions run link recorded in the commit message

**Dependencies:** Task 10
**Files likely touched:** `.github/workflows/ci.yml`, `scripts/lint.sh`
**Estimated scope:** S

### Checkpoint C: Release candidate

- [ ] `scripts/release.sh 1.0.0-rc.1`, tag pushed, CI publishes a GitHub Release with `cobblemon-1.0.0-rc.1.mrpack`
- [ ] Human installs the mrpack from the Release URL in Modrinth App and in Prism Launcher, joins staging from the pre-filled server entry
- [ ] Update test: install rc.1, add an unrelated server manually, then update to rc.2 (a no-op release) and check whether `servers.dat` was overwritten; record the outcome in `docs/releases.md` and decide the `servers.dat` policy

### Phase 4: Documentation and acceptance

#### Task 12: Player guide, English and Traditional Chinese

**Description:** Write `docs/player-guide.md`: requirements, install Modrinth App or Prism Launcher, import the mrpack from the Release URL, client heap 4 to 6 GB, press Play, pick the pre-added server, what to do when the MOTD version differs, short FAQ. Write `docs/player-guide.zh-TW.md` as a faithful translation with the same heading order.

**Acceptance criteria:**
- [ ] A person following only the guide installs rc.1 and joins staging (human test, recorded in the commit message).
- [ ] The zh-TW file mirrors the English file section by section.
- [ ] Every link resolves.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] Manual read-through by the human

**Dependencies:** Checkpoint C
**Files likely touched:** `docs/player-guide.md`, `docs/player-guide.zh-TW.md`
**Estimated scope:** S

#### Task 13: Admin runbooks

**Description:** Write `docs/admin-guide.md` (whitelist, op, list, restart, logs, `docker stats`, performance triage order), `docs/upgrade.md` and `docs/rollback.md` (the SPEC SOPs with exact commands using the staging, release and backup scripts), and `docs/acceptance-checklist.md` (the ten Phase 1 gameplay items with tester, date and result columns).

**Acceptance criteria:**
- [ ] Every command in the admin guide was executed once against the local stack during the task.
- [ ] The upgrade SOP was rehearsed as a same-version dry run on staging; the rollback SOP was rehearsed by restoring the rc backup.
- [ ] The acceptance checklist covers all ten Phase 1 items from `SPEC.md`.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] Rehearsal transcript summarised in the commit message

**Dependencies:** Tasks 9, 10
**Files likely touched:** `docs/admin-guide.md`, `docs/upgrade.md`, `docs/rollback.md`, `docs/acceptance-checklist.md`
**Estimated scope:** M

#### Task 14: README, ADRs and clean-clone rehearsal

**Description:** Write `README.md` (what this is, quick start, structure, version contract, links to the guides) and three ADRs: `0001-single-pack-for-client-and-server.md`, `0002-itzg-image-and-mc-backup-sidecar.md`, `0003-servers-dat-generated-at-export.md`. Rehearse the quick start verbatim from a clean clone in the scratch directory; it must end with a passing `scripts/smoke.sh`.

**Acceptance criteria:**
- [ ] The quick start works verbatim from a clean clone (SPEC success criterion 1).
- [ ] Each ADR has context, decision and consequences.
- [ ] README links resolve.

**Verification:**
- [ ] `scripts/lint.sh`
- [ ] Clean-clone transcript summarised in the commit message

**Dependencies:** Task 11
**Files likely touched:** `README.md`, `docs/adr/0001-single-pack-for-client-and-server.md`, `docs/adr/0002-itzg-image-and-mc-backup-sidecar.md`, `docs/adr/0003-servers-dat-generated-at-export.md`
**Estimated scope:** M

#### Task 15: L5 acceptance on staging and the 1.0.0 release

**Description:** Human-driven, agent-assisted. Run the acceptance checklist on staging with the rc pack and at least two players. Any failure becomes a new task (ask first). When the checklist passes: `scripts/release.sh 1.0.0`, push the tag, confirm the GitHub Release, set `PACK_VERSION=1.0.0` on production, `up -d`, run L3 and L4 and the restore drill on production, fill in `docs/releases.md`, notify players.

**Acceptance criteria:**
- [ ] `docs/acceptance-checklist.md` is filled in with all items passing on staging and on production.
- [ ] SPEC success criteria 1 through 7 are demonstrated with output shown to the human.
- [ ] Git tag, `pack.toml`, mrpack name, `PACK_VERSION` and MOTD all read `1.0.0`.

**Verification:**
- [ ] `scripts/version-check.sh`
- [ ] `scripts/smoke.sh && scripts/persist-test.sh && scripts/restore-drill.sh` on production

**Dependencies:** Tasks 12, 13, 14
**Files likely touched:** `docs/acceptance-checklist.md`, `docs/releases.md`, `pack/pack.toml`, `.env.example`
**Estimated scope:** S

### Checkpoint D: Complete

- [ ] All `SPEC.md` success criteria met with evidence
- [ ] `/agent-skills:review`, then `/agent-skills:code-simplify`, then `/agent-skills:ship` on the branch before merging to `main`

## Parallelization

With one agent the numbered order is the plan. If a second agent is available after Checkpoint B, Tasks 9, 10 and 11 are independent of each other (they touch disjoint files), and Task 12 can be drafted in parallel with Task 13. Tasks 6 to 8 must stay sequential because they all edit `compose.yaml`.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Dev machine Docker VM has 4.8 GB; production default is `MEMORY=6G` | High (L3 cannot run locally as configured) | Local `.env` uses `MEMORY=3G`; raise Docker Desktop to 8 GB before the two-stack staging test; CI smoke uses 4G |
| Per-platform digest in `SPEC.md` would not pull on arm64 | High | Task 6 pins the multi-arch index digest and verifies both platforms |
| Host bash is 3.2 | Medium | No associative arrays, `mapfile` or `${var,,}`; shellcheck with `--shell=bash`; every script is run on the Mac during its task |
| Containers create root-owned files on Linux hosts | Medium | `user:` mapping on the tools service; documented in README |
| packwiz side guess differs from the side table | Medium | Explicit `side` edits; `pack-inspect.sh` asserts every marker |
| Launcher re-applies overrides and overwrites `servers.dat` on update | Medium | Tested at Checkpoint C with rc.1 to rc.2; fallback is to drop `servers.dat` and document a one-time manual add |
| itzg default healthcheck too strict for modded startup | Medium | 5 minute start period; smoke timeout 10 minutes |
| Modrinth rate limits slow the first boot | Low | Timeout and retry in `smoke.sh`; mrpack cached by itzg in `/data` |
| `mc-backup` prune may recurse into `backups/keep/` | Low | Verified in Task 8; sibling path if needed |
| Hosted CI runner cannot boot a 6G server | Low | Smoke job is manual dispatch only with `MEMORY=4G` |

## Open Questions

None blocking. Two confirmations are requested at this gate: the side table in Architecture Decision 3, and the Docker Desktop memory increase on the dev machine before Task 9.
