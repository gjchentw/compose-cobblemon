# compose-cobblemon

A Cobblemon (Minecraft 1.21.1, Fabric) server and its matching client pack, shipped as
one versioned release. Admins run everything with `docker compose`; players install one
`.mrpack` and press Play. This repository is a GitHub template: create your own copy,
set two secrets, tag a release, and CI builds the pack for your server.

- Players: read [docs/player-guide.md](docs/player-guide.md)
  (Traditional Chinese: [docs/player-guide.zh-TW.md](docs/player-guide.zh-TW.md)).
- Admins: read [docs/admin-guide.md](docs/admin-guide.md), then
  [docs/upgrade.md](docs/upgrade.md) and [docs/rollback.md](docs/rollback.md).

## How it fits together

One packwiz pack under `pack/` is the source of truth. `scripts/pack-export.sh` turns it
into `dist/cobblemon-<version>.mrpack`. Players install that file in Modrinth App or Prism
Launcher; the server mounts the same file and `itzg/minecraft-server` installs only the
server-side entries. A backup sidecar archives the world daily. A staging override runs a
second stack next to production for testing upgrades on a copy of the real world.

```
pack/  ──export──▶  dist/cobblemon-X.Y.Z.mrpack  ──▶  players (Modrinth App / Prism)
                                 │
                                 └──▶  cobblemon service (server side only)  ──▶  ./data
                                                 │
                                                 └──▶  backup sidecar  ──▶  ./backups
```

## Make it yours (GitHub)

1. Click **Use this template** and create your repository.
2. In your repository go to **Settings > Secrets and variables > Actions > Secrets** and add
   `SERVER_PUBLIC_HOST` (the address players connect to, for example `mc.example.org`) and
   `SERVER_NAME` (what players see in their server list). Tag builds refuse to publish a pack
   without them.
3. Optional: replace `config/server-icon.png`, and change `name` and `author` in `pack/pack.toml`.
4. Cut a release from your clone with `scripts/release.sh X.Y.Z` and push the tag. CI attaches
   `cobblemon-X.Y.Z.mrpack` to a GitHub Release; send players the link.

## Quick start (Docker host)

Requirements: Linux with Docker 24+ and Compose 2.24+ (the staging override uses `!override`), bash, 12 GB RAM for the default 6 GB heap.

```bash
git clone https://github.com/<you>/<your-repo>.git   # your copy of this template
cd <your-repo>
cp .env.example .env
# edit .env: RCON_PASSWORD (openssl rand -base64 32), SERVER_NAME, SERVER_PUBLIC_HOST,
#            MEMORY, and UID/GID from `id -u` / `id -g`
mkdir -p data backups/keep dist && chmod 750 data backups   # yours, not root's; private
scripts/pack-export.sh          # or download the release mrpack into dist/
docker compose up -d
scripts/smoke.sh                # waits for healthy, checks version, mods and RCON exposure
```

Open 25565/tcp to players. Whitelist them with
`docker compose exec cobblemon rcon-cli whitelist add PLAYER_NAME`.

## Verification ladder

Every change is checked bottom-up; CI runs L1 and L2 on every push.

| Level | Command |
|---|---|
| L1 static | `scripts/lint.sh && docker compose config -q` |
| L2 pack | `scripts/pack-export.sh && scripts/pack-inspect.sh && scripts/version-check.sh` |
| L3 smoke | `scripts/smoke.sh` |
| L4 persistence | `scripts/persist-test.sh && scripts/restore-drill.sh` |
| L5 gameplay | [docs/acceptance-checklist.md](docs/acceptance-checklist.md), by people |

The same scripts test the staging stack with `COMPOSE_FILE=compose.yaml:compose.staging.yaml`.

## Version contract

One release is one git tag `vX.Y.Z`, one `pack/pack.toml` version, one
`dist/cobblemon-X.Y.Z.mrpack`, one `PACK_VERSION` and the MOTD `... | Pack X.Y.Z`.
`scripts/release.sh X.Y.Z` cuts a release; CI attaches the mrpack to a GitHub Release.
History: [docs/releases.md](docs/releases.md).

## Repository layout

```
compose.yaml              production stack: cobblemon + backup (+ packwiz under profile "tools")
compose.staging.yaml      staging override: own project name, port 25566, staging/ data
.env.example              every variable with a default or placeholder
pack/                     packwiz source of truth (pack.toml, index.toml, mods/*.pw.toml, options.txt)
tools/packwiz/Dockerfile  packwiz built from a pinned commit
config/server-icon.png    placeholder icon, replace with your own
scripts/                  lint, pack-export, pack-inspect, smoke, persist-test, restore-drill,
                          staging-clone-world, version-check, release
docs/                     guides, SOPs, checklist, releases, adr/
.github/workflows/ci.yml  L1 + L2 on push, release on tag, smoke on manual dispatch
SPEC.md                   what this repo builds and how it is verified
AGENTS.md                 how AI agents and humans collaborate here
tasks/                    implementation plan and task list
```

Runtime directories (`data/`, `backups/`, `staging/`, `dist/`, `.env`) are never committed.

## Decisions

See [docs/adr/](docs/adr/) for why the pack feeds both sides, why itzg images and a backup
sidecar were chosen over custom Dockerfiles and cron, and why `servers.dat` is generated at
export time.

## License

See [LICENSE](LICENSE).
