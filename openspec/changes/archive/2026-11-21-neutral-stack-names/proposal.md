# Proposal

## Why

The stack carries the game's name where a role name belongs: the main service is `cobblemon`, the containers are fixed as `cobblemon` and `cobblemon-backup`, the staging project is `cobblemon-staging`, and the tools image is tagged `compose-cobblemon/packwiz:local`. A project that takes `compose-services` for another mod pack would carry this game's name, which is the first of the tangles the baseline left for follow-up. The fixed names are also host-wide: the human plans a second mod project from this template on the same host, and tests on 2026-11-21 showed that it cannot run there today. A second stack with the same fixed container name fails to start, and a second staging stack with the same project name is silently adopted by the first one's containers.

## What Changes

- **BREAKING** The main service is renamed from `cobblemon` to `minecraft`. Administrator commands change, for example `docker compose exec minecraft rcon-cli list`.
- **BREAKING** No container name is fixed. Compose names the containers `<project>-<service>-1`, the project being the checkout's directory name. `docker stats cobblemon` becomes `docker compose stats`.
- **BREAKING** The staging project name comes from `STAGING_PROJECT_NAME` in `.env` (default `minecraft-staging`) instead of the fixed `cobblemon-staging`. The staging override no longer names containers.
- The tools image is no longer tagged with a fixed name; Compose tags it per project.
- New check `scripts/config-check.sh` (L1), run by the CI `validate` job: the rendered production and staging configurations fix no container name and no shared image tag, the services are `minecraft`, `backup` and `packwiz`, and the staging project name follows the variable and differs from production's.
- `scripts/smoke.sh` refuses to start a staging file set that would run under production's project name, which happens when `COMPOSE_PROJECT_NAME` is set for the whole shell or in `.env`.
- Documents follow: the commands in the administrator guide, the upgrade and rollback procedures and the README; a one-time upgrade step that removes the container of the old service; a section on running two deployments on one host.
- Not changed: `dist/cobblemon.mrpack` and `dist/cobblemon.env` keep their names, since they are the players' fixed link; the `backup` and `packwiz` service names; ports, volumes and images.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `compose-services`: services are named for their role; the staging project name is set by the deployment; two deployments made from this template can run on one host.

## Impact

- `compose.yaml`, `compose.staging.yaml`, `.env.example`.
- `scripts/smoke.sh`, `scripts/persist-test.sh`, `scripts/staging-clone-world.sh`; new `scripts/config-check.sh`; `.github/workflows/ci.yml` (one step in `validate`).
- `README.md`, `docs/admin-guide.md`, `docs/upgrade.md`, `docs/rollback.md`, `AGENTS.md` (the L1 means).
- Existing deployments: at the upgrade that brings this change, `docker compose up -d --remove-orphans` once, to remove the container of the old `cobblemon` service; without it, an old container that is still running keeps the port and the new one cannot start. World data is in `./data` and is not touched. A staging stack left under the old project name is removed with `docker compose -p cobblemon-staging down`.
- Players: nothing changes. No pack is published by this change.
