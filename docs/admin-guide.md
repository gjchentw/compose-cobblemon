# Admin Guide

Day-2 operations for the production stack. Every command runs from the repo
root on the Docker host. The host needs Docker 24+ with Compose 2.24+ and bash.

## First deployment

1. Clone your repository (created from the template, see README "Make it yours") and
   check out the release tag you are deploying:
   `git clone https://github.com/<you>/<your-repo>.git && cd <your-repo> && git checkout v1.0.0`
2. `cp .env.example .env` and edit `.env`:
   - `RCON_PASSWORD`: `openssl rand -base64 32`
   - `SERVER_NAME`, `SERVER_PUBLIC_HOST`: what players will see and connect to
   - `MEMORY`: `6G` on a 12 GB host, `4G` on an 8 GB host
   - `UID` and `GID`: the output of `id -u` and `id -g`
3. `mkdir -p data backups/keep dist` so the directories belong to you, not to root.
4. Put the pack in `dist/`. Either download `cobblemon-<version>.mrpack` from the
   [Releases page](../../releases) into `dist/`,
   or build it locally with `scripts/pack-export.sh` (builds the tools image first).
5. `docker compose up -d`, then `scripts/smoke.sh`. The first start downloads the
   server-side mods and takes a few minutes; the smoke test waits up to 10 minutes.
6. Open port 25565/tcp on the host firewall. Never open 25575 (RCON).

## Everyday commands

| Task | Command |
|---|---|
| Status and health | `docker compose ps` |
| Follow the server log | `docker compose logs -f cobblemon` |
| Who is online | `docker compose exec cobblemon rcon-cli list` |
| Whitelist a player | `docker compose exec cobblemon rcon-cli whitelist add PLAYER_NAME` |
| Remove from whitelist | `docker compose exec cobblemon rcon-cli whitelist remove PLAYER_NAME` |
| Give operator rights | `docker compose exec cobblemon rcon-cli op PLAYER_NAME` |
| Broadcast a message | `docker compose exec cobblemon rcon-cli say "Restart in 5 minutes"` |
| Restart the server | `docker compose restart cobblemon` (players are disconnected; the world is saved first) |
| Stop everything | `docker compose stop` |
| Resource usage | `docker stats cobblemon --no-stream` |
| Backup right now | `docker compose exec -e PAUSE_IF_NO_PLAYERS=false backup backup now` |
| Keep a backup forever | `mv backups/world-<timestamp>.tar.gz backups/keep/` |
| Verify backups restore | `scripts/restore-drill.sh` |

RCON is reachable only inside the compose network; `docker compose exec cobblemon rcon-cli`
is the only way in, and that is intended.

## Where things live

| Path | Content | In git |
|---|---|---|
| `data/` | world, configs, whitelist, ops, logs | no |
| `backups/` | tar archives from the backup sidecar; pruned after `PRUNE_BACKUPS_DAYS` | no |
| `backups/keep/` | archives you want to keep (pre-upgrade); never pruned | no |
| `dist/` | the mrpack the server installs and players download | no |
| `staging/` | data and backups of the staging stack | no |
| `.env` | your settings and the RCON password | no, never |

## Backups

The `backup` sidecar takes a full archive of `data/` every `BACKUP_INTERVAL` (24h) while
players have been online, and deletes archives older than `PRUNE_BACKUPS_DAYS` (14) from the
top level of `backups/`. Before every upgrade, take one by hand and move it to `backups/keep/`.
Run `scripts/restore-drill.sh` after every upgrade; it proves the newest archive restores.

## Performance triage

Watch TPS and MSPT first (`docker compose exec cobblemon rcon-cli tps` is not vanilla; use
the `spark` mod once it is added in a later release), then CPU and RAM with `docker stats`.
When TPS drops, work down this list and stop at the first step that fixes it:

1. Profile with spark (Phase 2 mod) to find the real bottleneck.
2. Lower `SIMULATION_DISTANCE` in `.env` (6 is the default), then `docker compose up -d`.
3. Lower `VIEW_DISTANCE` (10 is the default).
4. Count entities and Pokémon; cull with `rcon-cli kill @e[type=cobblemon:pokemon,tag=!owned]` only if agreed with players.
5. Check chunk generation load: players exploring far away generate terrain.
6. Disable a suspect add-on on staging and compare.
7. Pre-generate the area players use.
8. Add hardware last.

## Security

- `ONLINE_MODE=true` and the whitelist are enforced; do not change them.
- The image, the backup image and every mod are pinned; bump them only through `docs/upgrade.md`.
- `.env`, `data/`, `backups/` and `dist/` are gitignored. Never commit them, and never share `.env`.
