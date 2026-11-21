# Spec Delta

## ADDED Requirements

### Requirement: Player acceptance
Before a branch that changes the pack or the stack is merged, at least two players SHALL complete an acceptance run on staging with that branch, and again on production after the deployment. Each run SHALL cover logging in, a server restart, world persistence, reaching the server from another network, and the gameplay items `game-requirements` declares. Between them, the two runs SHALL use every launcher the pack install and update guide covers.

#### Scenario: Sign-off
- **WHEN** a branch that changes the pack or the stack is ready to merge, which releases it
- **THEN** every item passes on staging before the merge and on production after the deployment, and the launcher used for each run is recorded

#### Scenario: Items that do not depend on the game
- **WHEN** the mod pack is replaced by another
- **THEN** logging in, the server restart, world persistence and reaching the server from another network stay in the run unchanged

## MODIFIED Requirements

### Requirement: Server installs the server side of the configured pack
The main game service SHALL install `dist/<pack>.mrpack` from the deployment's checkout, `<pack>` being the pack's base name that `game-requirements` declares, installing only the entries marked for the server and none of the client-only override files.

#### Scenario: Only server-side mods are installed
- **WHEN** the stack starts on a checkout that contains `dist/<pack>.mrpack`
- **THEN** the server's mods directory contains exactly the pack's entries whose side is `both` or `server`, and neither the pack's client settings files nor its `servers.dat` is placed in the server data

### Requirement: Deployed pack matches the configured version
Before starting the stack, the smoke check SHALL refuse a `PACK_VERSION` set in `.env`, a configured version that does not have the pack version format, a missing `dist/<pack>.mrpack` or `dist/<pack>.env`, or a pack whose embedded version differs from the configured version, naming both versions.

#### Scenario: Embedded version differs
- **WHEN** `dist/<pack>.env` names a version other than the one inside `dist/<pack>.mrpack`
- **THEN** `scripts/smoke.sh` fails before the server starts and names both versions

#### Scenario: Version left in the environment file
- **WHEN** `.env` sets `PACK_VERSION`
- **THEN** `scripts/smoke.sh` fails before starting anything and tells the administrator to remove that line

#### Scenario: Malformed version
- **WHEN** the configured `PACK_VERSION` is neither `YYYY.MM.DD-<commit>` nor the placeholder `0.0.0-dev`
- **THEN** `scripts/smoke.sh` fails before starting anything

### Requirement: Pack version comes from the committed version file
The stack SHALL take `PACK_VERSION` from `dist/<pack>.env` in the deployment's checkout, read after the deployment environment file through `COMPOSE_ENV_FILES=.env,dist/<pack>.env`. Without a `PACK_VERSION`, Compose SHALL refuse to start with a message naming that setting. The committed example environment file SHALL NOT set `PACK_VERSION`. The helper scripts SHALL use the same environment files when `COMPOSE_ENV_FILES` is unset.

#### Scenario: Pull brings the version
- **WHEN** the administrator runs `git pull` and it brings a new `dist/<pack>.mrpack` and `dist/<pack>.env`
- **THEN** the next start installs the new pack and shows its version in the MOTD, with no edit to `.env`

#### Scenario: Setting missing
- **WHEN** `docker compose up` runs in a shell without `COMPOSE_ENV_FILES` and `.env` does not set `PACK_VERSION`
- **THEN** Compose refuses to start and its message names `COMPOSE_ENV_FILES=.env,dist/<pack>.env`

#### Scenario: Helper script without the setting
- **WHEN** `scripts/smoke.sh` runs in a shell without `COMPOSE_ENV_FILES`
- **THEN** it uses `.env` and `dist/<pack>.env` as if the setting were present
