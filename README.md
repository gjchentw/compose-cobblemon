# compose-cobblemon

A Cobblemon (Minecraft 1.21.1, Fabric) server and its matching client pack, both built
from `main`. Admins run everything with `docker compose`; players install one `.mrpack`
from a link that never changes and press Play. This repository is a GitHub template: create
your own copy, put your server's name and address in one file on `main`, and CI builds the
pack for your server and commits it to `main`. No local tooling is needed to publish.

- Players: read [docs/player-guide.md](docs/player-guide.md)
  (Traditional Chinese: [docs/player-guide.zh-TW.md](docs/player-guide.zh-TW.md)).
- Admins: read [docs/admin-guide.md](docs/admin-guide.md), then
  [docs/upgrade.md](docs/upgrade.md) and [docs/rollback.md](docs/rollback.md).

## How it fits together

One packwiz pack under `pack/` is the source of truth. On every push to `main`, CI turns it
into `dist/cobblemon.mrpack` with its version file `dist/cobblemon.env`, and commits both to
`main` when the pack's contents changed. Players download that file from the fixed link and
install it in Modrinth App or Prism Launcher; the server's checkout of `main` holds the same
file, and `itzg/minecraft-server` installs only the server-side entries. A backup sidecar
archives the world daily. A staging override runs a second stack next to production for
testing a branch on a copy of the real world before it is merged.

```
pack/  ──CI on main──▶  dist/cobblemon.mrpack (+ cobblemon.env)  ──raw link──▶  players
                                     │
                                     └──git pull──▶  cobblemon service (server side only)  ──▶  ./data
                                                              │
                                                              └──▶  backup sidecar  ──▶  ./backups
```

## Make it yours (GitHub)

1. Click **Use this template** and create your repository. Keep it **public**: players
   download the pack from its raw link, which serves files of public repositories only.
2. Edit `config/public.env` on `main` (the GitHub web editor is enough) and commit:
   `SERVER_PUBLIC_HOST` is the address players connect to, for example `mc.example.org`, and
   `SERVER_NAME` is what they see in their server list and in the MOTD. Neither is a secret:
   both are published inside the pack. A name may contain spaces, but no single quote.
3. Optional: replace `config/server-icon.png` and change `name` and `author` in `pack/pack.toml`
   (both can be edited in the GitHub web editor).
4. The push from step 2 runs CI, and its `publish` job builds the pack for your server and
   commits `dist/cobblemon.mrpack` and `dist/cobblemon.env` to `main` as
   `pack <version> [skip ci]`. Until that commit appears, `dist/` still holds the template's
   pack, which points at another server: do not send the link before it. While
   `SERVER_PUBLIC_HOST` is still the placeholder `mc.example.com`, the job publishes nothing
   and says so.
5. Send players the fixed link. It always serves the newest pack on `main`:
   `https://raw.githubusercontent.com/<you>/<your-repo>/main/dist/cobblemon.mrpack`

Let the bot push: the `publish` job pushes its commit to `main` with the workflow's own
token. Branch protection or a ruleset on `main` that requires pull requests or otherwise
blocks direct pushes rejects that push, and the job fails.

Nothing else is edited by hand to publish, and a push that changes neither the pack's
contents nor the display name (documentation, for example) publishes nothing. If no pack
commit appears, open the run under **Actions**: the `publish` job reports whether it
published, found nothing changed, or skipped because the address is still the placeholder.

## Quick start (Docker host)

Requirements: Linux with Docker 24+ and Compose 2.24+ (the staging override uses `!override`), bash, 12 GB RAM for the default 6 GB heap.

```bash
git clone https://github.com/<you>/<your-repo>.git   # your copy, after its first pack commit
cd <your-repo>                  # stay on main: it holds the pack and dist/cobblemon.env
cp .env.example .env
# edit .env: RCON_PASSWORD (openssl rand -base64 32), MEMORY, and UID/GID from `id -u` / `id -g`.
#            No PACK_VERSION and no server name: both come from dist/cobblemon.env.
echo 'export COMPOSE_ENV_FILES=.env,dist/cobblemon.env' >> ~/.profile   # once per account
. ~/.profile
mkdir -p data backups/keep && chmod 750 data backups   # yours, not root's; private
docker compose up -d
scripts/smoke.sh                # waits for healthy; checks version, pack, mods, RCON exposure
```

The pack and its version file are in the checkout, so there is nothing to download, and
`git pull` brings both together at every upgrade. `COMPOSE_ENV_FILES` tells Compose to read
`.env` and then the version file; it applies to every Compose command of that account (see
[docs/admin-guide.md](docs/admin-guide.md), "First deployment"). Without it,
`docker compose up` refuses to start and names the setting.

Open 25565/tcp to players, send them the fixed link, and whitelist them with
`docker compose exec cobblemon rcon-cli whitelist add PLAYER_NAME`.

To try a change to `pack/` without publishing, run `scripts/pack-export.sh`: it rebuilds both
files in `dist/` with the checked-out commit's version and the values in `config/public.env`
(a `SERVER_NAME` or `SERVER_PUBLIC_HOST` set in the environment overrides the file for that
one build). `git restore dist/` puts the published
pack back; do that before `git pull` and before committing, since only CI commits them.

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

Nobody writes a version by hand. The pack version is `YYYY.MM.DD-<commit>`: the UTC commit
date and the first seven characters of the commit on `main` the pack was built from, for
example `2026.11.18-95db987`. One version names one pack, in four places that always agree:
the version inside `dist/cobblemon.mrpack`, the `PACK_VERSION` in `dist/cobblemon.env`
committed with it, the pre-filled server entry `<name> (<version>)` in the client, and the
MOTD `... | Pack <version>`. Players compare the last two to see whether their pack is current.

The display name travels the same way. It is written once, in `config/public.env`; the build
puts it into the pack's entry and, as `SERVER_NAME`, into `dist/cobblemon.env`, where the
server reads it for the MOTD. The entry and the MOTD therefore always start with the name of
the same build.

In git, `pack/pack.toml` always reads `0.0.0-dev` and `.env.example` sets neither
`PACK_VERSION` nor `SERVER_NAME`. Only CI commits the two files in `dist/`, together, as
`pack <version> [skip ci]`, and only when the pack's contents or the display name changed. `scripts/smoke.sh` checks a deployment against this
contract: no `PACK_VERSION` in `.env`, a pack whose inside version equals the version file,
and a MOTD that announces it. History is the git log of `main`: every `pack <version>` commit
is a published pack, and `pack/` at the commit named in the version shows its contents.

The fixed link always serves the newest pack:
`https://raw.githubusercontent.com/<you>/<your-repo>/main/dist/cobblemon.mrpack`. GitHub
caches it for a few minutes after a publish.

## Repository layout

```
compose.yaml              production stack: cobblemon + backup (+ packwiz under profile "tools")
compose.staging.yaml      staging override: own project name, port 25566, staging/ data
.env.example              every variable with a default or placeholder
pack/                     packwiz source of truth (pack.toml, index.toml, mods/*.pw.toml, options.txt)
tools/packwiz/Dockerfile  packwiz built from a pinned commit
config/public.env         display name and public address; edit and commit to publish your pack
config/server-icon.png    placeholder icon, replace with your own
scripts/                  lint, pack-export, pack-inspect, pack-publish, version-check, smoke,
                          persist-test, restore-drill, staging-clone-world, ci-env
dist/                     cobblemon.mrpack and cobblemon.env, committed by CI only
docs/                     guides, SOPs, checklist, adr/
.github/workflows/ci.yml  L1 + L2 on push; publishes the pack on a push to main;
                          L3/L4 on dispatch or a smoke/* branch
openspec/                 OpenSpec specs and changes; all new work starts here as a change
AGENTS.md                 how AI agents and humans collaborate here
tasks/                    plan and task list of the 1.0.x work, frozen
```

Runtime directories (`data/`, `backups/`, `staging/`, the rest of `dist/`, `.env`) are never
committed.

## Decisions

See [docs/adr/](docs/adr/) for why the pack feeds both sides, why itzg images and a backup
sidecar were chosen over custom Dockerfiles and cron, and why `servers.dat` is generated at
export time.

## License

See [LICENSE](LICENSE).
