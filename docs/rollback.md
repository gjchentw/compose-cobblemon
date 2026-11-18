# Rollback SOP

Use when an upgraded production server misbehaves and the fix is not obvious.
Rolling back the pack and image is safe. Rolling back the world is a loss of
everything played since the pre-upgrade backup, and a world written by a newer
Cobblemon is not assumed to load on the older one, so the world step is last and
only when needed.

What you need, all created by `docs/upgrade.md`:

- `PREV`, the commit production ran before the upgrade (noted in its step 3; `git reflog`
  also lists it)
- the pre-upgrade archive in `backups/keep/`

The pack and its version file are committed, so checking out `PREV` brings back the pack,
the version and the compose files together. Two ways back, usually both: production checks
out `PREV` at once, and a revert on `main` publishes the old contents to players.

## Steps

1. Announce and stop:
   ```
   docker compose exec cobblemon rcon-cli say "Rolling back, back in 10 minutes"
   docker compose stop
   ```
2. Return the checkout to the previous commit:
   ```
   git checkout PREV
   cat dist/cobblemon.env
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
5. Revert on `main`: revert the merge that caused the problem (`git revert -m 1 <merge>`) on a
   branch, and accept and merge that branch like any other change (`docs/upgrade.md`,
   sections 1 to 3). Production already runs `PREV` meanwhile. CI publishes a pack with the
   old contents under a new version, and the fixed link serves it again.
6. Until that publish, the fixed link still serves the bad pack. Players who need the old one
   sooner use the link of `PREV`:
   `https://raw.githubusercontent.com/<you>/<your-repo>/PREV/dist/cobblemon.mrpack`.
7. After the revert is published, return production to `main` as an ordinary upgrade
   (`docs/upgrade.md`, section 4, from step 3), with `git checkout main && git pull` in place
   of `git pull`, since the checkout is detached at `PREV`. Tell players to install the pack
   from the fixed link again.
8. Open an issue naming the bad version and the reason for the rollback.

## Rolling back to a tag release (v1.0.x)

Commits before the rolling pack carry no `dist/cobblemon.mrpack`; their pack came from the
GitHub release. To return to one, for example `v1.0.1`: in step 2, `git checkout v1.0.1`,
remove `COMPOSE_ENV_FILES` from the profile and open a new shell, put `PACK_VERSION=1.0.1`
back in `.env`, and download `cobblemon-1.0.1.mrpack` from that release into `dist/`. The
v1.0.1 release and its pack are kept on the Releases page for this.
