# Upgrade SOP

Upgrade the pack (Cobblemon, Fabric, any mod) or the server image without surprising
players. The rule: production runs `main`, and merging to `main` publishes the new pack to
every player at once. So every change is tested on staging, with a copy of the production
world, from its branch before it is merged.

The pack version is `YYYY.MM.DD-<commit>`, taken from the commit that changed the pack (see
README "Version contract"). CI commits `dist/cobblemon.mrpack` and its version file
`dist/cobblemon.env` to `main`; the MOTD and the name of the pre-filled server entry carry
the same version. Nothing in git is edited by hand to release.

The commands below assume the shell has `COMPOSE_ENV_FILES=.env,dist/cobblemon.env`, as
set up in `docs/admin-guide.md`; the scripts in `scripts/` set it themselves. Paths: the
production checkout is `<your-repo>`, on `main`; the acceptance checkout is a git worktree
next to it, `../<your-repo>-accept`.

## 1. Prepare the branch

1. Branch from `main`. Bump what changes:
   - a mod: `docker compose --profile tools run --rm packwiz modrinth install <modrinth version URL> -y`
     (or `packwiz update <mod>`), then set its `side` if needed and `packwiz refresh`
   - the server image: change tag and digest in `compose.yaml` (ask first, see `AGENTS.md`)
   - Minecraft itself: also update the first line of `pack/options.txt` to the new data
     version (`version:<n>`, the `world_version` of that Minecraft release; 1.21.1 is 3955),
     or the game discards the pack's key bindings on first launch
   - the backup image: same in `compose.yaml`
   - the server's display name or public address: edit `config/public.env`; both are built
     into the pack, so the change is published like any other
2. `scripts/lint.sh && docker compose config -q && scripts/pack-export.sh && scripts/pack-inspect.sh`
3. `scripts/pack-publish.sh --dry-run` tells whether merging would publish a new pack, and
   which archive members change.
4. Exporting rewrites `dist/cobblemon.mrpack` and `dist/cobblemon.env` in your checkout. Put
   them back before committing (`git restore dist/`): only CI commits them.
5. Push the branch and wait for CI to pass. Do not merge yet.

## 2. Accept the branch on staging (Docker host)

1. Check out the branch next to production, with production's settings, and build its pack:
   ```
   cd <your-repo>
   git fetch origin
   git worktree add --detach ../<your-repo>-accept origin/<branch>
   cp .env ../<your-repo>-accept/.env
   cd ../<your-repo>-accept
   scripts/pack-export.sh
   ```
   The worktree now has the branch's pack and `dist/cobblemon.env` naming its version.
   Every command from here on runs in the worktree, so the relative `COMPOSE_ENV_FILES`
   picks up the worktree's own `.env` and version file.
2. Make sure staging is stopped, then copy the production world (production saves are
   paused for the copy when it is running):
   ```
   COMPOSE_FILE=compose.yaml:compose.staging.yaml docker compose down
   scripts/staging-clone-world.sh --production ../<your-repo>
   ```
3. A host without memory for two servers (each needs `MEMORY` plus the JVM's own overhead):
   stop production now with `docker compose stop` in `../<your-repo>`, and start it again in
   step 7.
4. Start staging with the branch's pack and run the automated checks:
   ```
   export COMPOSE_FILE=compose.yaml:compose.staging.yaml
   scripts/smoke.sh && scripts/persist-test.sh && scripts/restore-drill.sh
   ```
   The MOTD reads `[STAGING] <name> | Pack <branch version>`. Staging is its own Compose
   project, named by `STAGING_PROJECT_NAME` in `.env` (default `minecraft-staging`).
5. Give the testers the branch's client pack, `dist/cobblemon.mrpack` from the worktree.
   Its pre-filled entry points at production: they add `<host>:25566` by hand, or you
   export a staging pack first with `SERVER_PUBLIC_HOST=<host>:25566 scripts/pack-export.sh`
   (the environment overrides `config/public.env` for that one build).
   Run `docs/acceptance-checklist.md` with at least two players. Read the staging log for
   warnings: `docker compose logs minecraft | grep -iE 'warn|error'`.
6. Anything fails: fix it on the branch and push, then in the worktree
   `git fetch origin && git checkout --detach origin/<branch>`, rebuild the pack and repeat
   from step 2.
7. Everything passes: stop staging and remove the worktree, with its staging data and
   backups, then start production again if you stopped it:
   ```
   docker compose down && unset COMPOSE_FILE
   cd ../<your-repo>
   git worktree remove --force ../<your-repo>-accept
   docker compose up -d && scripts/smoke.sh    # only if you stopped production in step 3
   ```
8. Merge the branch to `main`.

## 3. Publish (CI)

The merge runs CI on `main`. When the pack's contents or the display name changed, the
`publish` job commits `dist/cobblemon.mrpack` and `dist/cobblemon.env` to `main` as
`pack <version> [skip ci]`; a merge that changes neither (documentation, for example)
publishes nothing, and so does a repository whose `config/public.env` still holds the
placeholder address. The
fixed link serves the new pack within a few minutes:
`https://raw.githubusercontent.com/<you>/<your-repo>/main/dist/cobblemon.mrpack`.

Players who install the new pack cannot join the old server, so upgrade production soon
after the publish.

## 4. Upgrade production (Docker host)

1. Announce: `docker compose exec minecraft rcon-cli say "Server upgrade in 10 minutes"`.
2. Pre-upgrade backup, kept forever, and proven to restore:
   ```
   docker compose exec -e PAUSE_IF_NO_PLAYERS=false backup backup now
   mv "backups/$(ls -t backups | grep tar.gz | head -n 1)" backups/keep/
   scripts/restore-drill.sh "keep/$(ls -t backups/keep | head -n 1)"
   ```
3. Note the running commit for `docs/rollback.md`: `git log -1 --format='%h %s'`.
4. `docker compose stop && git pull`. The pull brings the compose files, the pack and its
   version file together; `.env` is not edited.
5. `docker compose up -d && scripts/smoke.sh && scripts/restore-drill.sh`. The smoke check
   refuses a `PACK_VERSION` left in `.env` and a version file that does not match the pack.
6. Tell players the new version (the MOTD shows it) and that the fixed link serves it; they
   install it as a new profile (`docs/pack-install-guide.md`). Run `docs/acceptance-checklist.md`
   on production.

Keep the noted commit and the pre-upgrade archive in `backups/keep/` until the new pack has
survived one full backup cycle. They are what `docs/rollback.md` needs.

### Once: moving a deployment from tag releases

A deployment set up for a tag release (`v1.0.x`, `PACK_VERSION` in `.env`) changes over once,
at its first upgrade under this SOP. In step 4, `git checkout main` before `git pull`; then
delete the `PACK_VERSION` line from `.env`, add
`export COMPOSE_ENV_FILES=.env,dist/cobblemon.env` to the profile of the account that runs
the server (`docs/admin-guide.md`), open a new shell, and continue with step 5. The old
`dist/cobblemon-<version>.mrpack` files are no longer used and can be deleted.

### Once: moving a copy from repository secrets to `config/public.env`

A copy that set the repository secrets `SERVER_NAME` and `SERVER_PUBLIC_HOST` changes over
once, after it has merged the template's change that adds `config/public.env`:

1. Put the two values in `config/public.env` and commit to `main`. CI publishes a pack and a
   version file that carries the display name, even when the pack's contents are the same
   as before.
2. Delete the two repository secrets; nothing reads them any more.
3. On the Docker host, upgrade as in section 4, and delete the `SERVER_NAME` and
   `SERVER_PUBLIC_HOST` lines from `.env`: the server now takes the name from
   `dist/cobblemon.env`.

### Once: moving a deployment to the role-named services

A deployment started before the main service was renamed from `cobblemon` to `minecraft`
changes over once, at the upgrade that brings the rename:

1. In section 4, step 5, start with `docker compose up -d --remove-orphans` in place of
   `docker compose up -d`. The flag removes the container of the old `cobblemon` service;
   the backup container is recreated under its new name without help. Without the flag an
   old container that is still running keeps the port, and the new one fails to start. The
   world is in `./data` and is not touched.
2. Use `minecraft` where your own notes and scripts say `cobblemon`, for example
   `docker compose exec minecraft rcon-cli list`. Compose answers
   `service "cobblemon" is not running` to the old name. Containers are no longer called
   `cobblemon` and `cobblemon-backup` but `<your-repo>-minecraft-1` and `<your-repo>-backup-1`.
3. If a staging stack from before is still on the host, remove it:
   `docker compose -p cobblemon-staging down`. Staging now runs as the project named by
   `STAGING_PROJECT_NAME` in `.env`; set it when the host carries a second deployment
   (`docs/admin-guide.md`, "Two deployments on one host").

Rolling back across the rename (`docs/rollback.md`) takes the same flag in step 3:
`docker compose up -d --remove-orphans`, which then removes the `minecraft` container.
