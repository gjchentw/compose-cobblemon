# Tasks

## 1. Names

- [x] 1.1 Rename the main service to `minecraft` in `compose.yaml` (service, `depends_on`, `RCON_HOST`, comments), `compose.staging.yaml`, `scripts/smoke.sh`, `scripts/persist-test.sh` and `scripts/staging-clone-world.sh`; show both file sets render with services `minecraft` and `backup` (verify: L1, L2)
- [x] 1.2 Remove `container_name` from both files, set the staging project name from `STAGING_PROJECT_NAME` (default `minecraft-staging`) and add the variable to `.env.example`, and remove the tools image's fixed tag; show the rendered names with and without the variable, and that export still builds and runs the tools image (verify: L1, L2)
- [x] 1.3 Add `scripts/config-check.sh` and run it in the CI `validate` job; show it fails on the commit before this change and on a copy with a `container_name` added back, and passes now (verify: L1)
- [x] 1.4 `scripts/smoke.sh` refuses a staging file set that would run under production's project name; show the refusal with `COMPOSE_PROJECT_NAME` exported and with it in `.env`, that no container is created or changed, and that production and a normal staging run are not refused (verify: L1)

## 2. On real stacks

- [ ] 2.1 Move this host's deployment as an existing one would: stop, switch to the branch, `docker compose up -d --remove-orphans`; show the old `cobblemon` container is gone, the containers carry Compose's names, and smoke, persistence and restore pass (verify: L3, L4)
- [ ] 2.2 Two copies in differently named directories with different ports and staging project names: create their four stacks without starting them and show eight containers under four projects with no shared name; show the files before this change fail the same test (verify: L1)
- [ ] 2.3 Rehearse branch acceptance on staging from a worktree with the new names: staging passes smoke, persistence and restore under its own project, and production restarts and passes smoke afterwards (verify: L3, L4)
- [ ] 2.4 Push the branch and a `smoke/*` branch and confirm lint, validate with the new check, pack, and the hosted smoke, persistence and restore jobs pass (verify: L1, L2, L3, L4)

## 3. Documents

- [ ] 3.1 Update the commands in `docs/admin-guide.md`, `docs/upgrade.md`, `docs/rollback.md` and `README.md`; add the one-time upgrade section (`--remove-orphans`, the old staging project) and a section on two deployments on one host (directory names, ports, `STAGING_PROJECT_NAME`, memory, no `COMPOSE_PROJECT_NAME`) (verify: L1)
- [ ] 3.2 Add `scripts/config-check.sh` to the L1 means in `AGENTS.md` and `README.md`, and confirm with a search that no script, Compose file or document outside `tasks/` and archived changes still uses `cobblemon` as a service, container, project or image name (verify: L1)

## Workflow follow-up

- Merge to `main`; the publish job is expected to skip.
- Archive the change.
- Next: the changes `game-values-out-of-mechanisms` and `split-shared-scripts`.
