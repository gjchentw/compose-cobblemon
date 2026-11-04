# Upgrade SOP

Upgrade the pack (Cobblemon, Fabric, any mod) or the server image without surprising
players. The rule: production never tracks "latest"; every change is a release that was
tested on staging with a copy of the production world.

Versions follow the contract in `docs/releases.md`: tag, `pack/pack.toml`,
mrpack name, `PACK_VERSION` and MOTD all carry the same `X.Y.Z`.

## 1. Prepare the release candidate (developer machine)

1. Branch from `main`. Bump what changes:
   - a mod: `docker compose --profile tools run --rm packwiz modrinth install <modrinth version URL> -y`
     (or `packwiz update <mod>`), then set its `side` if needed and `packwiz refresh`
   - the server image: change tag and digest in `compose.yaml` (ask first, see `AGENTS.md`)
   - the backup image: same in `compose.yaml`
2. `scripts/lint.sh && docker compose config -q && scripts/pack-export.sh && scripts/pack-inspect.sh`
3. Commit, then `scripts/release.sh X.Y.Z-rc.1` and push the branch and the tag.
   CI builds the mrpack and publishes a GitHub pre-release `vX.Y.Z-rc.1`.

## 2. Test on staging (Docker host)

1. `git fetch --tags && git checkout vX.Y.Z-rc.1`
2. Download `cobblemon-X.Y.Z-rc.1.mrpack` from the release into `dist/` (or `scripts/pack-export.sh`).
3. Make sure staging is stopped, then copy the production world:
   `COMPOSE_FILE=compose.yaml:compose.staging.yaml docker compose down && scripts/staging-clone-world.sh`
4. Start staging with the candidate pack and run the automated checks:
   ```
   export COMPOSE_FILE=compose.yaml:compose.staging.yaml PACK_VERSION=X.Y.Z-rc.1
   scripts/smoke.sh && scripts/persist-test.sh && scripts/restore-drill.sh
   unset COMPOSE_FILE PACK_VERSION
   ```
5. Install the rc client pack and join staging on port 25566. Run `docs/acceptance-checklist.md`
   with at least two players. Read the staging log for warnings: `COMPOSE_FILE=compose.yaml:compose.staging.yaml docker compose logs cobblemon | grep -iE 'warn|error'`.
6. Anything fails: fix, cut `rc.2`, repeat. Nothing fails: cut the final release on the
   developer machine with `scripts/release.sh X.Y.Z`, push branch and tag, wait for the
   GitHub Release.

## 3. Upgrade production (Docker host)

1. Announce: `docker compose exec cobblemon rcon-cli say "Server upgrade in 10 minutes"`.
2. Pre-upgrade backup, kept forever, and proven to restore:
   ```
   docker compose exec -e PAUSE_IF_NO_PLAYERS=false backup backup now
   mv "backups/$(ls -t backups | grep tar.gz | head -n 1)" backups/keep/
   scripts/restore-drill.sh "keep/$(ls -t backups/keep | head -n 1)"
   ```
3. `docker compose stop`
4. `git checkout vX.Y.Z`, put `cobblemon-X.Y.Z.mrpack` in `dist/`, set `PACK_VERSION=X.Y.Z` in `.env`.
5. `docker compose up -d && scripts/smoke.sh && scripts/restore-drill.sh`
6. Record the result in `docs/releases.md` (Notes column), publish the GitHub Release notes,
   and tell players the new pack version and where to download it (`docs/player-guide.md`).
7. Stop staging: `COMPOSE_FILE=compose.yaml:compose.staging.yaml docker compose down`.

Keep the previous tag checked out somewhere you can reach, the previous mrpack in `dist/`
and the pre-upgrade archive in `backups/keep/` until the new release has survived one
full backup cycle. They are what `docs/rollback.md` needs.
