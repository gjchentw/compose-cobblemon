# Admin Guide

Day-2 operations for the production stack. Every command runs from the repo
root on the Docker host. The host needs Docker 24+ with Compose 2.24+ and bash.

## First deployment

Run the server under an account dedicated to it: step 3 changes how every Compose command of
that account reads its settings.

1. Clone your repository (created from the template, see README "Make it yours") after its
   first pack commit, and stay on `main`:
   `git clone https://github.com/<you>/<your-repo>.git && cd <your-repo>`
   The checkout holds the pack, `dist/cobblemon.mrpack`, and its version file,
   `dist/cobblemon.env`; `cat dist/cobblemon.env` shows the version.
2. `cp .env.example .env` and edit `.env`:
   - `RCON_PASSWORD`: `openssl rand -base64 32`
   - `MEMORY`: `6G` on a 12 GB host, `4G` on an 8 GB host
   - `UID` and `GID`: the output of `id -u` and `id -g`

   The server's name and public address are not set here. They are in the committed
   `config/public.env` (README "Make it yours"); the name reaches the server through
   `dist/cobblemon.env`, so a `SERVER_NAME` in `.env` is not used.

   Do not add `PACK_VERSION`: it comes from `dist/cobblemon.env`, and `scripts/smoke.sh`
   refuses a `PACK_VERSION` in `.env`.
3. Tell Compose to read the version file, once, in the shell profile of this account:
   ```
   echo 'export COMPOSE_ENV_FILES=.env,dist/cobblemon.env' >> ~/.profile
   . ~/.profile
   ```
   Compose then reads `.env` first and the version file second. Without the setting,
   `docker compose up` refuses to start and names it; the scripts in `scripts/` set it
   themselves when it is missing. Two things to know:
   - The paths are relative to the working directory, so run every command from the repo
     root, as everywhere in this guide.
   - The setting applies to every Compose command of this account. In another directory
     without these files, Compose stops with "couldn't find env file". Empty it for one
     command to get Compose's default (only `.env`):
     `COMPOSE_ENV_FILES= docker compose ...`
4. `mkdir -p data backups/keep && chmod 750 data backups` so the directories belong to
   you, not to root, and other accounts on the host cannot read the world or the RCON password.
5. `docker compose up -d`, then `scripts/smoke.sh`. The first start downloads the
   server-side mods and takes a few minutes; the smoke test waits up to 10 minutes.
6. Open port 25565/tcp on the host firewall. Never open 25575 (RCON).
7. Send players the fixed link,
   `https://raw.githubusercontent.com/<you>/<your-repo>/main/dist/cobblemon.mrpack`; the
   player guide tells them to expect it from you. Upgrades follow `docs/upgrade.md`.

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
| `config/public.env` | the server's display name and public address, published in the pack | yes |
| `dist/cobblemon.mrpack`, `dist/cobblemon.env` | the pack the server installs and players download; its version and display name | yes, committed by CI only |
| `staging/` | data and backups of the staging stack | no |
| `.env` | your settings and the RCON password | no, never |

## Backups

The `backup` sidecar takes a full archive of `data/` every `BACKUP_INTERVAL` (24h) while
players have been online, and deletes archives older than `PRUNE_BACKUPS_DAYS` (14) from the
top level of `backups/`. Archives never contain `server.properties`, `.rcon-cli.env` or
`.rcon-cli.yaml` (they hold the RCON password and the image regenerates them from `.env` on
every start). Before every upgrade, take one by hand, move it to `backups/keep/` and prove it
restores with `scripts/restore-drill.sh keep/<archive>`. Run `scripts/restore-drill.sh` after
every upgrade too; it proves the newest archive restores.

If `data/` or any archive was ever shared with someone else, rotate `RCON_PASSWORD` in `.env`
and run `docker compose up -d` (both containers pick up the new value).

A scheduled backup may log `tar: .: file changed as we read it` followed by
`ERROR Backup failed with exit code 1`. The archive is still written and complete (tar exit
code 1 means a file changed during the read, which is expected on a live world); on Docker
Desktop it happens on every run. Check with `scripts/restore-drill.sh` if in doubt.

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
- `.env`, `data/` and `backups/` are gitignored. Never commit them, and never share `.env`.
  The two files in `dist/` are committed by CI only.
