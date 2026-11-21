# Spec Delta

## ADDED Requirements

### Requirement: Services are named for their role
The stack's services SHALL be named for what they do: `minecraft` for the main game service, `backup` for the backup service and `packwiz` for the pack tooling. No service, container, project or image name in the committed configuration SHALL carry the name of the game or of the mod pack.

#### Scenario: Administrator command
- **WHEN** an administrator lists the players online
- **THEN** `docker compose exec minecraft rcon-cli list` answers

#### Scenario: Rendered names
- **WHEN** the production and the staging configurations are rendered
- **THEN** their services are `minecraft` and `backup`, and with the `tools` profile also `packwiz`

### Requirement: Deployments coexist on one host
Two repositories made from this template SHALL be able to run on one host at the same time, each with its production and its staging stack, when their checkouts have different directory names and their deployment environments set different published ports and staging project names. The committed configuration SHALL NOT fix a container name, and SHALL NOT tag a locally built image with a name shared across projects.

#### Scenario: Two copies side by side
- **WHEN** two copies in directories `alpha` and `beta`, with different ports and staging project names, create their production and staging stacks
- **THEN** four projects exist with two containers each, and no container, project or network is shared

#### Scenario: Fixed names are rejected
- **WHEN** a change adds a `container_name` or a fixed tag for a locally built image
- **THEN** `scripts/config-check.sh` fails and names the service

### Requirement: Staging never runs under production's project name
The smoke check SHALL refuse to start the staging file set when it would run under the same project name as the production file set, naming `COMPOSE_PROJECT_NAME` as the likely cause.

#### Scenario: Project name set for the whole shell
- **WHEN** `scripts/smoke.sh` runs with the staging file set while `COMPOSE_PROJECT_NAME` is set in the shell or in `.env`
- **THEN** it fails before any container is created or changed

## MODIFIED Requirements

### Requirement: Staging environment
A staging stack SHALL run next to production on the same host with its own project name, which the deployment sets as `STAGING_PROJECT_NAME` (default `minecraft-staging`), its own published port (default 25566), data and backup directories, and a `[STAGING]` MOTD prefix, and SHALL otherwise use the production configuration.

#### Scenario: Staging differs only where it must
- **WHEN** the production and the staging configurations are rendered and compared
- **THEN** they differ only in the project name, the published port, the data and backup paths and the MOTD

#### Scenario: Staging project name from the deployment
- **WHEN** `.env` sets `STAGING_PROJECT_NAME=beta-staging` and the staging configuration is rendered
- **THEN** its project name is `beta-staging`
