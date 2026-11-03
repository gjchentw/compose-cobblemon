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
   (the archive holds `world/`, `config/` and the admin files; mods are reinstalled from the pack):
   ```
   docker compose stop
   docker compose run --rm --no-deps --entrypoint sh -v "$PWD/backups/keep:/keep:ro" cobblemon -c \
     'rm -rf /data/world /data/config /tmp/r && mkdir -p /tmp/r && tar xzf /keep/ARCHIVE.tar.gz -C /tmp/r \
      && cp -a /tmp/r/world /tmp/r/config /data/ && cp -a /tmp/r/*.json /data/'
   docker compose up -d && scripts/smoke.sh
   ```
   The archive is extracted to a scratch directory first and only the world, config
   and admin files are copied back; mods and loader files come from the pack on start.
5. Tell players to install the previous pack version from the Releases page and join again.
6. Note the rollback and the reason in `docs/releases.md`, then open an issue for the failed release.
