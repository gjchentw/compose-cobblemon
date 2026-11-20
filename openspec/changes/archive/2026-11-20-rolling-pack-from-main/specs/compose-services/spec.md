# Spec Delta

## ADDED Requirements

### Requirement: Branch acceptance on staging
Administrators SHALL be able to run a branch on the staging stack before it is merged: staging runs from a separate checkout of the branch, builds that branch's pack on the host, takes a copy of the production world, and passes the smoke, persistence and restore checks with the branch's pack version. The production checkout SHALL stay on `main` throughout.

#### Scenario: Candidate on staging
- **WHEN** an administrator prepares branch `bump-x` for acceptance
- **THEN** staging runs `bump-x`'s pack with a copy of the production world on its own port, production keeps running `main`, and the staging checks pass before the branch is merged

### Requirement: Pack version comes from the committed version file
The stack SHALL take `PACK_VERSION` from `dist/cobblemon.env` in the deployment's checkout, read after the deployment environment file through `COMPOSE_ENV_FILES=.env,dist/cobblemon.env`. Without a `PACK_VERSION`, Compose SHALL refuse to start with a message naming that setting. The committed example environment file SHALL NOT set `PACK_VERSION`. The helper scripts SHALL use the same environment files when `COMPOSE_ENV_FILES` is unset.

#### Scenario: Pull brings the version
- **WHEN** the administrator runs `git pull` and it brings a new `dist/cobblemon.mrpack` and `dist/cobblemon.env`
- **THEN** the next start installs the new pack and shows its version in the MOTD, with no edit to `.env`

#### Scenario: Setting missing
- **WHEN** `docker compose up` runs in a shell without `COMPOSE_ENV_FILES` and `.env` does not set `PACK_VERSION`
- **THEN** Compose refuses to start and its message names `COMPOSE_ENV_FILES=.env,dist/cobblemon.env`

#### Scenario: Helper script without the setting
- **WHEN** `scripts/smoke.sh` runs in a shell without `COMPOSE_ENV_FILES`
- **THEN** it uses `.env` and `dist/cobblemon.env` as if the setting were present

## MODIFIED Requirements

### Requirement: Server installs the server side of the configured pack
The main game service SHALL install `dist/cobblemon.mrpack` from the deployment's checkout, installing only the entries marked for the server and none of the client-only override files.

#### Scenario: Only server-side mods are installed
- **WHEN** the stack starts on a checkout that contains `dist/cobblemon.mrpack`
- **THEN** the server's mods directory contains exactly the pack's entries whose side is `both` or `server`, and no client-only override file such as `options.txt` or `servers.dat` is placed in the server data

### Requirement: Deployed pack matches the configured version
Before starting the stack, the smoke check SHALL refuse a `PACK_VERSION` set in `.env`, a configured version that does not have the pack version format, a missing `dist/cobblemon.mrpack` or `dist/cobblemon.env`, or a pack whose embedded version differs from the configured version, naming both versions.

#### Scenario: Embedded version differs
- **WHEN** `dist/cobblemon.env` names a version other than the one inside `dist/cobblemon.mrpack`
- **THEN** `scripts/smoke.sh` fails before the server starts and names both versions

#### Scenario: Version left in the environment file
- **WHEN** `.env` still sets `PACK_VERSION`, as deployments did before the version file existed
- **THEN** `scripts/smoke.sh` fails before starting anything and tells the administrator to remove that line

#### Scenario: Malformed version
- **WHEN** the configured `PACK_VERSION` is neither `YYYY.MM.DD-<commit>` nor the placeholder `0.0.0-dev`
- **THEN** `scripts/smoke.sh` fails before starting anything

## REMOVED Requirements

### Requirement: Deployed configuration matches the release
**Reason**: The pack now comes from the deployment's own checkout, so the pack and the configuration are always from the same commit; there are no release tags to compare.
**Migration**: Deploy with `git pull` on `main`; the version comes from `dist/cobblemon.env`.
