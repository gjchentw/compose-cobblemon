# Design

## Context

See proposal.md for the motivation. This is the first of three changes that untangle the files the baseline listed (the `design.md` of the archived `establish-baseline-specs` change, Risks): this one makes the stack's names neutral, the second moves game values out of mechanism files, the third splits the shared scripts. The human chose to keep the directory layout and to fix seams only.

Today `compose.yaml` names the main service `cobblemon`, fixes `container_name` on both services, and tags the tools image `compose-cobblemon/packwiz:local`; `compose.staging.yaml` sets `name: cobblemon-staging` and overrides both container names. Three scripts name the service; the documents name it in fifteen commands and name a container once (`docker stats cobblemon`). The scripts find containers through `docker compose`, never by container name.

Verified with Compose 5.7.1 on 2026-11-21:
- Two stacks with the same `container_name`: the second fails with "Conflict. The container name ... is already in use".
- Two stacks without `container_name`, in directories `auto-a` and `auto-b`: both run, as `auto-a-minecraft-1` and `auto-b-minecraft-1`.
- Two stacks whose staging override sets the same `name:`: the second `up` reports the first one's staging container as running and creates none of its own.
- `name: "${COMPOSE_PROJECT_NAME}-staging"` in the override: the variable is empty when `name` is resolved, so every copy gets `staging`; and when the variable is exported, it replaces `name` altogether, so staging gets production's project name.
- `name: "${STAGING_PROJECT_NAME:-minecraft-staging}"`: follows `.env`; two copies with different values ran their four stacks side by side.
- After a service is renamed, plain `docker compose up -d` leaves the old service's container; if it is still running it keeps the published port and the new container fails to start. `docker compose up -d --remove-orphans` stops and removes it, then starts the new containers.
- `docker compose stats` exists in Compose 2.24.0, the documented minimum.

## Goals / Non-Goals

**Goals:**
- No service, container, project or image name carries the game's name.
- Two repositories made from this template run on one host without touching each other.
- An existing deployment moves over with one documented command, and the world is not touched.

**Non-Goals:**
- Renaming `dist/cobblemon.mrpack` or `dist/cobblemon.env`: they are the players' fixed link.
- Moving the tools service out of `compose.yaml` or changing what it mounts: the third change and the least-privilege change.
- Making ports or memory automatic for a second deployment: they stay settings in `.env`.

## Decisions

**1. The main service is `minecraft` (chosen by the human).** It names the role, reads without explanation, and holds for any mod pack on this stack. Alternatives: `mc` (the name in itzg's examples, short, but the same letters as the placeholder host `mc.example.com` and the `MC_PORT` variable), `server` (the word is everywhere in this repository). `backup` and `packwiz` already name roles and stay.

**2. No `container_name` (option A, chosen by the human).** Compose names containers `<project>-<service>-1`. The production project is the checkout's directory name, so two copies in differently named directories do not collide. The staging override loses its two container names and shrinks to project name, port, paths and MOTD. The one documented command that used a container name becomes `docker compose stats`. Alternative: keep fixed names with the new word. Rejected by the human: a name like `minecraft` is even more likely to collide.

**3. The staging project name is a deployment setting (chosen by the human).** `compose.staging.yaml` sets `name: "${STAGING_PROJECT_NAME:-minecraft-staging}"`, and `.env.example` carries the variable with a note that it must be unique on the host. Alternatives, both tested: deriving it from `COMPOSE_PROJECT_NAME` (empty at that point, so every copy becomes `staging`); no `name` at all, so the acceptance worktree's directory names the project (unique without a setting, but a staging file set started from the production checkout would then be the production project). An explicit name stays distinct from production wherever it is started.

**4. The tools image has no fixed tag (approved by the human).** Without `image:`, Compose tags the build `<project>-packwiz`. Each project, and each acceptance worktree, builds its own from the shared layer cache, so two copies with different pinned packwiz commits no longer overwrite one tag.

**5. A static check guards the names.** `scripts/config-check.sh` renders both file sets and asserts: no `container_name`; no `image:` on a service that is built locally; the services are `minecraft`, `backup` and, with the `tools` profile, `packwiz`; the staging project name equals `STAGING_PROJECT_NAME` when it is set and differs from production's. It uses `docker compose config` and shell only, like the other L1 means, and the CI `validate` job runs it after the two `config -q` lines. Alternative: one-off checks at apply. Rejected: the second deployment the human plans depends on nobody adding a fixed name back.

**6. The smoke check refuses a staging run under production's project name.** A `COMPOSE_PROJECT_NAME` set in the shell profile or in `.env` replaces the override's `name`, so the staging file set would recreate production's containers with staging settings. Before starting anything, `scripts/smoke.sh` renders the production file set alone and the file set it was asked to start; when they are different file sets with the same project name, it fails and names the variable. The SOP starts staging through this script. A manual `docker compose up` is not covered; the administrator guide says not to set the variable.

**7. Existing deployments move with `--remove-orphans`, once.** The upgrade procedure gets a one-time section: stop, pull, `docker compose up -d --remove-orphans`, smoke. The backup container is recreated under its new name without help, since its service keeps its name. A staging stack left under the old project name is removed with `docker compose -p cobblemon-staging down`. Rolling back to a commit before this change is the same step in reverse.

## Risks / Trade-offs

- [Administrators' habits and saved commands use `cobblemon`] → Compose answers "no such service: cobblemon"; the upgrade section lists the rename.
- [An administrator upgrades without `--remove-orphans` while the old container runs] → The new container fails to start with a port error and the old one keeps serving; the smoke check fails. The upgrade section names the command, and stopping first, as the SOP says, avoids the port conflict.
- [Two copies keep the default staging project name] → The second staging adopts the first one's containers. `.env.example` and the administrator guide say the value must be unique on the host; the smoke guard does not see another repository.
- [Two checkouts with the same directory name on one host] → They are one Compose project. The administrator guide says to use different directory names.
- [Container names now depend on the directory name] → Scripts and documents use `docker compose` only; the config check keeps fixed names out.
- [Each acceptance worktree builds its own tools image] → Layers come from the build cache; removing the worktree leaves an unused image tag, cleaned by `docker image prune`.

## Migration Plan

1. Merge. Nothing is published.
2. Each deployment, at its next upgrade: `docker compose stop && git pull`, then `docker compose up -d --remove-orphans`, then `scripts/smoke.sh`. Optionally set `STAGING_PROJECT_NAME` in `.env`.
3. This host's test deployment is moved during apply, as the rehearsal of step 2.

Rollback: check out the previous commit and run `docker compose up -d --remove-orphans`; the `minecraft` container is then the orphan.
