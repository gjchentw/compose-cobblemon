# Rollback SOP

Use when an upgraded production server misbehaves and the fix is not obvious.
Rolling back the pack and image is safe. Rolling back the world is a loss of
everything played since the pre-upgrade backup, and a world written by a newer
Cobblemon is not assumed to load on the older one, so the world step is last and
only when needed.

What you need, all created by `docs/upgrade.md`:

- the previous tag `vPREV` in the repository
- the previous `cobblemon-PREV.mrpack` in `dist/`
- the pre-upgrade archive in `backups/keep/`
- the previous client pack, still available on the Releases page

## Steps

1. Announce and stop:
   ```
   docker compose exec cobblemon rcon-cli say "Rolling back, back in 10 minutes"
   docker compose stop
   ```
2. Return the repository and the pack version:
   ```
   git checkout vPREV
   sed -i.bak 's/^PACK_VERSION=.*/PACK_VERSION=PREV/' .env && rm .env.bak
   ls dist/cobblemon-PREV.mrpack
   ```
3. Start. The image reinstalls the previous server-side mods from the mrpack and removes the newer ones:
   ```
   docker compose up -d && scripts/smoke.sh
   ```
4. Only if the world itself is broken, restore it from the pre-upgrade archive
   (the archive holds `world/`, `config/` and the admin files; mods are reinstalled from the pack).
   The archive is opened and checked first, the current world is moved aside, and only then
   is the restored copy put in place, so a wrong archive name cannot cost you the live world:
   ```
   docker compose stop
   docker compose run --rm --no-deps --entrypoint sh -v "$PWD/backups/keep:/keep:ro" cobblemon -c '
     set -e
     rm -rf /tmp/r && mkdir -p /tmp/r
     tar xzf /keep/ARCHIVE.tar.gz -C /tmp/r
     test -e /tmp/r/world/level.dat
     rm -rf /data/world.pre-rollback /data/config.pre-rollback
     mv /data/world /data/world.pre-rollback
     [ ! -d /data/config ] || mv /data/config /data/config.pre-rollback
     cp -a /tmp/r/world /data/ && [ ! -d /tmp/r/config ] || cp -a /tmp/r/config /data/
     cp -a /tmp/r/*.json /data/'
   docker compose up -d && scripts/smoke.sh
   ```
   After the smoke test passes and players confirm the world, delete the aside copies:
   `docker compose exec cobblemon rm -rf /data/world.pre-rollback /data/config.pre-rollback`.
5. Tell players to install the previous pack version from the Releases page and join again.
6. Note the rollback and the reason in `docs/releases.md`, then open an issue for the failed release.
