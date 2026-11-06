# Spec: compose-cobblemon

**Status:** APPROVED 2026-11-03 (SDD gate 1); living document, amended as decisions change
**Spec version:** 0.3.0 (2026-11-06; decision 10: the git tag is the release version)
**Source material:** the human's "Docker + Fabric + Cobblemon Server Deployment Plan" (Chinese), translated and tightened here. Where this spec deviates from that plan, the deviation is called out and recorded under Decisions.

## Objective

Ship a Cobblemon Minecraft server **and** the matching client pack as one versioned release, so that:

- **Admins** deploy, back up, upgrade and roll back the server with `docker compose` and a handful of scripts. Every version (Minecraft, Fabric, Cobblemon, image, pack) is pinned and changed only on purpose.
- **Players** install one client pack in Modrinth App or Prism Launcher, press Play, and see the server already in their Multiplayer list. They never install Fabric, hunt for Fabric API, or copy JARs.
- **Support** starts every incident with one question: "which pack version are you on?"

User stories:

1. As an admin, I clone this repo on a fresh Linux host with Docker, fill in `.env`, run `docker compose up -d`, and have a healthy whitelisted server within 10 minutes.
2. As an admin, I publish a release on GitHub and CI produces `cobblemon-<version>.mrpack` for players.
3. As an admin, I test a new Cobblemon release on a staging stack with a copy of the production world before touching production, and I can roll back if it fails.
4. As a player, I install the pack, press Play, select "Cobblemon Server" in Multiplayer, and join with no further setup.
5. As a player, when a new pack version is announced I update it in my launcher and join again; the server MOTD tells me which version is expected.

## Scope

**In scope for release 1.0.0**

- Production Compose stack: Cobblemon server + backup sidecar.
- Staging Compose override runnable next to production on the same host.
- One pack definition that produces the client `.mrpack` and feeds the server (see Architecture).
- Client defaults shipped in the pack: performance options and a pre-filled server list.
- Client QoL mods in 1.0.0: Mod Menu, EMI, Xaero's Minimap, Xaero's World Map, AppleSkin, Mouse Tweaks, plus Text Placeholder API as the required dependency of Mod Menu (client side only; decided 2026-11-03).
- Verification scripts: smoke, persistence, backup restore drill.
- Runbooks: player install guide (English, plus a Traditional Chinese copy), admin guide, upgrade SOP, rollback SOP.
- Phase 1 gameplay acceptance checklist (login, spawn, starter, catch, battle, trade, ride, death and respawn, restart, persistence).

**Out of scope for 1.0.0, planned for later releases**

- Phase 2 server mods: spark, LuckPerms, BlueMap, Ledger, spawn/home/tpa commands.
- Publishing the pack as a Modrinth project.
- In-game onboarding content (safe spawn build, tutorial signs, starter kit). The server provides spawn protection and a short MOTD only.
- Off-host backup replication (rclone/restic targets).
- Proxy layers (Velocity), multi-server networks, Paper or Bukkit compatibility layers.

## Tech Stack

All versions below were verified on 2026-11-03 against the sources listed at the end.

| Component | Pinned value | Notes |
|---|---|---|
| Docker Engine | 24+ with Compose 2.24+ (`docker compose`; the staging override uses `!override`) | Host needs only Docker and bash; all tooling runs in containers |
| Server image | `itzg/minecraft-server:2026.10.1-java21` | Pinned by tag and digest in `compose.yaml`. `latest` is Java 25 now; Minecraft 1.21.1 targets Java 21 |
| Backup image | `itzg/mc-backup`, dated tag chosen in Plan | Official companion image; RCON-coordinated `save-off`/`save-on` |
| Minecraft | 1.21.1 | |
| Mod loader | Fabric, loader version pinned in `pack.toml` | |
| Cobblemon | 1.8.4 (released 2026-10-27) | Decided 2026-11-03; the original plan said 1.8.3 |
| Official modpack reference | Modrinth project `5FFgwNNP` ("Cobblemon Official Modpack [Fabric]") | Used as the reference mod list, or directly as the server pack under Option A |
| Pack tooling | packwiz, pinned commit, built into `tools/packwiz/Dockerfile` | Produces `.mrpack`; same tool exports the pack the server consumes |
| Launchers supported | Modrinth App, Prism Launcher | Both import `.mrpack` |
| Lint tooling | hadolint, yamllint, shellcheck, all via containers | No host installs |

## Architecture

```
Player
  └─ Modrinth App / Prism Launcher
      └─ cobblemon-<version>.mrpack  (client side of the pack)
          └─ mc.example.com:25565
              └─ Docker host
                  ├─ cobblemon   itzg/minecraft-server:2026.10.1-java21
                  │     ├─ installs server side of the SAME .mrpack from /packs (read-only mount)
                  │     ├─ Fabric + Cobblemon + server-side mods
                  │     └─ ./data:/data  (world, configs, whitelist)
                  └─ backup      itzg/mc-backup
                        ├─ RCON to cobblemon (internal network only)
                        └─ ./data:/data:ro  →  ./backups:/backups
```

**Single source of truth (Option B, decided 2026-11-03).** The repo holds one packwiz pack under `pack/`. Each mod is marked `side = client | server | both`. `packwiz modrinth export` writes one `.mrpack` whose `modrinth.index.json` carries those side markers. Players install it; the server mounts the same file and `itzg/minecraft-server` installs only the server-side entries. Server-required mods therefore cannot be missing from the client, and the version contract holds by construction.

**Rejected alternative (Option A, as in the original plan).** The server would run the official modpack (`TYPE=MODRINTH`, `MODRINTH_MODPACK=5FFgwNNP`, `MODRINTH_VERSION=<cobblemon version>`) with a separately maintained client pack. Rejected because every bump would require auditing the official pack for server-side mods that need a client counterpart. Kept here as context for the ADR.

**Version contract.** The git tag is the only place a release version is written. One release = one git tag `vX.Y.Z` = `cobblemon-X.Y.Z.mrpack` (file name and the pack's internal version id) = `PACK_VERSION=X.Y.Z` in the host's `.env` = MOTD "Cobblemon Server | Pack X.Y.Z". In git, `pack/pack.toml` and `.env.example` carry the placeholder `0.0.0-dev`, never a release version; the build substitutes the tag's version into a copy of the pack. Publishing a GitHub release (UI or `gh release create`) with a new tag is the whole release procedure: CI builds the pack for that tag, attaches the mrpack, and writes the Minecraft, Fabric loader, Cobblemon and server image versions into the release notes.

**Environments.** `compose.yaml` is production. `compose.staging.yaml` overrides container names, the published port (25566), data and backup directories (`staging/`), and the pack file, so staging runs on the same host without touching production data.

## Commands

Exact flags are finalised in Plan; the shape is fixed here. Every command runs from the repo root and needs only Docker and bash on the host.

```
# L1 static
Validate:   docker compose config -q
            docker compose -f compose.yaml -f compose.staging.yaml config -q
Lint:       scripts/lint.sh            # hadolint, yamllint, shellcheck via containers
Pack check: docker compose --profile tools run --rm packwiz refresh   # must produce no git diff

# L2 build
Tools:      docker compose --profile tools build
Export:     scripts/pack-export.sh [X.Y.Z]   # -> dist/cobblemon-<version>.mrpack; default is the 0.0.0-dev placeholder
            scripts/pack-inspect.sh    # jq over modrinth.index.json: expected mods and side markers

# Run
Up:         docker compose up -d
Logs:       docker compose logs -f cobblemon
Status:     docker compose ps
Admin:      docker compose exec cobblemon rcon-cli <command>   # list, whitelist add/remove, op
Staging:    docker compose -f compose.yaml -f compose.staging.yaml -p cobblemon-staging up -d

# L3 / L4
Smoke:      scripts/smoke.sh           # healthy within timeout, port answers, expected log lines
Persist:    scripts/persist-test.sh    # down, up, world and player data still present
Backup now: docker compose exec backup backup now
Restore:    scripts/restore-drill.sh   # restore latest backup into a scratch dir and verify

# Release
Release:    publish a GitHub release with a new tag vX.Y.Z (web UI, or `gh release create vX.Y.Z`); CI builds and attaches the mrpack
```

## Project Structure

```
compose.yaml              production stack: cobblemon + backup (+ packwiz under profile "tools")
compose.staging.yaml      staging override: ports, names, directories, pack file
.env.example              every variable the stacks read, with safe defaults or placeholders
.gitignore
pack/                     packwiz source of truth
  pack.toml               name, version, minecraft, fabric loader
  index.toml              generated by packwiz refresh
  mods/*.pw.toml          one file per mod, with side markers
  options.txt             client performance defaults (overrides)
  (servers.dat is generated at export time, never committed; see docs/adr/0003)
tools/packwiz/Dockerfile  pinned packwiz image
config/                   server-side files mounted into /data (server-icon.png, config overlays)
scripts/                  lib.sh, lint.sh, pack-export.sh, pack-inspect.sh/.py, make-servers-dat.py,
                          version-check.sh, smoke.sh, persist-test.sh, restore-drill.sh,
                          staging-clone-world.sh, ci-env.sh
docs/
  player-guide.md         install the pack, press Play
  player-guide.zh-TW.md   Traditional Chinese copy of the player guide; the only non-English file, see AGENTS.md
  admin-guide.md          day-2 operations: whitelist, ops, restart, logs, monitoring
  upgrade.md              upgrade SOP
  rollback.md             rollback SOP
  acceptance-checklist.md Phase 1 gameplay checklist (L5)
  adr/                    architecture decision records
.github/workflows/ci.yml  L1 and L2 on push and PR; pack build on a published release; L3/L4 by dispatch or smoke/* branch
dist/                     exported mrpacks, gitignored, attached to releases
data/ backups/ staging/   runtime data, gitignored
SPEC.md AGENTS.md README.md tasks/
```

## Code Style

One service, showing every convention at once:

```yaml
services:
  cobblemon:
    # Pinned by tag AND digest. Bump both together, via the upgrade SOP.
    image: itzg/minecraft-server:2026.10.1-java21@sha256:07ab333a8542208c4c863a78fd3cf3fd1138d5a2e118306e1a316d202f69ab74
    container_name: cobblemon
    restart: unless-stopped
    stop_grace_period: 2m            # let the server save before Docker kills it
    ports:
      - "${MC_PORT:-25565}:25565"    # RCON (25575) is never published
    environment:
      EULA: "TRUE"
      TZ: "${TZ:-UTC}"
      # --- pack ---
      TYPE: "MODRINTH"
      MODRINTH_MODPACK: "/packs/cobblemon-${PACK_VERSION:?set PACK_VERSION in .env}.mrpack"
      # --- JVM ---
      MEMORY: "${MEMORY:-6G}"
      USE_AIKAR_FLAGS: "true"
      # --- gameplay ---
      MOTD: "${SERVER_NAME:-Cobblemon Server} | Pack ${PACK_VERSION}"
      ONLINE_MODE: "true"
      ENABLE_WHITELIST: "true"
      ENFORCE_WHITELIST: "true"
      # --- admin ---
      ENABLE_RCON: "true"
      RCON_PASSWORD: "${RCON_PASSWORD:?set RCON_PASSWORD in .env}"
    volumes:
      - ./data:/data
      - ./dist:/packs:ro
      - ./config/server-icon.png:/data/server-icon.png:ro
    healthcheck:
      test: ["CMD", "mc-health"]
      start_period: 5m               # modded startup is slow; default is too strict
      interval: 15s
      timeout: 10s
      retries: 20
```

Conventions:

- YAML: 2-space indent, keys grouped by concern with a `# --- name ---` comment, every environment value quoted.
- `.env` variables are `UPPER_SNAKE_CASE`. Required secrets use `${VAR:?message}`; everything else has a default `${VAR:-value}` that matches `.env.example`.
- Images are pinned by tag and digest. No `latest`, no `stable`.
- Scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, shellcheck clean, usage text at the top, exit non-zero on any failed check, status to stderr.
- packwiz files are generated by packwiz. The only hand edits are `pack.toml` and the `side` field of a mod file, always followed by `packwiz refresh`.
- All committed text is English, with one exception: `docs/player-guide.zh-TW.md` (see `AGENTS.md`).

## Testing Strategy

There are no unit tests. The verification ladder from `AGENTS.md` is made concrete here, plus a manual acceptance level for gameplay.

| Level | What must be true | How |
|---|---|---|
| L1 Static | All compose combinations validate; Dockerfile, YAML and shell lint clean; `packwiz refresh` leaves the tree unchanged | `docker compose config`, `scripts/lint.sh`, git diff check |
| L2 Build | Tools image builds; export produces `dist/cobblemon-<v>.mrpack`; the index lists the expected mods with correct `client`/`server` env markers | `scripts/pack-export.sh`, `scripts/pack-inspect.sh` |
| L3 Smoke | Stack reaches `healthy` within 10 minutes; status query on 25565 reports Minecraft 1.21.1; log shows the Fabric "Done" line and Cobblemon loaded; no client-only mod was installed server-side | `scripts/smoke.sh` |
| L4 Persistence | After `down` and `up`, world and player data survive; backup sidecar produced at least one archive; restore drill restores it into a scratch directory with the world intact | `scripts/persist-test.sh`, `scripts/restore-drill.sh` |
| L5 Acceptance | A human with the exported pack completes `docs/acceptance-checklist.md` on staging: install, join from the pre-filled server list, choose starter, catch, battle, trade, ride, die and respawn, survive a server restart | manual, recorded in the release notes |

RED and GREEN for infrastructure: a task first adds or extends the check that fails without the change, then the smallest change that makes it pass, then every level named in the task's `Verify` line.

CI (GitHub Actions) runs L1 and L2 on every push and pull request with the placeholder version. When a GitHub release is published it derives the version from the tag, exports and inspects the pack for it, and uploads the mrpack to that release. L3 is a manual workflow dispatch because a modded server boot is slow and memory-hungry on hosted runners.

## Operations Requirements

These are requirements the repository must satisfy; the detailed procedures live in `docs/`.

**Backup.** The `backup` sidecar takes one full tar archive of `/data` every 24 hours, pauses while no players are online, prunes archives older than 14 days, and excludes `*.jar`, `cache`, `logs`. Incremental backups (restic) are deferred. Backups live in `./backups`, outside `./data`. A pre-upgrade backup is taken with `backup now` and moved to `backups/keep/`, which pruning never touches. The restore drill must be run once before 1.0.0 is declared done, and after every upgrade.

**Upgrade SOP** (`docs/upgrade.md`), condensed from the plan:

1. Bump what changes in `pack/` or `compose.yaml`, merge, and publish a pre-release `vX.Y.Z-rc.N` on GitHub; CI builds the candidate pack.
2. Copy the production world into `staging/data`, start staging with the candidate pack.
3. Join staging with the candidate client pack; run the L5 checklist; read the startup log.
4. Take a pre-upgrade backup of production and move it to `backups/keep/`.
5. Publish the final GitHub release `vX.Y.Z`; CI attaches the mrpack.
6. Stop production, check out the tag, set `.env` `PACK_VERSION=X.Y.Z`, place the mrpack in `dist/`, start, run L3 and L4, notify players with the exact version string.

Production never tracks `latest` of Cobblemon, Fabric loader, the image, or any mod.

**Rollback SOP** (`docs/rollback.md`). Keep the previous `compose.yaml`, `.env`, mrpack and pre-upgrade backup until the new release has survived one full backup cycle. Rollback is: stop, restore previous `.env` and mrpack, restore `mods/` and `config/` from the pre-upgrade backup, restore the world only if required, start, run L3, tell players to switch back to the previous pack version. A world modified by a newer Cobblemon is not assumed to downgrade cleanly.

**Admin operations** (`docs/admin-guide.md`): whitelist add/remove, op, list, restart, log inspection, `docker stats`, and the performance triage order from the plan (spark first, then simulation distance, view distance, entity counts, chunk generation, add-on A/B, pre-generation, hardware last). spark itself is a Phase 2 mod.

**Host sizing.** The production host has at least 12 GB RAM (decided 2026-11-03), so the default is `MEMORY=6G`, leaving room for the OS, JVM overhead and the backup sidecar. `.env.example` documents `MEMORY=4G` as the value for an 8 GB host. The plan's "8 GB host, 6 to 8 GB heap" was over-committed.

## Boundaries

**Always**

- Follow the SDD cycle in `AGENTS.md`; every change maps to a task.
- Pin every image by tag and digest, every mod and loader version in `pack/`.
- Keep `.env.example` complete and in sync with every `${VAR}` referenced in any compose file.
- Run L1 and L2 before every commit; L3 and L4 before every release.
- Keep RCON on the internal Compose network only.
- Keep `ONLINE_MODE=true` and the whitelist enforced.

**Ask first**

- Adding or removing a mod in `pack/`, including Phase 2 server mods.
- Adding, removing or renaming a Compose service.
- Changing published ports, volume mappings, the base image, or any pinned version.
- Adding tooling or CI workflows.
- Deleting any file.
- Anything touching secrets, RCON, user or group IDs, or container privileges.

**Never**

- Commit `.env`, `data/`, `backups/`, `staging/`, `dist/`, logs or any secret.
- Use `latest`, `stable` or any floating tag.
- Publish the RCON port or set `ONLINE_MODE=false`.
- Hand-edit packwiz-generated files, other than `pack.toml` and a mod's `side` field followed by `packwiz refresh`.
- Ship a release whose git tag, mrpack file name and internal version id, `PACK_VERSION` and MOTD disagree, or commit a release version to `pack/pack.toml` or `.env.example`.
- Remove or weaken a check to make it pass.

## Success Criteria

1.0.0 is done when all of the following are demonstrated, with output shown to the human:

1. On a fresh Linux host with only Docker installed: clone, `cp .env.example .env`, set `RCON_PASSWORD`, run `scripts/pack-export.sh` then `docker compose up -d`; the stack is `healthy` within 10 minutes and a status query on port 25565 reports Minecraft 1.21.1.
2. The exported `cobblemon-1.0.0.mrpack` installs in Modrinth App and in Prism Launcher; the game launches with no manual mod steps; "Cobblemon Server" is already in the Multiplayer list; a whitelisted account joins.
3. Git tag `v1.0.0`, the mrpack file name and internal version id, the host's `PACK_VERSION` and the MOTD all read `1.0.0`; `pack/pack.toml` and `.env.example` in git still read the `0.0.0-dev` placeholder.
4. L1 through L4 pass locally; the restore drill restores a backup with the world intact.
5. The staging stack runs next to production on port 25566 with a copied world, and the L5 checklist passes on staging and on production.
6. Runbooks exist and were followed at least once each: player guide (English and Traditional Chinese), admin guide, upgrade SOP, rollback SOP.
7. CI runs L1 and L2 green on the release commit, and the release workflow attaches `cobblemon-1.0.0.mrpack` to the published GitHub release.

## Assumptions

1. Target users are a small private group (whitelist, 10 to 20 players), not a public server.
2. One Linux Docker host runs both production and staging; staging is only up during upgrades.
3. Players use Modrinth App or Prism Launcher on desktop and own a Java Edition account (`ONLINE_MODE=true`).
4. Every mod in the pack is hosted on Modrinth, so the mrpack references downloads rather than bundling JARs and no redistribution licence question arises.
5. The domain, server name and icon in this repo are placeholders; real values live only in `.env` and local files.
6. Admins are comfortable with a terminal; no web admin panel is in scope.

## Decisions

Resolved with the human on 2026-11-03, one question at a time. Non-obvious ones get an ADR in `docs/adr/` during Plan.

| # | Question | Decision |
|---|---|---|
| 1 | Pack architecture | Option B: one packwiz pack feeds both client and server |
| 2 | Cobblemon version for 1.0.0 | 1.8.4 |
| 3 | Host RAM and heap | Host has at least 12 GB; `MEMORY=6G` default, `MEMORY=4G` documented for 8 GB hosts |
| 4 | QoL mods in 1.0.0 | All of them: Mod Menu, EMI, Xaero's Minimap, Xaero's World Map, AppleSkin, Mouse Tweaks |
| 5 | Pack distribution | GitHub Release of this repo; CI attaches the mrpack (amended by decision 10: the published release, not a tag push, triggers the build) |
| 6 | CI | GitHub Actions: L1 and L2 on push and PR, pack build on a published release (amended by decision 10), L3 by manual dispatch or a smoke/* branch |
| 7 | Player guide language | English primary, plus `docs/player-guide.zh-TW.md` as an explicit exception recorded in `AGENTS.md` |
| 8 | Backup cadence | One full tar archive every 24 hours, pause when no players are online, prune after 14 days, pre-upgrade archives kept in `backups/keep/` |
| 9 | Server name and host for CI builds (2026-11-04) | GitHub repository secrets `SERVER_NAME` and `SERVER_PUBLIC_HOST`; the repository is a GitHub template so others create their own copy, set their own secrets and build their own pack |
| 10 | Release version source (2026-11-06) | The git tag. Publishing a GitHub release builds the pack for that tag; `pack/pack.toml` and `.env.example` hold the `0.0.0-dev` placeholder; `scripts/release.sh` and `docs/releases.md` are removed (release history lives in GitHub Releases). Supersedes the "version committed in git" part of the original contract, so a template copy can release without any local tooling |

No open questions remain.

## Risks

- `itzg/minecraft-server:latest` is Java 25; using it with 1.21.1 Fabric mods is unsupported territory. Mitigated by pinning the java21 tag.
- The image's default healthcheck is too strict for modded startup; the compose file sets a 5 minute start period.
- Launchers may re-apply pack overrides on in-place updates and overwrite a player's `servers.dat`. Moot by design: the player guide updates by installing the new mrpack as a new profile, which always carries the pre-filled entry.
- `itzg` cleans mods from a previous modpack version on upgrade; the world is untouched but custom files under `data/mods` would be removed. All server-side additions must go through the pack, never by hand.
- Modrinth API rate limits can slow a first boot; the smoke timeout is 10 minutes to absorb this.

## Sources

- Modrinth project `5FFgwNNP` metadata: https://api.modrinth.com/v2/project/5FFgwNNP and its versions endpoint (1.8.4 published 2026-10-27, Fabric, 1.21.1).
- Cobblemon mod versions: https://api.modrinth.com/v2/project/cobblemon/version (1.8.4F published 2026-10-27).
- itzg Modrinth modpack variables, including local `.mrpack` paths: https://docker-minecraft-server.readthedocs.io/en/latest/types-and-platforms/mod-platforms/modrinth-modpacks/
- itzg Java tags and pinned release tag format: https://docker-minecraft-server.readthedocs.io/en/latest/versions/java/
- itzg healthcheck: https://docker-minecraft-server.readthedocs.io/en/latest/misc/healthcheck/
- Image tag `2026.10.1-java21`, multi-arch index digest `sha256:07ab333a8542208c4c863a78fd3cf3fd1138d5a2e118306e1a316d202f69ab74` (linux/amd64 and linux/arm64, verified with `docker buildx imagetools inspect`): https://hub.docker.com/v2/repositories/itzg/minecraft-server/tags/2026.10.1-java21
- itzg/mc-backup sidecar usage and variables: https://github.com/itzg/docker-mc-backup
- packwiz getting started and export: https://packwiz.infra.link/tutorials/creating/getting-started/
