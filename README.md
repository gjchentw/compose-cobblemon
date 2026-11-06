# compose-cobblemon

A Cobblemon (Minecraft 1.21.1, Fabric) server and its matching client pack, shipped as
one versioned release. Admins run everything with `docker compose`; players install one
`.mrpack` and press Play. This repository is a GitHub template: create your own copy,
set two secrets, publish a release on GitHub, and CI builds the pack for your server.
No local tooling is needed to release.

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
   `SERVER_NAME` (what players see in their server list). A release build refuses to publish a
   pack without `SERVER_PUBLIC_HOST`; without `SERVER_NAME` the entry is called "Cobblemon Server".
3. Optional: replace `config/server-icon.png` and change `name` and `author` in `pack/pack.toml`
   (both can be edited in the GitHub web editor).
4. Publish a release: **Releases > Draft a new release**, type a new tag such as `v1.0.0` in
   **Choose a tag** and pick "Create new tag on publish", then **Publish release**. For a
   release candidate use `v1.0.0-rc.1`; CI marks it as a pre-release even if you forget the
   checkbox.
5. Wait a few minutes. CI builds the pack for that tag, attaches `cobblemon-1.0.0.mrpack` to the
   release and adds a pack contents table to its notes. Send players the release link.

The tag is the version: it must be `vX.Y.Z` or `vX.Y.Z-rc.N`, and nothing in git has to be
edited to release. If the build fails, open the run under **Actions**. For a missing secret,
add it and re-run the failed jobs. For a tag in another format, delete the release and its
tag, then publish again with a valid tag.

## Quick start (Docker host)

Requirements: Linux with Docker 24+ and Compose 2.24+ (the staging override uses `!override`), bash, 12 GB RAM for the default 6 GB heap.

```bash
git clone https://github.com/<you>/<your-repo>.git   # your copy of this template
cd <your-repo>
git checkout v1.0.0             # the release you deploy
cp .env.example .env
# edit .env: PACK_VERSION=1.0.0 (the tag without the "v"), RCON_PASSWORD (openssl rand -base64 32),
#            SERVER_NAME, SERVER_PUBLIC_HOST, MEMORY, and UID/GID from `id -u` / `id -g`
mkdir -p data backups/keep dist && chmod 750 data backups   # yours, not root's; private
curl -fL -o dist/cobblemon-1.0.0.mrpack \
  https://github.com/<you>/<your-repo>/releases/download/v1.0.0/cobblemon-1.0.0.mrpack
docker compose up -d
scripts/smoke.sh                # waits for healthy; checks version, pack, mods, RCON exposure
```

To try the stack without a release, keep `PACK_VERSION=0.0.0-dev` and run `scripts/pack-export.sh`
instead of downloading: it builds `dist/cobblemon-0.0.0-dev.mrpack` from `pack/`.

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

The git tag is the only place a release version is written. One release is one tag `vX.Y.Z`,
one `cobblemon-X.Y.Z.mrpack` (file name and the version inside the pack), one `PACK_VERSION`
in the host's `.env` and the MOTD `... | Pack X.Y.Z`. In git, `pack/pack.toml` and
`.env.example` always read `0.0.0-dev`; CI substitutes the tag's version when it builds the
pack for a published release. `scripts/smoke.sh` checks a deployment against this contract:
the checkout carries the tag, the pack file is that version inside, and the MOTD announces
it. Release history is the repository's Releases page.

## Repository layout

```
compose.yaml              production stack: cobblemon + backup (+ packwiz under profile "tools")
compose.staging.yaml      staging override: own project name, port 25566, staging/ data
.env.example              every variable with a default or placeholder
pack/                     packwiz source of truth (pack.toml, index.toml, mods/*.pw.toml, options.txt)
tools/packwiz/Dockerfile  packwiz built from a pinned commit
config/server-icon.png    placeholder icon, replace with your own
scripts/                  lint, pack-export, pack-inspect, version-check, smoke, persist-test,
                          restore-drill, staging-clone-world, ci-env
docs/                     guides, SOPs, checklist, adr/
.github/workflows/ci.yml  L1 + L2 on push; pack build on a published release; L3/L4 on dispatch
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
